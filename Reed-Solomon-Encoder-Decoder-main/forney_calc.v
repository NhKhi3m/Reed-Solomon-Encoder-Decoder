module forney_calc (
    input clk,
    input rst_n,
    input start,
    input      [255:0] syn_in,       // Tu khoi Syndrome (32 byte S_1..S_32)
    input      [135:0] err_loc_in,   // Tu khoi BM: Da thuc Lambda(x), 17 he so
    input              error_flag,   // Co bao loi tu Chien Search
    output     [7:0]   error_mag     // Do lon loi (gia tri XOR de sua byte)
);

    // =========================================================================
    // 1. BANG LUY THUA ALPHA NGHICH DAO: inv_root[i] = alpha^(-i) = alpha^(255-i)
    //    Forney pipeline phai DONG BO voi Chien Search (cung dung inv_root)
    //    De tai moi cycle c, Forney danh gia Omega(alpha^(-c)) va Lambda'(alpha^(-c))
    //    tai cung diem ma Chien danh gia Lambda(alpha^(-c))
    // =========================================================================
    wire [7:0] root [0:15];
    assign root[0]  = 8'h01; // alpha^0
    assign root[1]  = 8'h02; // alpha^1
    assign root[2]  = 8'h04; // alpha^2
    assign root[3]  = 8'h08; // alpha^3
    assign root[4]  = 8'h10; // alpha^4
    assign root[5]  = 8'h20; // alpha^5
    assign root[6]  = 8'h40; // alpha^6
    assign root[7]  = 8'h80; // alpha^7
    assign root[8]  = 8'h1D; // alpha^8
    assign root[9]  = 8'h3A; // alpha^9
    assign root[10]  = 8'h74; // alpha^10
    assign root[11]  = 8'hE8; // alpha^11
    assign root[12]  = 8'hCD; // alpha^12
    assign root[13]  = 8'h87; // alpha^13
    assign root[14]  = 8'h13; // alpha^14
    assign root[15]  = 8'h26; // alpha^15

    // =========================================================================
    // 2. HAM NHAN VA NGHICH DAO TRONG GF(2^8)
    //    Primitive polynomial: x^8 + x^4 + x^3 + x^2 + 1 (reduction = 0x1D)
    // =========================================================================
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

    // Nghich dao bang dinh ly Fermat nho: a^(-1) = a^254 trong GF(2^8)
    function [7:0] gf_inv;
        input [7:0] a;
        reg [7:0] temp;
        integer k;
        begin
            if (a == 8'h00) gf_inv = 8'h00; // Tranh chia cho 0
            else begin
                temp = a;
                for (k = 0; k < 253; k = k + 1) begin
                    temp = gf_mult(temp, a);
                end
                gf_inv = temp;
            end
        end
    endfunction

    // =========================================================================
    // 3. TINH DA THUC OMEGA (Error Evaluator Polynomial)
    //    Omega(x) = Lambda(x) * S(x) mod x^(2t)
    //    Omega_i = sum_{j=0}^{i} Lambda_j * S_{i-j}
    // =========================================================================
    reg [7:0] Omega [0:15];
    integer i, j;
    always @(*) begin
        for (i = 0; i <= 15; i = i + 1) begin
            Omega[i] = 8'h00;
            for (j = 0; j <= i; j = j + 1) begin
                if (j <= 16) begin
                    Omega[i] = Omega[i] ^ gf_mult(err_loc_in[j*8 +: 8], syn_in[(i-j)*8 +: 8]);
                end
            end
        end
    end

    // =========================================================================
    // 4. PIPELINE REGISTERS: Omega va Lambda' chay song song voi Chien Search
    //
    //    QUAN TRONG: Dung inv_root thay vi root de dong bo voi Chien forward!
    //
    //    Omega pipeline:
    //      Khoi tao: Omega_reg[i] = Omega_i * inv_root[i] = Omega_i * alpha^(-i)
    //      Moi cycle: Omega_reg[i] *= inv_root[i]
    //      -> Tai cycle c: Omega_reg[i] = Omega_i * (alpha^(-i))^c
    //      -> Tong XOR = Omega(alpha^(-c))
    //
    //    Lambda' pipeline:
    //      Dao ham Lambda'(x) = Lambda_1 + Lambda_3*x^2 + Lambda_5*x^4 + ...
    //      Lambda_prime_reg[k] theo doi so hang Lambda_{2k+1} * x^{2k}
    //      Khoi tao: Lambda_prime_reg[k] = Lambda_{2k+1} * (alpha^(-2k))^1
    //                                    = Lambda_{2k+1} * inv_root[2k]
    //      Moi cycle: *= inv_root[2k]
    //      -> Tai cycle c: = Lambda_{2k+1} * (alpha^(-2k))^c
    //      -> Tong XOR = Lambda'(alpha^(-c))
    // =========================================================================
    reg [7:0] Omega_reg [0:15];
    reg [7:0] Lambda_prime_reg [0:7]; // 8 thanh ghi cho k=0..7

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= 15; i = i + 1) Omega_reg[i] <= 8'd0;
            for (i = 0; i <= 7;  i = i + 1) Lambda_prime_reg[i] <= 8'd0;
        end else if (start) begin
            // Nhip dau tien (c=1): Nhan voi root
            for (i = 0; i <= 15; i = i + 1)
                Omega_reg[i] <= gf_mult(Omega[i], root[i]);

            // Lambda' khoi tao: Lambda_prime_reg[k] = Lambda_{2k+1} * root[2k]
            for (i = 0; i <= 7; i = i + 1)
                Lambda_prime_reg[i] <= gf_mult(err_loc_in[(i*2+1)*8 +: 8], root[i*2]);
        end else begin
            // Cac cycle tiep theo: Tiep tuc nhan voi root tuong ung
            for (i = 0; i <= 15; i = i + 1)
                Omega_reg[i] <= gf_mult(Omega_reg[i], root[i]);

            for (i = 0; i <= 7; i = i + 1)
                Lambda_prime_reg[i] <= gf_mult(Lambda_prime_reg[i], root[i*2]);
        end
    end

    // =========================================================================
    // 5. TINH GIA TRI OMEGA VA LAMBDA' TAI MOI CYCLE (Mach to hop)
    //    omega_sum = Omega(alpha^(-c))
    //    lambda_prime_sum = Lambda'(alpha^(-c))
    // =========================================================================
    reg [7:0] omega_sum;
    reg [7:0] lambda_prime_sum;
    integer idx;

    always @(*) begin
        omega_sum = 8'h00;
        lambda_prime_sum = 8'h00;

        for (idx = 0; idx <= 15; idx = idx + 1)
            omega_sum = omega_sum ^ Omega_reg[idx];

        for (idx = 0; idx <= 7; idx = idx + 1)
            lambda_prime_sum = lambda_prime_sum ^ Lambda_prime_reg[idx];
    end

    // =========================================================================
    // 6. KET QUA: error_mag = Omega(X_j^(-1)) / Lambda'(X_j^(-1))
    //    Cong thuc Forney: e_j = Omega(X_j^{-1}) / Lambda'(X_j^{-1})
    //    Voi X_j = alpha^j -> X_j^{-1} = alpha^{-j}
    //    Chien forward tai cycle c danh gia alpha^{-c} -> vi tri c-1
    //    => omega_sum va lambda_prime_sum dang danh gia tai alpha^{-c} -> DUNG!
    // =========================================================================
    assign error_mag = (error_flag && lambda_prime_sum != 8'h00) ?
                       gf_mult(omega_sum, gf_inv(lambda_prime_sum)) : 8'h00;

endmodule