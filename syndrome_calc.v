module syndrome_calc (
    input clk,
    input rst_n,                // Reset tich cuc muc thap
    input enable,               // Cho phep khoi hoat dong
    input      [7:0] data_in,   // Byte du lieu thu duoc tu kenh truyen
    output reg valid_out,       // Co bao hieu tinh toan xong 32 Syndrome
    output reg [255:0] syn_out  // 32 byte Syndrome gop chung vao 1 bus 256-bit
);

    // 1. Dinh nghia 32 nghiem alpha^0 den alpha^31 cua truong GF(2^8)
    // Day la hang so nhan cho 32 bo tinh Syndrome
// 1. Dinh nghia 32 nghiem tu alpha^1 den alpha^32 cua truong GF(2^8)
    wire [7:0] root [0:31];
    assign root[0]  = 8'h02; assign root[1]  = 8'h04; assign root[2]  = 8'h08; assign root[3]  = 8'h10;
    assign root[4]  = 8'h20; assign root[5]  = 8'h40; assign root[6]  = 8'h80; assign root[7]  = 8'h1D;
    assign root[8]  = 8'h3A; assign root[9]  = 8'h74; assign root[10] = 8'hE8; assign root[11] = 8'hCD;
    assign root[12] = 8'h87; assign root[13] = 8'h13; assign root[14] = 8'h26; assign root[15] = 8'h4C;
    assign root[16] = 8'h98; assign root[17] = 8'h2D; assign root[18] = 8'h5A; assign root[19] = 8'hB4;
    assign root[20] = 8'h75; assign root[21] = 8'hEA; assign root[22] = 8'hC9; assign root[23] = 8'h8F;
    assign root[24] = 8'h03; assign root[25] = 8'h06; assign root[26] = 8'h0C; assign root[27] = 8'h18;
    assign root[28] = 8'h30; assign root[29] = 8'h60; assign root[30] = 8'hC0; assign root[31] = 8'h9D;

    // 2. Khai bao 32 thanh ghi de luu ket qua cong don
    reg [7:0] syn_reg [0:31];

    // 3. Ket noi 32 bo nhan GF(2^8)
    wire [7:0] mult_out [0:31];
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : syn_mult_gen
            // S_i_moi = S_i_cu * alpha^i
            gf28_mult mult_inst (
                .a(syn_reg[i]),
                .b(root[i]),
                .p(mult_out[i])
            );
        end
    endgenerate

    // 4. Mạch FSM va Datapath cap nhat
    reg [7:0] byte_cnt;
    integer j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            byte_cnt <= 8'd0;
            valid_out <= 1'b0;
            for (j = 0; j < 32; j = j + 1) begin
                syn_reg[j] <= 8'd0;
            end
        end else if (enable) begin
            // Moi chu ky nhan 1 byte, neu la byte dau tien thi gan truc tiep
            if (byte_cnt == 0) begin
                for (j = 0; j < 32; j = j + 1) begin
                    syn_reg[j] <= data_in;
                end
            end else begin
                // Cac byte tiep theo, lay ket qua nhan XOR voi data_in
                for (j = 0; j < 32; j = j + 1) begin
                    syn_reg[j] <= mult_out[j] ^ data_in;
                end
            end

            // Kiem soat dem 255 byte
            if (byte_cnt < 254) begin
                byte_cnt <= byte_cnt + 1'b1;
                valid_out <= 1'b0;
            end else begin
                byte_cnt <= 8'd0;
                valid_out <= 1'b1; // Tinh xong 255 byte, keo co Valid len
            end
        end else begin
            valid_out <= 1'b0;
        end
    end

    // 5. Day 32 byte (thanh ghi) vao 1 bus 256-bit de de xuat ra ngoai
    integer k;
    always @(*) begin
        for(k = 0; k < 32; k = k + 1) begin
            syn_out[k*8 +: 8] = syn_reg[k];
        end
    end

endmodule