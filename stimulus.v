`timescale 1ns / 1ps

module tb_rs_encoder();

    // 1. Khai bao tin hieu
    reg clk;
    reg rst_n;
    reg enable;
    reg [7:0] data_in;
    
    wire [7:0] data_out;
    wire valid_out;

    // 2. Khoi tao UUT (Unit Under Test)
    rs_encoder uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_in(data_in),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    // 3. Tao xung nhịp (Clock generation) - 100MHz (Chu ky 10ns)
    always #5 clk = ~clk;

    // 4. Kich thich (Stimulus)
    integer i;
    
    initial begin
        // Khoi tao trang thai ban dau
        clk = 0;
        rst_n = 0;
        enable = 0;
        data_in = 8'd0;

        // Reset he thong (Duy tri rst_n muc thap trong 20ns)
        #20;
        rst_n = 1;
        
        // Bat dau cho phep hoat dong
        #10;
        enable = 1;

        // --- GIAI DOAN 1: Nap 223 byte du lieu ---
        // De de quan sat tren Waveform, ta nap cac gia tri tu 1 den 223
        for (i = 1; i <= 223; i = i + 1) begin
            data_in = i;
            #10; // Doi 1 chu ky clock (10ns)
        end

        // --- GIAI DOAN 2: Xa 32 byte Parity ---
        // Trong luc xa parity, data_in khong con y nghia, ep ve 0
        data_in = 8'd0;
        for (i = 0; i < 32; i = i + 1) begin
            #10; // Doi 32 chu ky clock de UUT xuat het parity
        end

        // --- GIAI DOAN 3: Kiem tra block tiep theo (Tuy chon) ---
        // Thu tat enable vai nhip de xem he thong co dung lai khong
        enable = 0;
        #30;
        
        $display("Mo phong hoan tat! Kiem tra Waveform de xem block 255 byte dau ra.");
        $stop; // Tam dung mo phong de xem dang song
    end

endmodule