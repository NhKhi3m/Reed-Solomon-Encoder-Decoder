`timescale 1ns / 1ps

module tb_chien_search();
    
    reg clk;
    reg rst_n;
    reg start;
    reg [135:0] err_loc_in;
    reg [7:0]   err_cnt_in;

    wire done;
    wire error_flag;
    wire [7:0] err_pos;

    // Goi khoi Chien Search
    chien_search uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .err_loc_in(err_loc_in),
        .err_cnt_in(err_cnt_in),
        .done(done),
        .error_flag(error_flag),
        .err_pos(err_pos)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; start = 0;
        
        // --- GIAI DOAN 1: Nap ket qua tu khoi BM vao ---
        err_cnt_in = 8'd1;  // Bao rang he thong co 1 loi
        err_loc_in = 136'd0; 
        err_loc_in[7:0]  = 8'h01; // Bac 0 (Lambda_0)
        err_loc_in[15:8] = 8'h02; // Bac 1 (Lambda_1)

        // Reset
        #20 rst_n = 1;
        
        // --- GIAI DOAN 2: Bat dau quet ---
        #10 start = 1;
        #10 start = 0;

        // --- GIAI DOAN 3: Cho quet xong 255 vi tri ---
        wait(done);
        
        #50;
        $display("Mo phong Chien Search hoan tat! Kiem tra co error_flag tren Waveform.");
        $stop;
    end
endmodule