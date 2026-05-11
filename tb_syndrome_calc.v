`timescale 1ns / 1ps

module tb_syndrome_calc();

    reg clk;
    reg rst_n;
    reg enable;
    reg [7:0] data_in;
    
    wire valid_out;
    wire [255:0] syn_out;

    syndrome_calc uut (
        .clk(clk),
        .rst_n(rst_n),
        .enable(enable),
        .data_in(data_in),
        .valid_out(valid_out),
        .syn_out(syn_out)
    );

    always #5 clk = ~clk; // Clock 10ns

    integer i;
    initial begin
        clk = 0; rst_n = 0; enable = 0; data_in = 8'h00;
        
        #20; rst_n = 1;
        #10; enable = 1;

        // GIAI DOAN 1: Truyen 253 byte 0 (Tu x^254 den x^2)
        for (i = 0; i < 253; i = i + 1) begin
            data_in = 8'h00;
            #10;
        end

        // GIAI DOAN 2: Truyen byte co loi
        // Huyen bi o day: Truyen 1 vao vi tri x^1
        data_in = 8'h01; 
        #10;

        // GIAI DOAN 3: Truyen byte cuoi cung (Vi tri x^0)
        data_in = 8'h00; 
        #10;

        enable = 0; // Ket thuc block

        #50;
        $display("Mo phong hoan tat! Kiem tra co valid_out va 256-bit syn_out.");
        $stop;
    end

endmodule