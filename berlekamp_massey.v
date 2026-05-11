module berlekamp_massey (
    input clk,
    input rst_n,
    input start,                     // Tin hieu bat dau tu khoi Syndrome
    input      [255:0] syn_in,       // 32 byte Syndrome
    output reg done,                 // Co bao hieu tinh toan xong
    output reg [135:0] err_loc_out,  // Da thuc dinh vi loi Lambda(x) gom 17 byte (16 bac + 1)
    output reg [7:0]   err_cnt_out   // So luong loi phat hien duoc (L)
);

    // Dinh nghia cac trang thai cho FSM
    localparam IDLE       = 3'd0;
    localparam CALC_DELTA = 3'd1;
    localparam UPDATE     = 3'd2;
    localparam SHIFT_B    = 3'd3;
    localparam FINISH     = 3'd4;

    reg [2:0] state, next_state;

    // Khai bao cac mang thanh ghi
    reg [7:0] S [0:31];       // Syndrome
    reg [7:0] Lambda [0:16];  // Error Locator Polynomial
    reg [7:0] B [0:16];       // Scratchpad Polynomial
    
    reg [7:0] delta;          // Sai so (Discrepancy)
    reg [7:0] gamma;          // delta cua vong lap truoc
    reg [7:0] L;              // So loi hien tai
    reg [7:0] k;              // Bien dem vong lap (0 -> 31)

    integer i;
    integer idx; // Bien dem cho mach to hop

    // 1. Chuyen trang thai FSM (Sequential Logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= IDLE;
        else        state <= next_state;
    end

    // 2. Logic chuyen trang thai (Combinational Logic)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:       if (start) next_state = CALC_DELTA;
            CALC_DELTA: next_state = UPDATE;
            UPDATE:     next_state = SHIFT_B;
            SHIFT_B:    if (k == 31) next_state = FINISH;
                        else         next_state = CALC_DELTA;
            FINISH:     next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end

    // Function phep nhan GF(2^8)
    function [7:0] gf_mult;
        input [7:0] a, b;
        reg [7:0] temp_a;
        integer j;
        begin
            gf_mult = 8'b0;
            temp_a = a;
            for (j = 0; j < 8; j = j + 1) begin
                if (b[j]) gf_mult = gf_mult ^ temp_a;
                if (temp_a[7]) temp_a = (temp_a << 1) ^ 8'h1D;
                else           temp_a = temp_a << 1;
            end
        end
    endfunction

    // =====================================================================
    // FIXED: Tách riêng bộ tính delta ra thành mạch tổ hợp để cộng dồn tức thời
    // =====================================================================
    reg [7:0] temp_delta;
    always @(*) begin
        temp_delta = S[k];
        for (idx = 1; idx <= 16; idx = idx + 1) begin
            if (idx <= L && k >= idx) begin
                temp_delta = temp_delta ^ gf_mult(Lambda[idx], S[k-idx]);
            end
        end
    end
    // =====================================================================

    // 3. Logic xu ly Data Path
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 0;
            err_cnt_out <= 0;
            err_loc_out <= 0;
            k <= 0;
            L <= 0;
            delta <= 0;
            gamma <= 8'h01; 
            for (i = 0; i <= 16; i = i + 1) begin
                Lambda[i] <= 0;
                B[i] <= 0;
            end
            for (i = 0; i < 32; i = i + 1) S[i] <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 0;
                    k <= 0;
                    L <= 0;
                    gamma <= 8'h01;
                    // Nhan 32 byte Syndrome tu bus vao mang
                    for (i = 0; i < 32; i = i + 1) S[i] <= syn_in[i*8 +: 8];
                    
                    // Khoi tao da thuc
                    for (i = 0; i <= 16; i = i + 1) begin
                        Lambda[i] <= (i == 0) ? 8'h01 : 8'h00; // Lambda = 1
                        B[i]      <= (i == 1) ? 8'h01 : 8'h00; // B = x (Ban sua rat dung!)
                    end
                end

                CALC_DELTA: begin
                    // FIXED: Chi can chot ket qua tu mach to hop vao thanh ghi
                    delta <= temp_delta;
                end

                UPDATE: begin
                    if (delta != 8'h00) begin 
                        // Cap nhat Lambda = (gamma * Lambda) XOR (delta * B)
                        for (i = 0; i <= 16; i = i + 1) begin
                            Lambda[i] <= gf_mult(gamma, Lambda[i]) ^ gf_mult(delta, B[i]);
                        end

                        // Neu 2*L <= k, cap nhat lai B = old_Lambda va L, gamma
                        if ((L << 1) <= k) begin
                            for (i = 0; i <= 16; i = i + 1) B[i] <= Lambda[i];
                            L <= k + 1 - L;
                            gamma <= delta;
                        end
                    end 
                end

                SHIFT_B: begin
                    // Dich da thuc B tuong duong voi B(x) = B(x) * x
                    for (i = 16; i > 0; i = i - 1) begin
                        B[i] <= B[i-1];
                    end
                    B[0] <= 8'h00;
                    
                    k <= k + 1; // Tang vong lap
                end

                FINISH: begin
                    done <= 1;
                    err_cnt_out <= L;
                    // Noi mang Lambda vao bus output (17 byte = 136 bit)
                    for (i = 0; i <= 16; i = i + 1) begin
                        err_loc_out[i*8 +: 8] <= Lambda[i];
                    end
                end
            endcase
        end
    end

endmodule