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
            
            
            // 1. Kịch bản của Trạm Phát: Bơm chuỗi "DH CNTT" vào rs_encoder
            if      (i == 1) data_in = "T"; // 8'h44
            else if (i == 2) data_in = "R"; // 8'h48
            else if (i == 3) data_in = "U"; // 8'h20
            else if (i == 4) data_in = "O"; // 8'h43
            else if (i == 5) data_in = "N"; // 8'h4E (Gốc là chữ N)
            else if (i == 6) data_in = "G"; // 8'h54 (Gốc là chữ T)
            else if (i == 7) data_in = " "; // 8'h54
            else if (i == 8) data_in = "D"; // 216 byte khoảng trống còn lại nhồi số 0
            else if (i == 9) data_in = "H"; // 216 byte khoảng trống còn lại nhồi số 0
            else if (i == 10) data_in = " ";
            else if (i == 11) data_in = "C";
            else if (i == 12) data_in = "O";
            else if (i == 13) data_in = "N";
            else if (i == 14) data_in = "G";
            else if (i == 15) data_in = " ";
            else if (i == 16) data_in = "N";
            else if (i == 17) data_in = "G";    
            else if (i == 18) data_in = "H";
            else if (i == 19) data_in = "E";
            else if (i == 20) data_in = " ";
            else if (i == 21) data_in = "T";
            else if (i == 22) data_in = "H";
            else if (i == 23) data_in = "O";
            else if (i == 24) data_in = "N";
            else if (i == 25) data_in = "G";
            else if (i == 26) data_in = " ";
            else if (i == 27) data_in = "T";
            else if (i == 28) data_in = "I";
            else if (i == 29) data_in = "N";
            else              data_in = 8'h00; // Các byte còn lại nhồi số 0
            
            // 2. Kịch bản của Kênh Truyền
            if      (i == 2) error_mask = 8'h20; // Đánh hỏng chữ N thành T
            else if (i == 3) error_mask = 8'h48; // Đánh hỏng chữ T thành N
            else             error_mask = 8'h00; // Các ký tự khác đi qua an toàn
            
            #10;
        end

// TH�M ?�NG 1 D�NG N�Y: Ch? th�m 1 nh?p clock ?? ??y byte cu?i c�ng ra an to�n
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