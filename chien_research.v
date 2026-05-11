module chien_search (
    input clk,
    input rst_n,
    input start,
    input      [135:0] err_loc_in, // 17 byte Da thuc Lambda(x) tu khoi BM
    input      [7:0]   err_cnt_in, // So loi tim thay tu khoi BM
    output reg done,
    output reg error_flag,         // Bat len 1 neu tim thay loi tai vi tri hien tai
    output reg [7:0] err_pos       // Chi so cua byte dang kiem tra (Tu 254 giam ve 0)
);

    // 1. Dinh nghia cac root alpha^0 den alpha^16
    wire [7:0] root [0:16];
    assign root[0]  = 8'h01; assign root[1]  = 8'h02; assign root[2]  = 8'h04;
    assign root[3]  = 8'h08; assign root[4]  = 8'h10; assign root[5]  = 8'h20;
    assign root[6]  = 8'h40; assign root[7]  = 8'h80; assign root[8]  = 8'h1D;
    assign root[9]  = 8'h3A; assign root[10] = 8'h74; assign root[11] = 8'hE8;
    assign root[12] = 8'hCD; assign root[13] = 8'h87; assign root[14] = 8'h13;
    assign root[15] = 8'h26; assign root[16] = 8'h4C;

    // 2. Ham nhan GF(2^8)
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

    // 3. Khai bao thanh ghi va bien dem
    reg [7:0] Lambda_reg [0:16];
    reg [8:0] cycle_cnt; // Dem tu 1 den 255
    reg active;          // Co danh dau dang trong qua trinh quet
    integer i, idx;
    reg [7:0] sum;       // Bien dung de cong don XOR

    // 4. Mạch Pipeline quet 255 vi tri
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 0;
            done <= 0;
            cycle_cnt <= 0;
            for (i = 0; i <= 16; i = i + 1) Lambda_reg[i] <= 0;
        end else if (start) begin
            // Kich hoat: Vua nap vao, vua nhan luon lan dau tien cho cycle 1
            for (i = 0; i <= 16; i = i + 1) begin
                Lambda_reg[i] <= gf_mult(err_loc_in[i*8 +: 8], root[i]);
            end
            cycle_cnt <= 1;
            active <= 1;
            done <= 0;
        end else if (active) begin
            // Cac chu ky tiep theo: Tiep tuc nhan voi nghiem alpha
            for (i = 0; i <= 16; i = i + 1) begin
                Lambda_reg[i] <= gf_mult(Lambda_reg[i], root[i]);
            end
            
            // Kiem tra ket thuc 255 vong
            if (cycle_cnt == 255) begin
                active <= 0;
                done <= 1;
            end else begin
                cycle_cnt <= cycle_cnt + 1;
            end
        end else begin
            done <= 0;
        end
    end

    // 5. Mạch to hop danh gia ket qua (XOR Tree)
    always @(*) begin
        sum = 8'h00;
        // Cong don cac thanh ghi hien tai
        for (idx = 0; idx <= 16; idx = idx + 1) begin
            sum = sum ^ Lambda_reg[idx];
        end

        // Neu Tong = 0 -> Vi tri hien tai bi loi!
        // (Luu y: Chi bao loi neu err_cnt_in > 0 de tranh canh bao gia khi he thong khong co loi)
        if (active && (sum == 8'h00) && (err_cnt_in > 0)) begin
            error_flag = 1'b1;
        end else begin
            error_flag = 1'b0;
        end

        // Tinh toan chi so byte (Giam dan tu 254 ve 0 de khop voi thu tu du lieu)
        if (active) err_pos = 255 - cycle_cnt;
        else        err_pos = 0;
    end

endmodule