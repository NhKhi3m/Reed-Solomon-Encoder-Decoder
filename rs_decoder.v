module rs_decoder (
    input clk,
    input rst_n,
    input enable,
    input      [7:0] data_in,
    output reg [7:0] data_out,
    output reg valid_out,
    output     [7:0] err_count
);

    // =========================================================================
    // TIN HIEU NOI BO
    // =========================================================================
    wire syn_valid;
    wire [255:0] syn_out;

    wire bm_done;
    wire [135:0] err_loc_out;
    wire [7:0]   err_cnt_out;

    wire chien_done;
    wire error_flag;
    wire [7:0] err_pos;

    wire [7:0] error_mag;

    // =========================================================================
    // 1. KHOI TAO SYNDROME & CHOT DU LIEU
    // =========================================================================
    syndrome_calc u_syndrome (
        .clk(clk), .rst_n(rst_n), .enable(enable), .data_in(data_in),
        .valid_out(syn_valid), .syn_out(syn_out)
    );

    // Thanh ghi chot Syndrome: Giu co dinh gia tri de Forney tinh toan
    reg [255:0] latched_syn;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) latched_syn <= 256'd0;
        else if (syn_valid) latched_syn <= syn_out;
    end

    // =========================================================================
    // 2. KHOI TAO BM, CHIEN VA FORNEY
    //
    //    PHAN TICH TIMING CHI TIET (Chien FORWARD order):
    //
    //    Goi Q = posedge dau tien decoder nhan byte voi enable=1
    //    Byte j nhap tai posedge Q+j (j = 0..254)
    //
    //    Syndrome: byte_cnt tu 0, dem 255 bytes
    //      syn_valid = 1 SAU posedge Q+254
    //
    //    BM: start = syn_valid
    //      BM thay start=1 tai posedge Q+255 -> IDLE: load S[]
    //      32 iterations x 3 cycles = 96 cycles (Q+256 -> Q+351)
    //      FINISH tai posedge Q+352: done <= 1
    //      bm_done = 1 SAU posedge Q+352
    //
    //    Chien: start = bm_done
    //      Chien thay start=1 tai posedge Q+353 -> nap Lambda_reg, cycle_cnt=1
    //      SAU posedge Q+353: Lambda(alpha^(-1)) -> kiem tra vi tri 0
    //      error_flag (combinational) fire SAU posedge Q+353+j cho vi tri j
    //      error_flag duoc sample (doc boi data_out <=) tai posedge Q+354+j
    //
    //    Delay line (non-blocking semantics):
    //      data_out tai posedge T doc delay_line[d] TRUOC posedge T
    //      = data_in tu posedge (T - 1 - d)
    //
    //    Can: data_in@(Q+354+j - 1 - d) = data_in@(Q+j)
    //    => 354+j-1-d = j => d = 353
    //
    //    KET LUAN: delay = 353
    // =========================================================================
    berlekamp_massey u_bm (
        .clk(clk), .rst_n(rst_n),
        .start(syn_valid),
        .syn_in(syn_out),
        .done(bm_done), .err_loc_out(err_loc_out), .err_cnt_out(err_cnt_out)
    );

    chien_search u_chien (
        .clk(clk), .rst_n(rst_n),
        .start(bm_done),
        .err_loc_in(err_loc_out), .err_cnt_in(err_cnt_out),
        .done(chien_done), .error_flag(error_flag), .err_pos(err_pos)
    );

    forney_calc u_forney (
        .clk(clk), .rst_n(rst_n),
        .start(bm_done),         // Forney bat dau cung luc voi Chien
        .syn_in(latched_syn),    // Dung syndrome da chot
        .err_loc_in(err_loc_out), .error_flag(error_flag),
        .error_mag(error_mag)
    );

    assign err_count = err_cnt_out;

    // =========================================================================
    // 3. BO DEM TRE VA MACH SUA LOI (DELAY BUFFER & CORRECTION)
    //
    //    delay_line[353] tai posedge Q+354+j:
    //      doc gia tri TRUOC posedge = data_in tu posedge (Q+354+j-1-353) = Q+j
    //      = byte j (dung!)
    //
    //    Khi error_flag = 1 (vi tri j bi loi):
    //      data_out = delay_line[353] ^ error_mag -> byte da sua
    //    Khi error_flag = 0:
    //      data_out = delay_line[353] -> byte giu nguyen
    // =========================================================================
    reg [7:0] delay_line [0:545];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i <= 545; i = i + 1) delay_line[i] <= 8'd0;
            data_out <= 8'd0;
            valid_out <= 1'b0;
        end else begin
            // Dich du lieu lien tuc (shift register)
            delay_line[0] <= data_in;
            for (i = 1; i <= 545; i = i + 1) begin
                delay_line[i] <= delay_line[i-1];
            end

            // Sua loi tai dung vi tri bang XOR voi error_mag
            if (error_flag) begin
                data_out <= delay_line[353] ^ error_mag;
            end else begin
                data_out <= delay_line[353];
            end

            valid_out <= 1'b1;
        end
    end

endmodule