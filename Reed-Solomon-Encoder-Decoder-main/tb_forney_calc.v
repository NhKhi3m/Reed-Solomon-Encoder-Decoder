`timescale 1ns / 1ps

// =============================================================================
// TESTBENCH: tb_forney_calc
// Muc dich: Kiem tra module forney_calc voi 1 loi da biet
// =============================================================================
module tb_forney_calc();

    // =========================================================================
    // 1. KHAI BAO TIN HIEU
    // =========================================================================
    reg clk;
    reg rst_n;
    reg start;
    reg [255:0] syn_in;
    reg [135:0] err_loc_in;
    reg error_flag;
    wire [7:0] error_mag;

    // =========================================================================
    // 2. KHOI TAO MODULE CAN KIEM TRA (DUT - Device Under Test)
    // =========================================================================
    forney_calc u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .syn_in(syn_in),
        .err_loc_in(err_loc_in),
        .error_flag(error_flag),
        .error_mag(error_mag)
    );

    // =========================================================================
    // 3. TAO XUNG NHIP (100 MHz -> chu ky 10ns)
    // =========================================================================
    always #5 clk = ~clk;

    // =========================================================================
    // 4. HAM NHAN GF(2^8) DE TINH TOAN THAM CHIEU
    // =========================================================================
    function [7:0] gf_mult_tb;
        input [7:0] a, b;
        reg [7:0] temp_a;
        integer j;
        begin
            gf_mult_tb = 8'b0;
            temp_a = a;
            for (j = 0; j < 8; j = j + 1) begin
                if (b[j]) gf_mult_tb = gf_mult_tb ^ temp_a;
                if (temp_a[7]) temp_a = (temp_a << 1) ^ 8'h1D;
                else           temp_a = temp_a << 1;
            end
        end
    endfunction

    // =========================================================================
    // 5. KICH THICH HE THONG (STIMULUS)
    //
    //    Test case: 1 loi don tai vi tri co dinh
    //    - Dua vao syndrome va Lambda da tinh truoc
    //    - Gia lap Chien Search bang cach bat error_flag tai cycle dung
    //    - Kiem tra error_mag co bang gia tri loi da inject khong
    // =========================================================================
    integer i;
    initial begin
        // Khoi tao
        clk = 0;
        rst_n = 0;
        start = 0;
        syn_in = 256'd0;
        err_loc_in = 136'd0;
        error_flag = 0;

        // Reset
        #20;
        rst_n = 1;
        #10;

        // =====================================================================
        // TEST CASE 1: Kiem tra co ban
        //
        // Su dung syndrome va Lambda tu 1 truong hop loi da biet:
        // - 1 loi tai byte 0, gia tri loi = 0x01 (don gian nhat)
        // - Lambda(x) = 1 + alpha^0 * x = 1 + x (vi chi 1 loi tai vi tri 0)
        //   X_0 = alpha^0 = 1, nen Lambda(x) = 1 + x (nghiem tai x = 1 = alpha^0)
        //
        // Lambda: Lambda[0] = 0x01, Lambda[1] = 0x01, Lambda[2..16] = 0x00
        // =====================================================================
        err_loc_in = 136'd0;
        err_loc_in[7:0]   = 8'h01; // Lambda_0 = 1
        err_loc_in[15:8]  = 8'h01; // Lambda_1 = 1

        // Syndrome cho 1 loi e_0 = 0x01 tai vi tri 0:
        // S_k = e_0 * (alpha^k)^0 = e_0 = 0x01 voi moi k
        // Nhung vi syndrome_calc dung convention S[j] = S_{j+1},
        // nen syn_in[j*8 +: 8] = 0x01 voi moi j
        for (i = 0; i < 32; i = i + 1) begin
            syn_in[i*8 +: 8] = 8'h01;
        end

        // Bat dau Forney pipeline
        #10;
        start = 1;
        #10;
        start = 0;

        // Cho Forney chay 1 cycle (vi tri 0 = cycle 1)
        // Sau start, tai cycle 1, Forney da tinh Omega(alpha^(-1)) va Lambda'(alpha^(-1))
        #10;

        // Bat error_flag de gia lap Chien phat hien loi tai vi tri 0
        error_flag = 1;
        #10;

        // Doc ket qua
        $display("=== TEST CASE 1: 1 loi tai vi tri 0, gia tri 0x01 ===");
        $display("error_mag = 0x%h (Ky vong: 0x01)", error_mag);
        if (error_mag == 8'h01)
            $display(">>> KET QUA: DUNG! <<<");
        else
            $display(">>> KET QUA: SAI! Kiem tra lai Forney pipeline <<<");

        error_flag = 0;
        #10;

        // =====================================================================
        // Ket thuc mo phong
        // =====================================================================
        #100;
        $display("\n=== Mo phong Forney Testbench hoan tat ===");
        $stop;
    end

endmodule