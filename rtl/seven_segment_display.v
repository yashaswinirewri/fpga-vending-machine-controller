
module seven_segment_display #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer REFRESH_HZ = 1000
)(
    input wire clk,
    input wire rst,
    input wire [15:0] value,

    output reg [7:0] seg,
    output reg [3:0] an
);

    // Clock divider for display multiplexing
    localparam integer REFRESH_COUNT =
        CLK_FREQ / (REFRESH_HZ * 4);

    reg [31:0] refresh_counter;
    reg [1:0] digit_select;
    reg [3:0] digit;

    wire [15:0] number;
    assign number = value % 10000;

    // Generate digit selection timing
    always @(posedge clk) begin
        if (rst) begin
            refresh_counter <= 0;
            digit_select <= 0;
        end
        else begin
            if (refresh_counter >= REFRESH_COUNT - 1) begin
                refresh_counter <= 0;
                digit_select <= digit_select + 1'b1;
            end
            else begin
                refresh_counter <= refresh_counter + 1'b1;
            end
        end
    end

    // Select digit and activate corresponding anode
    always @(*) begin

        case (digit_select)

            2'b00: begin
                digit = number % 10;
                an = 4'b1110;
            end

            2'b01: begin
                digit = (number / 10) % 10;
                an = 4'b1101;
            end

            2'b10: begin
                digit = (number / 100) % 10;
                an = 4'b1011;
            end

            2'b11: begin
                digit = (number / 1000) % 10;
                an = 4'b0111;
            end

            default: begin
                digit = 0;
                an = 4'b1111;
            end

        endcase
    end

    // Active-low seven-segment decoder
    always @(*) begin

        case (digit)

            0: seg = 8'b11000000;
            1: seg = 8'b11111001;
            2: seg = 8'b10100100;
            3: seg = 8'b10110000;
            4: seg = 8'b10011001;
            5: seg = 8'b10010010;
            6: seg = 8'b10000010;
            7: seg = 8'b11111000;
            8: seg = 8'b10000000;
            9: seg = 8'b10010000;

            default: seg = 8'b11111111;

        endcase
    end

endmodule