module chien_search (
    input clk,
    input rst_n,
    input start,
    input      [135:0] err_loc_in, // 17 byte Da thuc Lambda(x) tu khoi BM
    input      [7:0]   err_cnt_in, // So loi tim thay tu khoi BM
    output reg done,
    output reg error_flag,         // Bat len 1 neu tim thay loi tai vi tri hien tai
    output reg [7:0] err_pos       // Chi so byte dang kiem tra (0-indexed, tang dan)
);

    // =========================================================================
    // 1. BANG NGHICH DAO: inv_root[k] = alpha^(-k) = alpha^(255-k)
    //    Dung de duyet FORWARD: tu vi tri 0 den 254
    //
    //    Ly do doi chieu: Khi duyet forward, tai cycle c (1-indexed),
    //    ta danh gia Lambda(alpha^(-c)), tuong ung voi vi tri c-1 (0-indexed).
    //    Neu Lambda(alpha^(-c)) = 0, byte tai vi tri c-1 bi loi.
    //
    //    Dieu nay lam cho error_flag fire tai cycle (353 + j) tuong ung vi tri j,
    //    va delay_line[353] trong rs_decoder chinh xac chua byte j. ✓
    //
    //    Tinh toan: alpha^(-k) = gf_inv(alpha^k) trong GF(2^8) voi poly 0x11D
    //    alpha^(-0)  = alpha^0   = 0x01
    //    alpha^(-1)  = alpha^254 = 0x8E   (gf_inv(0x02) = 0x8E)
    //    alpha^(-2)  = alpha^253 = 0x47
    //    ...
    // =========================================================================
    wire [7:0] root [0:16];
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
    assign root[16]  = 8'h4C; // alpha^16

    // =========================================================================
    // 2. HAM NHAN GF(2^8)
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

    // =========================================================================
    // 3. KHAI BAO THANH GHI VA BIEN DEM
    // =========================================================================
    reg [7:0] Lambda_reg [0:16]; // 17 thanh ghi cho Lambda_0..Lambda_16
    reg [8:0] cycle_cnt;         // Dem tu 1 den 255
    reg active;                  // Co danh dau dang trong qua trinh quet
    integer i, idx;
    reg [7:0] sum;               // Bien cong don XOR

    // =========================================================================
    // 4. PIPELINE QUET 255 VI TRI (FORWARD ORDER: vi tri 0 -> 254)
    //
    //    Khi start = 1 (posedge):
    //      Lambda_reg[k] <= Lambda_k * inv_root[k]  (= Lambda_k * alpha^(-k))
    //      cycle_cnt = 1
    //    -> Sum tai cycle 1 = Lambda(alpha^(-1)) -> kiem tra vi tri 0
    //
    //    Moi cycle tiep theo:
    //      Lambda_reg[k] <= Lambda_reg[k] * inv_root[k]
    //      cycle_cnt += 1
    //    -> Sum tai cycle c = Lambda(alpha^(-c)) -> kiem tra vi tri c-1
    //
    //    Sau 255 cycles: tat ca vi tri 0..254 da duoc kiem tra
    // =========================================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            active <= 0;
            done <= 0;
            cycle_cnt <= 0;
            for (i = 0; i <= 16; i = i + 1) Lambda_reg[i] <= 0;
        end else if (start) begin
            // Kich hoat: Nap va nhan lan dau voi root cho cycle 1
            for (i = 0; i <= 16; i = i + 1) begin
                Lambda_reg[i] <= gf_mult(err_loc_in[i*8 +: 8], root[i]);
            end
            cycle_cnt <= 1;
            active <= 1;
            done <= 0;
        end else if (active) begin
            // Cac chu ky tiep theo: Tiep tuc nhan voi root
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

    // =========================================================================
    // 5. MACH TO HOP DANH GIA KET QUA (XOR Tree)
    //    Neu Sum = 0, vi tri hien tai bi loi
    //    err_pos = cycle_cnt - 1 (0-indexed, tang dan tu 0 den 254)
    // =========================================================================
    always @(*) begin
        sum = 8'h00;
        // Cong don 17 thanh ghi
        for (idx = 0; idx <= 16; idx = idx + 1) begin
            sum = sum ^ Lambda_reg[idx];
        end

        // Neu Tong = 0 va dang hoat dong va co loi -> Bao loi!
        if (active && (sum == 8'h00) && (err_cnt_in > 0)) begin
            error_flag = 1'b1;
        end else begin
            error_flag = 1'b0;
        end

        // Vi tri byte: cycle_cnt - 1 (0-indexed, forward order)
        if (active) err_pos = cycle_cnt - 1;
        else        err_pos = 0;
    end

endmodule
