`timescale 1ns / 1ps

module tb_rs_encoder();

    // 1. Khai bao tin hieu
    reg clk;
    reg rst_n;
    reg enable;
    reg [7:0] data_in;
    
    wire [7:0] data_out;
    wire valid_out;

    // 2. Goi Unit Under Test (UUT)
    rs_encoder uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_in(data_in),
        .data_out(data_out),
        .valid_out(valid_out)
    );

    // 3. Tao xung clock 100MHz (Chu ky 10ns)
    always #5 clk = ~clk;

    // 4. Kich ban Test (Test Sequence)
    integer i;
    initial begin
        // Khoi tao
        clk = 0;
        rst_n = 0;
        enable = 0;
        data_in = 8'd0;

        // Reset he thong
        #20 rst_n = 1;
        
        // Bat dau hoat dong (Keo enable len 1)
        #10 enable = 1;

        $display("--- BAT DAU GUI 223 BYTE DATA ---");
        // Giai doan 1: Truyen 223 byte du lieu (Vi du: cac so dem tu 1 den 223)
        for (i = 1; i <= 223; i = i + 1) begin
            data_in = i;
            #10;
        end

        $display("--- BAT DAU XA 32 BYTE PARITY ---");
        // Giai doan 2: De module tu dong xuat 32 byte parity
        // (Trong thoi gian nay is_msg = 0, data_in bi bo qua nen ta set ve 0)
        data_in = 8'd0;
        for (i = 0; i < 32; i = i + 1) begin
            #10;
        end

        // Giai doan 3: Ket thuc block truyen
        enable = 0;
        #50;
        
        $display("--- MO PHONG HOAN TAT ---");
        $stop;
    end

endmodule