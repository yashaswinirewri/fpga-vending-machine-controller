
module vending_machine_fsm #(
    parameter COIN1  = 5,
    parameter COIN2  = 10,
    parameter PRICE_A = 15,
    parameter PRICE_B = 25
)(
    input wire clk,
    input wire rst,

    input wire coin1,
    input wire coin2,
    input wire select_item,  // 0 = A, 1 = B
    input wire buy,

    output reg [15:0] balance,
    output reg [15:0] display_amount,

    output reg dispense_A,
    output reg dispense_B,
    output reg change_returned,
    output reg insufficient
);

    // FSM states
    localparam IDLE     = 2'b00;
    localparam ACCEPT   = 2'b01;
    localparam DISPENSE = 2'b10;

    reg [1:0] state;

    reg [15:0] pending_change;

    wire [15:0] selected_price;

    assign selected_price =
        select_item ? PRICE_B : PRICE_A;

    always @(posedge clk) begin

        if (rst) begin
            state           <= ACCEPT;
            balance         <= 0;
            display_amount  <= 0;
            pending_change  <= 0;

            dispense_A      <= 0;
            dispense_B      <= 0;
            change_returned <= 0;
            insufficient    <= 0;
        end

        else begin

            // Default: one-clock-cycle output pulses
            dispense_A      <= 0;
            dispense_B      <= 0;
            change_returned <= 0;
            insufficient    <= 0;

            case (state)

                // Initial state
                IDLE: begin
                    state <= ACCEPT;
                end

                // Coin acceptance and purchase validation
                ACCEPT: begin

                    if (coin1) begin
                        balance <= balance + COIN1;
                        display_amount <= balance + COIN1;
                    end

                    else if (coin2) begin
                        balance <= balance + COIN2;
                        display_amount <= balance + COIN2;
                    end

                    else if (buy) begin

                        if (balance >= selected_price) begin

                            pending_change <=
                                balance - selected_price;

                            display_amount <=
                                balance - selected_price;

                            balance <= 0;

                            state <= DISPENSE;

                        end

                        else begin
                            insufficient <= 1;
                        end

                    end
                end

                // Dispensing state
                DISPENSE: begin

                    if (select_item == 1'b0)
                        dispense_A <= 1;
                    else
                        dispense_B <= 1;

                    if (pending_change > 0)
                        change_returned <= 1;

                    pending_change <= 0;

                    state <= ACCEPT;

                end

                default: begin
                    state <= IDLE;
                end

            endcase

        end
    end

endmodule