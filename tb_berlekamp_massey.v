`timescale 1ns / 1ps

module tb_berlekamp_massey();

    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] syn_in;
    
    wire done;
    wire [135:0] err_loc_out;
    wire [7:0]   err_cnt_out;

    // Goi module Berlekamp-Massey ra de test
    berlekamp_massey uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .syn_in(syn_in),
        .done(done),
        .err_loc_out(err_loc_out),
        .err_cnt_out(err_cnt_out)
    );

    // Tao xung Clock 10ns
    always #5 clk = ~clk;

    initial begin
        clk = 0; 
        rst_n = 0; 
        start = 0;
        
        // GIAI DOAN 1: Nap ket qua Syndrome tu khoi truoc vao day
        // Day chinh la thanh qua 256-bit ban vua lam ra ban nay!
        syn_in = 256'hc06030180c06038fc9ea75b45a2d984c261387cde8743a1d8040201008040201;

        // Reset he thong
        #20; 
        rst_n = 1;
        #10; 

        // GIAI DOAN 2: Phat lenh cho FSM bat dau chay
        start = 1;
        #10; 
        start = 0; // Chi can nhay len 1 xung clock de "kich no" FSM roi tat

        // GIAI DOAN 3: Cho doi FSM lap 32 vong
        // (Thay vi uoc luong thoi gian, minh dung lenh wait de doi co done)
        wait(done == 1'b1);
        
        #50;
        $display("Mo phong BM hoan tat! Kiem tra tin hieu err_cnt_out va err_loc_out.");
        $stop;
    end

endmodule