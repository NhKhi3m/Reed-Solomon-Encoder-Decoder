module forney_calc (
    input clk,
    input rst_n,
    input start,
    input      [255:0] syn_in,       // Tu khoi Syndrome
    input      [135:0] err_loc_in,   // Tu khoi BM (Lambda)
    input              error_flag,   // Co bao loi tu Chien Search
    output     [7:0]   error_mag     // Do lon cua loi (Gia tri can de sua sai)
);

    // 1. Dinh nghia cac root
    wire [7:0] root [0:15];
    assign root[0]=8'h01; assign root[1]=8'h02; assign root[2]=8'h04; assign root[3]=8'h08;
    assign root[4]=8'h10; assign root[5]=8'h20; assign root[6]=8'h40; assign root[7]=8'h80;
    assign root[8]=8'h1D; assign root[9]=8'h3A; assign root[10]=8'h74; assign root[11]=8'hE8;
    assign root[12]=8'hCD; assign root[13]=8'h87; assign root[14]=8'h13; assign root[15]=8'h26;

    // 2. Ham Nhan va Nghich dao trong GF(2^8)
    function [7:0] gf_mult;
        input [7:0] a, b;
        reg [7:0] temp_a;
        integer j;
        begin
            gf_mult = 8'b0;
            temp_a = a;
            for (j = 0; j < 8; j = j + 1) begin
                if (b[j]) gf_mult = gf_mult ^ temp_a;
                if (temp_a[7]) temp_a = (temp_a << 1) ^ 8'h1D;
                else           temp_a = temp_a << 1;
            end
        end
    endfunction

    // Phep nghich dao bang dinh ly Fermat (a^-1 = a^254 trong GF(2^8))
    function [7:0] gf_inv;
        input [7:0] a;
        reg [7:0] temp;
        integer k;
        begin
            if (a == 8'h00) gf_inv = 8'h00; // Tranh loi
            else begin
                temp = a;
                for(k = 0; k < 253; k = k + 1) begin
                    temp = gf_mult(temp, a);
                end
                gf_inv = temp;
            end
        end
    endfunction

    // 3. Tinh toan Da thuc Omega (To hop)
    reg [7:0] Omega [0:15];
    integer i, j;
    always @(*) begin
        for(i = 0; i <= 15; i = i + 1) begin
            Omega[i] = 8'h00;
            for(j = 0; j <= 15; j = j + 1) begin
                if (j <= i) begin
                    Omega[i] = Omega[i] ^ gf_mult(err_loc_in[j*8 +: 8], syn_in[(i-j)*8 +: 8]);
                end
            end
        end
    end

    // 4. Mạch Pipeline chay song song voi Chien Search
    reg [7:0] Omega_reg [0:15];
    reg [7:0] Lambda_odd_reg [0:7]; // Chi can lay cac he so bac le cua Lambda

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i = 0; i <= 15; i = i + 1) Omega_reg[i] <= 0;
            for(i = 0; i <= 7; i = i + 1) Lambda_odd_reg[i] <= 0;
        end else if (start) begin
            // Nhip dau tien: Nap Omega va Lambda le, nhan luon voi root
            for(i = 0; i <= 15; i = i + 1) Omega_reg[i] <= gf_mult(Omega[i], root[i]);
            for(i = 0; i <= 7; i = i + 1) Lambda_odd_reg[i] <= gf_mult(err_loc_in[(i*2+1)*8 +: 8], root[i*2+1]);
        end else begin
            // Cac nhip sau: Tiep tuc dich vong (nhan tiep voi root)
            for(i = 0; i <= 15; i = i + 1) Omega_reg[i] <= gf_mult(Omega_reg[i], root[i]);
            for(i = 0; i <= 7; i = i + 1) Lambda_odd_reg[i] <= gf_mult(Lambda_odd_reg[i], root[i*2+1]);
        end
    end

    // 5. Tinh toan Do lon loi (Xuat ra ngay lap tuc khi co error_flag)
    reg [7:0] omega_sum;
    reg [7:0] lambda_odd_sum;
    integer idx;
    always @(*) begin
        omega_sum = 8'h00;
        lambda_odd_sum = 8'h00;
        for(idx = 0; idx <= 15; idx = idx + 1) omega_sum = omega_sum ^ Omega_reg[idx];
        for(idx = 0; idx <= 7; idx = idx + 1) lambda_odd_sum = lambda_odd_sum ^ Lambda_odd_reg[idx];
    end

    // error_mag = Omega / Lambda_odd
    assign error_mag = error_flag ? gf_mult(omega_sum, gf_inv(lambda_odd_sum)) : 8'h00;

endmodule