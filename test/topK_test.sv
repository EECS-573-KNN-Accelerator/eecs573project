`include "global_defs.sv"
`timescale 1ns / 1ps

module topK_tb;

    //----------------------------------------------------------------
    // Local Parameters
    //----------------------------------------------------------------
    // Calculated parameters
    localparam int CLK_PERIOD = 10; // 10ns clock period

    //----------------------------------------------------------------
    // Testbench Signals
    //----------------------------------------------------------------
    
    // DUT Inputs
    logic                  clk;
    logic                  reset;
    logic                  bdu_done;
    knn_entry_t            bdu_entry;
    logic [`DIST_WIDTH-1:0] running_mean;

    // DUT Outputs
    logic [`DIST_WIDTH-1:0]     threshold;
    knn_entry_t   knn_distances [`K-1:0];

    //----------------------------------------------------------------
    // Instantiate the DUT (Device Under Test)
    //----------------------------------------------------------------
    topK dut (
        .clk(clk),
        .reset(reset),
        .bdu_done(bdu_done),
        .point_in(bdu_entry),
        .running_mean(running_mean),

        .threshold(threshold),
        .knn_buffer_out(knn_distances)
    );

    //----------------------------------------------------------------
    // Task to Print Results
    //----------------------------------------------------------------
    task print_state;
        input int scenario_idx;
        begin
            $display("--- Scenario %0d Results ---", scenario_idx);
            $display("Threshold: %0d", threshold);
            for (int i = 0; i < `K; i++) begin
                $display("Index %0d: Dist = %0d, Valid = %b", 
                         i, knn_distances[i].distance, knn_distances[i].valid);
            end
            $display("----------------------------\n");
        end
    endtask

    //----------------------------------------------------------------
    // Clock Generation
    //----------------------------------------------------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end


    //----------------------------------------------------------------
    // Test Stimulus
    //----------------------------------------------------------------
    initial begin
        // Initialize all inputs to a known idle state and reset
        reset         = 1'b1;
        bdu_done      = '0;
        bdu_entry     = '0;
        running_mean  = 'd50;

        // Wait for reset to finish
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        print_state(0);

        reset = 1'b0;

        // --- Test Scenario 1
        // should be dist: 60 inf inf inf
        //          valid:  0   0   0   0
        #2;
        bdu_entry.distance = 'd60;
        bdu_entry.valid = 1'b0;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(1);

        // --- Test Scenario 2
        // should be dist: 20 60 inf inf
        //          valid:  1  0   0   0
        #2;
        bdu_entry.distance = 'd20;
        bdu_entry.valid = 1'b1;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(2);

        // --- Test Scenario 3
        // should be dist: 10 20 60 inf
        //          valid:  1  1  0   0
        bdu_entry.distance = 'd10;
        bdu_entry.valid = 1'b1;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(3);

        // --- Test Scenario 4
        // should be dist: 10 20 60 70
        //          valid:  1  1  0  0
        bdu_entry.distance = 'd70;
        bdu_entry.valid = 1'b0;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(4);

        // --- Test Scenario 5
        // should be dist: 5 10 20 60
        //          valid: 1  1  1  0
        bdu_entry.distance = 'd5;
        bdu_entry.valid = 1'b1;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(5);

        // --- Test Scenario 6
        // should be dist: 5 10 20 60
        //          valid: 1  1  1  0
        bdu_entry.distance = 'd80;
        bdu_entry.valid = 1'b0;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(6);

        // --- Test Scenario 7
        // should be dist: 5 10 20 51
        //          valid: 1  1  1  0
        bdu_entry.distance = 'd51;
        bdu_entry.valid = 1'b0;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(7);

        // --- Test Scenario 8
        // should be dist: 5 10 20 30
        //          valid: 1  1  1  1
        bdu_entry.distance = 'd30;
        bdu_entry.valid = 1'b1;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(8);

        // --- Test Scenario 9
        // should be dist: 5 10 20 30
        //          valid: 1  1  1  1
        bdu_entry.distance = 'd40;
        bdu_entry.valid = 1'b0;
        bdu_done = 1'b1;
        @(posedge clk);
        #1; print_state(9);

        $display("[%0t] All test scenarios complete. Finishing simulation.", $time);
        $finish;
    end

endmodule