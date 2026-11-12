
`timescale 1ns / 1ps

module vending_machine_tb;

    reg clk = 0;
    reg rst = 1;
    reg coin1 = 0;
    reg coin2 = 0;
    reg select_item = 0;
    reg buy = 0;

    wire [15:0] balance;
    wire [15:0] display_amount;

    wire dispense_A;
    wire dispense_B;
    wire change_returned;
    wire insufficient;

    integer errors = 0;

    // Device under test
    vending_machine_fsm DUT (
        .clk(clk),
        .rst(rst),
        .coin1(coin1),
        .coin2(coin2),
        .select_item(select_item),
        .buy(buy),
        .balance(balance),
        .display_amount(display_amount),
        .dispense_A(dispense_A),
        .dispense_B(dispense_B),
        .change_returned(change_returned),
        .insufficient(insufficient)
    );

    // 100 MHz simulation clock
    always #5 clk = ~clk;

    // Insert coin 1
    task insert_coin1;
        begin
            @(negedge clk);
            coin1 = 1;
            @(negedge clk);
            coin1 = 0;
        end
    endtask

    // Insert coin 2
    task insert_coin2;
        begin
            @(negedge clk);
            coin2 = 1;
            @(negedge clk);
            coin2 = 0;
        end
    endtask

    // Reset controller
    task reset_dut;
        begin
            @(negedge clk);
            rst = 1;
            @(negedge clk);
            rst = 0;
            @(negedge clk);
        end
    endtask

    // Check balance
    task check_balance;
        input [15:0] expected;
        begin
            if (balance !== expected) begin
                $display("FAIL: Expected balance=%0d, Actual=%0d",
                         expected, balance);
                errors = errors + 1;
            end
            else begin
                $display("PASS: Balance=%0d", balance);
            end
        end
    endtask

    // Test sequence
    initial begin

        $display("--------------------------------");
        $display(" VENDING MACHINE TESTBENCH");
        $display("--------------------------------");

        // Initial reset
        repeat(2) @(negedge clk);
        rst = 0;

        // TEST 1: Exact payment for Item A
        $display("\nTEST 1: Exact payment for Item A");

        insert_coin1();
        insert_coin1();
        insert_coin1();

        check_balance(15);

        @(negedge clk);
        select_item = 0;
        buy = 1;

        @(posedge clk);
        #1;

        buy = 0;

        @(posedge clk);
        #1;

        if (dispense_A && balance == 0)
            $display("PASS: Item A dispensed");
        else begin
            $display("FAIL: Item A dispensing");
            errors = errors + 1;
        end

        reset_dut();

        // TEST 2: Overpayment for Item B
        $display("\nTEST 2: Overpayment for Item B");

        select_item = 1;

        insert_coin2();
        insert_coin2();
        insert_coin2();

        check_balance(30);

        @(negedge clk);
        buy = 1;

        @(posedge clk);
        #1;
        buy = 0;

        @(posedge clk);
        #1;

        if (dispense_B && change_returned &&
            display_amount == 5) begin
            $display("PASS: Item B dispensed");
            $display("PASS: Change returned = 5");
        end
        else begin
            $display("FAIL: Item B transaction");
            errors = errors + 1;
        end

        reset_dut();

        // TEST 3: Insufficient balance
        $display("\nTEST 3: Insufficient payment");

        select_item = 0;

        insert_coin1();

        @(negedge clk);
        buy = 1;

        @(posedge clk);
        #1;
        buy = 0;

        if (insufficient && !dispense_A && !dispense_B)
            $display("PASS: Insufficient balance detected");
        else begin
            $display("FAIL: Insufficient balance detection");
            errors = errors + 1;
        end

        check_balance(5);

        reset_dut();

        // TEST 4: Exact payment for Item B
        $display("\nTEST 4: Exact payment for Item B");

        select_item = 1;

        insert_coin1();
        insert_coin1();
        insert_coin1();
        insert_coin1();
        insert_coin1();

        check_balance(25);

        @(negedge clk);
        buy = 1;

        @(posedge clk);
        #1;
        buy = 0;

        @(posedge clk);
        #1;

        if (dispense_B && !change_returned &&
            display_amount == 0)
            $display("PASS: Exact Item B transaction");
        else begin
            $display("FAIL: Exact Item B transaction");
            errors = errors + 1;
        end

        // Final result
        $display("\n--------------------------------");

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TESTS FAILED: %0d errors", errors);

        $display("--------------------------------");

        $finish;
    end

endmodule