`timescale 1ns / 1ps

module tb_forney_calc();
    
    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] syn_in;
    reg [135:0] err_loc_in;
    reg [7:0]   err_cnt_in;

    wire done;
    wire error_flag;
    wire [7:0] err_pos;
    wire [7:0] error_mag;

    // 1. Goi khối Chien Search (Dò vị trí)
    chien_search chien (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .err_loc_in(err_loc_in),
        .err_cnt_in(err_cnt_in),
        .done(done),
        .error_flag(error_flag),
        .err_pos(err_pos)
    );

    // 2. Goi khối Forney (Tính độ lớn lỗi), nối cờ error_flag sang
    forney_calc forney (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .syn_in(syn_in),
        .err_loc_in(err_loc_in),
        .error_flag(error_flag),
        .error_mag(error_mag)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; start = 0;
        
        // --- GIAI DOAN 1: Nap toan bo Data tu Syndrome va BM ---
        syn_in = 256'hc06030180c06038fc9ea75b45a2d984c261387cde8743a1d8040201008040201;
        
        err_cnt_in = 8'd1;  
        err_loc_in = 136'd0; 
        err_loc_in[7:0]  = 8'h01; 
        err_loc_in[15:8] = 8'h02; 

        #20 rst_n = 1;
        
        // --- GIAI DOAN 2: Bat dau quet ---
        #10 start = 1;
        #10 start = 0;

        // --- GIAI DOAN 3: Cho quet xong ---
        wait(done);
        
        #50;
        $display("Mo phong Forney hoan tat! Kiem tra error_mag.");
        $stop;
    end
endmodule