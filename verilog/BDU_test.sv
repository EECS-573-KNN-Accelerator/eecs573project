`timescale 1ns/1ps
`define B 32
`define F 18

module BDU_tb;
    // DUT inputs
    logic clk;
    logic rst;
    logic valid;
    logic q_bit;
    logic r_bit;
    logic [1:0] code;
    logic [$clog2(`B)-1:0] b;
    logic [`B-1:0] threshold;

    // DUT outputs
    logic terminate;
    logic done;
    logic [`B-1:0] partial_distance_output;
    logic [`B-1:0] ref_coor_x;
    logic [`B-1:0] ref_coor_y;
    logic [`B-1:0] ref_coor_z;

    logic [`B-1:0] debug;

    // Instantiate DUT
    BDU dut (
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .q_bit(q_bit),
        .r_bit(r_bit),
        .code(code),
        .b(b),
        .threshold(threshold),
        .terminate(terminate),
        .done(done),
        .partial_distance_output(partial_distance_output),
        .ref_coor_x(ref_coor_x),
        .ref_coor_y(ref_coor_y),
        .ref_coor_z(ref_coor_z),
        .debug(debug)
    );

    // ----------------------------------------
    // Clock generation
    // ----------------------------------------
    initial clk = 0;
    always #5 clk = ~clk; // 100MHz clock

    // ----------------------------------------
    // Stimulus
    // ----------------------------------------
    bit [`B-1:0] q;
    bit [`B-1:0] r;

    initial begin
        $display("---- Starting BDU Sanity Test ----");
        rst = 1;
        valid = 0;
        q_bit = 0;
        r_bit = 0;
        code = 2'b00;
        b = 0;
        threshold = 32'h0000_FFFF;
        @(negedge clk);
        //@(posedge clk);
        $display("Cycle reset | code=%b q_bit=%b r_bit=%b | terminate=%b done=%b partial_dist=%0d debug=%b",
                    code, q_bit, r_bit, terminate, done, partial_distance_output, debug);

        repeat(3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ---------------------------------- Sanity Test ---------------------------------------------------
        valid = 1;

        // q and r
        q = 32'h0000_FFFF;
        r = 32'h0000_FFF0;

        for (int i = 0; i < 96; i++) begin
            case (i % 3)
                0: code = 2'b01; // x
                1: code = 2'b10; // y
                2: code = 2'b11; // z
            endcase

            q_bit = q[`B - 1 - (i/3)];
            r_bit = r[`B - 1 - (i/3)];
            b = i/3 + 1;

            @(posedge clk);
            $display("Cycle %0d | code=%b q_bit=%b r_bit=%b | terminate=%b done=%b partial_dist=%0d debug=%d",
                     i, code, q_bit, r_bit, terminate, done, partial_distance_output, debug);
        end

        // End of stimulus
        valid = 0;
        repeat(10) @(posedge clk);

        $display("---- Simulation Complete ----");
        $finish;
    end
endmodule
