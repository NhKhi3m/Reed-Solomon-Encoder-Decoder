`timescale 1ns / 1ps

module tb_rs_decoder();

    // 1. Khai bao tin hieu he thong
    reg clk;
    reg rst_n;
    reg enable;
    reg [7:0] data_in;

    // Tin hieu tu khoi Phat (Encoder)
    wire [7:0] encoded_data;
    wire enc_valid;

    // Tin hieu mo phong Nhieu tren kenh truyen (Channel Noise)
    reg  [7:0] error_mask;
    wire [7:0] noisy_data;

    // Tin hieu tu khoi Thu (Decoder)
    wire [7:0] decoded_data;
    wire dec_valid;
    wire [7:0] err_count;

    // =========================================================================
    // 2. KHOI TAO HE THONG TUONG TU THUC TE (Tx -> Channel -> Rx)
    // =========================================================================
    
    // Khoi Phat: Tao ra block 255 byte chuan (223 Data + 32 Parity)
    rs_encoder u_encoder (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_in(data_in),
        .data_out(encoded_data),
        .valid_out(enc_valid)
    );

    // Kenh Truyen: Ban loi (Error Injection) bang phep XOR
    // Neu error_mask = 0, du lieu giu nguyen. Neu khac 0, du lieu se bi lat bit.
    assign noisy_data = encoded_data ^ error_mask;

    // Khoi Thu: Nhan du lieu bi nhieu va co gang sua sai
    rs_decoder u_decoder (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enc_valid),  // Chi doc du lieu khi Encoder co ngo ra hop le
        .data_in(noisy_data),
        .data_out(decoded_data),
        .valid_out(dec_valid),
        .err_count(err_count)
    );

    // =========================================================================
    // 3. KICH THICH HE THONG (STIMULUS)
    // =========================================================================
    
    always #5 clk = ~clk; // Xung nhip 10ns (100MHz)

    integer i;
    initial begin
        // Khoi tao ban dau
        clk = 0; rst_n = 0;
        //enable = 0; data_in = 0; error_mask = 0;

        // Reset he thong
        #20 rst_n = 1;
        #10 enable = 1;

        // --- TRUYEN 1 BLOCK 255 BYTE ---
        for (i = 1; i <= 255; i = i + 1) begin
            
            // 1. Bom du lieu goc (Gia lap data la 1, 2, 3... den 223)
            if (i <= 223) data_in = i; 
            else          data_in = 8'd0; // Khong quan tam data nua, de Encoder tu xa Parity
            
            // 2. Kich ban ban loi: Co tinh lam hong 2 byte
            if (i == 15)      error_mask = 8'hA5; // Loi tai byte thu 15
            else if (i == 50) error_mask = 8'hFF; // Loi (lat toan bo bit) tai byte thu 50
            else              error_mask = 8'h00; // Cac byte khac an toan
            
            #10; // Doi 1 nhip clock cho tung byte
        end

// THÊM ?ÚNG 1 DÒNG NÀY: Ch? thêm 1 nh?p clock ?? ??y byte cu?i cùng ra an toàn
        #10;
        // Dung truyen, cho doi Decoder phan tich
        //enable = 0;
        error_mask = 0;

        // Decoder can thoi gian tinh toan (Syndrome 255 + BM 32 + Chien 255 = khoang 542 nhip)
        // Ta se doi mot khoang thoi gian du dai de quan sat
        #6000;

        $display("Mo phong Toan he thong hoan tat! Kiem tra Waveform ngay!");
        $stop;
    end

endmodule