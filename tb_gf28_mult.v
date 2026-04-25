`timescale 1ns / 1ps

module tb_gf28_mult();

    // Cac tin hieu dung de kich thich trong Testbench
    reg  [7:0] a_tb;
    reg  [7:0] b_tb;
    wire [7:0] p_tb;

    // Khoi tao khoi thiet bi can kiem tra (Unit Under Test - UUT)
    gf28_mult uut (
        .a(a_tb),
        .b(b_tb),
        .p(p_tb)
    );

    // Kich ban mo phong (Test sequence)
    initial begin
        // Bai test 1: 0x07 * 0x09
        // Trong truong GF(2^8) voi da thuc 0x1D, ket qua tinh toan tay phai ra 0x3F
        a_tb = 8'h07;
        b_tb = 8'h09;
        #10; // Doi 10 nanosecond de tin hieu on dinh
        
        if (p_tb == 8'h3F)
            $display("Test 1 Thanh cong: 0x07 * 0x09 = 0x%h", p_tb);
        else
            $display("Test 1 That bai: Mong doi 0x3F, nhung nhan duoc 0x%h", p_tb);

        // Bai test 2: Bat ky so nao nhan voi 1 cung phai tra ve chinh no
        a_tb = 8'hA5;
        b_tb = 8'h01;
        #10; // Doi them 10 nanosecond
        
        if (p_tb == 8'hA5)
            $display("Test 2 Thanh cong: 0xA5 * 0x01 = 0x%h", p_tb);
        else
            $display("Test 2 That bai: Mong doi 0xA5, nhung nhan duoc 0x%h", p_tb);

        $finish; // Ket thuc qua trinh mo phong
    end

endmodule