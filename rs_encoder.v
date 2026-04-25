module rs_encoder (
    input clk,
    input rst_n,                // Reset tich cuc muc thap (Active low)
    input enable,               // Cho phep khoi hoat dong
    input      [7:0] data_in,   // Du lieu dau vao (1 byte)
    output reg [7:0] data_out,  // Du lieu dau ra (1 byte)
    output reg valid_out        // Co bao hieu du lieu dau ra hop le
);

    // 1. Dinh nghia cac he so cua da thuc sinh g(x)
    wire [7:0] g [0:31];
    assign g[0]  = 8'h2D; assign g[1]  = 8'hD8; assign g[2]  = 8'hAB; assign g[3]  = 8'h8B;
    assign g[4]  = 8'h4A; assign g[5]  = 8'h36; assign g[6]  = 8'hFC; assign g[7]  = 8'h8B;
    assign g[8]  = 8'h77; assign g[9]  = 8'hD1; assign g[10] = 8'hE1; assign g[11] = 8'hF0;
    assign g[12] = 8'hAC; assign g[13] = 8'h0B; assign g[14] = 8'hE8; assign g[15] = 8'h45;
    assign g[16] = 8'h95; assign g[17] = 8'h3E; assign g[18] = 8'hB4; assign g[19] = 8'hD7;
    assign g[20] = 8'h1D; assign g[21] = 8'h6F; assign g[22] = 8'h01; assign g[23] = 8'h1C;
    assign g[24] = 8'h3C; assign g[25] = 8'h5A; assign g[26] = 8'hD0; assign g[27] = 8'h30;
    assign g[28] = 8'h94; assign g[29] = 8'h64; assign g[30] = 8'h5D; assign g[31] = 8'h17;

    // 2. Khai bao 32 thanh ghi (Registers) cho mach LFSR
    reg [7:0] lfsr [0:31];

    // 3. Bo dem kiem soat block 255 byte (223 data + 32 parity)
    reg [7:0] byte_cnt;
    wire is_msg = (byte_cnt < 223); // Tin hieu phan loai: =1 khi dang nhan data, =0 khi dang xuat parity

    // 4. Tinh toan tin hieu hoi tiep (Feedback)
    // Neu dang nap data: feedback = data_in XOR lfsr[31]
    // Neu dang xuat parity: feedback = 0 de ngat vong lap
    wire [7:0] feedback;
    assign feedback = is_msg ? (data_in ^ lfsr[31]) : 8'h00;

    // 5. Khoi tao 32 bo nhan GF(2^8) su dung vong lap generate
    wire [7:0] mult_out [0:31];
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : mult_gen
            // Goi module ban da test thanh cong vao day
            gf28_mult mult_inst (
                .a(feedback),
                .b(g[i]),
                .p(mult_out[i])
            );
        end
    endgenerate

    // 6. Mach cap nhat trang thai (FSM & Shift Register)
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset toan bo he thong
            byte_cnt  <= 8'd0;
            data_out  <= 8'd0;
            valid_out <= 1'b0;
            for (j = 0; j < 32; j = j + 1) begin
                lfsr[j] <= 8'd0;
            end
        end else if (enable) begin
            // Quan ly bo dem block size
            if (byte_cnt < 254)
                byte_cnt <= byte_cnt + 1'b1;
            else
                byte_cnt <= 8'd0; // Reset dem khi du 255 byte

            valid_out <= 1'b1;

            if (is_msg) begin
                // --- GIAI DOAN 1: Xu ly 223 byte du lieu ---
                data_out <= data_in; // Truyen thang data ra ngo ra

                // Cap nhat LFSR
                lfsr[0] <= mult_out[0];
                for (j = 1; j < 32; j = j + 1) begin
                    lfsr[j] <= lfsr[j-1] ^ mult_out[j];
                end
            end else begin
                // --- GIAI DOAN 2: Xuat 32 byte Parity ---
                data_out <= lfsr[31]; // Xa dan tung parity byte ra ngo ra

                // Dich cac thanh ghi len tren de tiep tuc xa
                lfsr[0] <= 8'd0;
                for (j = 1; j < 32; j = j + 1) begin
                    lfsr[j] <= lfsr[j-1];
                end
            end
        end else begin
            // Khi enable = 0, khong co du lieu nao duoc xuat ra
            valid_out <= 1'b0;
        end
    end

endmodule