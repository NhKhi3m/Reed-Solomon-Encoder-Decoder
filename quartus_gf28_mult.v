module gf28_mult (
    input      [7:0] a,    // Toan hang thu nhat (8 bit)
    input      [7:0] b,    // Toan hang thu hai (8 bit)
    output reg [7:0] p     // Ket qua phep nhan (8 bit)
);

    integer i;
    reg [7:0] temp_a;

    always @(*) begin
        p = 8'b0;          // Khoi tao ket qua ban dau bang 0
        temp_a = a;        // Luu toan hang 'a' vao thanh ghi tam de xu ly

        // Lap qua toan bo 8 bit cua toan hang 'b'
        for (i = 0; i < 8; i = i + 1) begin
            
            // 1. Neu bit thu i cua 'b' la 1, cong (XOR) temp_a vao ket qua
            if (b[i]) begin
                p = p ^ temp_a; 
            end
            
            // 2. Chuan bi gia tri temp_a cho vong lap tiep theo (Tuong duong nhan voi x)
            // Kiem tra xem bit cao nhat (MSB - bit 7) cua temp_a co bang 1 hay khong truoc khi dich
            if (temp_a[7]) begin
                // Neu MSB = 1: Dich trai 1 bit va XOR voi da thuc sinh (primitive polynomial) 0x1D
                temp_a = (temp_a << 1) ^ 8'h1D;
            end else begin
                // Neu MSB = 0: Chi can dich trai 1 bit
                temp_a = temp_a << 1;
            end
        end
    end

endmodule