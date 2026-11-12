
module vending_machine_top #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input wire clk,
    input wire [3:0] btn,
    input wire [0:0] sw,

    output reg [2:0] led,
    output wire [7:0] seg,
    output wire [3:0] an
);

    // BTN0: Active-high reset
    wire rst = btn[0];

    // Debounced button pulses
    wire coin1_pulse;
    wire coin2_pulse;
    wire buy_pulse;

    // Vending machine signals
    wire [15:0] balance;
    wire [15:0] display_amount;

    wire dispense_A;
    wire dispense_B;
    wire change_returned;
    wire insufficient;

    // Button 1: Insert coin 1
    button_debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) DB1 (
        .clk(clk),
        .rst(rst),
        .button(btn[1]),
        .pulse(coin1_pulse)
    );

    // Button 2: Insert coin 2
    button_debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) DB2 (
        .clk(clk),
        .rst(rst),
        .button(btn[2]),
        .pulse(coin2_pulse)
    );

    // Button 3: Purchase selected item
    button_debounce #(
        .CLK_FREQ(CLK_FREQ),
        .DEBOUNCE_MS(DEBOUNCE_MS)
    ) DB3 (
        .clk(clk),
        .rst(rst),
        .button(btn[3]),
        .pulse(buy_pulse)
    );

    // Main vending machine FSM
    vending_machine_fsm FSM (
        .clk(clk),
        .rst(rst),

        .coin1(coin1_pulse),
        .coin2(coin2_pulse),

        .select_item(sw[0]),
        .buy(buy_pulse),

        .balance(balance),
        .display_amount(display_amount),

        .dispense_A(dispense_A),
        .dispense_B(dispense_B),
        .change_returned(change_returned),
        .insufficient(insufficient)
    );

    // Four-digit seven-segment display
    seven_segment_display #(
        .CLK_FREQ(CLK_FREQ)
    ) DISPLAY (
        .clk(clk),
        .rst(rst),
        .value(display_amount),
        .seg(seg),
        .an(an)
    );

    // Latched LED status indicators
    always @(posedge clk) begin

        if (rst) begin
            led <= 3'b000;
        end

        else begin

            if (dispense_A)
                led[0] <= 1'b1;

            if (dispense_B)
                led[1] <= 1'b1;

            if (change_returned)
                led[2] <= 1'b1;

        end
    end

endmodule