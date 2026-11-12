
module button_debounce #(
    parameter integer CLK_FREQ = 100_000_000,
    parameter integer DEBOUNCE_MS = 20
)(
    input wire clk,
    input wire rst,
    input wire button,
    output reg pulse
);

    // Number of clock cycles required for stable input
    localparam integer COUNT_MAX =
        (CLK_FREQ / 1000) * DEBOUNCE_MS;

    // Synchronizer registers
    reg sync1;
    reg sync2;

    // Debounce registers
    reg stable_state;
    reg [31:0] count;

    always @(posedge clk) begin

        if (rst) begin
            sync1 <= 0;
            sync2 <= 0;
            stable_state <= 0;
            count <= 0;
            pulse <= 0;
        end

        else begin

            // Synchronize asynchronous button input
            sync1 <= button;
            sync2 <= sync1;

            // Default pulse output
            pulse <= 0;

            // Check whether input matches stable state
            if (sync2 == stable_state) begin
                count <= 0;
            end

            // Input has remained different long enough
            else if (count >= COUNT_MAX - 1) begin

                stable_state <= sync2;
                count <= 0;

                // Generate pulse only on button press
                if (sync2)
                    pulse <= 1;

            end

            else begin
                count <= count + 1;
            end

        end
    end

endmodule