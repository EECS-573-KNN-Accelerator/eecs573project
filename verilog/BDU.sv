
`define B 32 // bit width for each dimension
`define F 18

module BDU (
    input logic clk,
    input logic rst,   
   
    input logic valid,  // signal to indicate valid inputs 
    input logic q_bit, // the query bit comes in as xyzxyzxyz... one bit of each dimension at a time of the point 
    input logic r_bit,  // the reference bit comes in as xyzxyzxyz... one bit of each dimension at a time of the point 
    input logic [1:0] code, // the input that indicates which dimension the query and ref bit belongs to, 01 - x, 10 - y, 11 - z
    input logic [$clog2(`B)-1:0] b, // which bit is this, MSB = 1, LSB = `B, used for 2(`B-b) calculation
    input logic [`B-1:0] threshold, // threshold for distance comparison (kth dist^2), the last KNN value

    output logic terminate, // signal indicating early termination of the reference coordinate (ref point not selected as kNN)
    output logic done,// signal indicating ref. coordinate dist calculation is complete and passes the threshold (ref point is selected as kNN)
    output logic [`B-1:0] partial_distance_output,  // computed distance (only when done == 1, when this value is valid for use)
    output logic [`B-1:0] ref_coor_x, // ref. coordinate at x dimension (only when done == 1, when this value is valid for use)
    output logic [`B-1:0] ref_coor_y, // ref. coordinate at y dimension (only when done == 1, when this value is valid for use)
    output logic [`B-1:0] ref_coor_z // ref. coordinate at z dimension (only when done == 1, when this value is valid for use)
);
    // Intermediate REGs 
    logic [`F-1:0] f_x, f_y, f_z; // Acumulators for each dimension 
    logic [`F-1:0] partial_dist2; // Partial Distance Squared

    // Coordinate Registers
    logic [`B-1:0] q_x, q_y, q_z;
    logic [`B-1:0] r_x, r_y, r_z;
    logic [$clog2(`B+1)+ 2:0] ctr; // there should be 3*`B cycles (for each bit for each dimension) before it is done

    // Control Signals 
    logic code1 = code[1];
    logic code0 = code[0];
    logic S1 = ~code1 & code0;  // x dimension
    logic S2 = code1 & ~code0;  // y dimension
    logic S3 = code1 & code0;   // z dimension
    logic S4 = code1 ^ code0;
    logic S5 = ~code1 & code0;
    logic S6 = code;
    logic [1:0] S7 = {q_bit, r_bit};
    logic [1:0] S8 = {q_bit, r_bit};


    // --------------------------------- Squared Distance Logic ---------------------------------

    logic [`F-1:0] mux7 = S7 == 2'b01 ? -1 : S7 == 2'b10 ? 1 : 0;
    logic [`F-1:0] mux6 = S6 == 2'b01 ? f_x : S6 == 2'b10 ? f_y : S6 == 2'b11 ? f_z : 0;

    logic [`F-1:0] accumulate = (mux6 << 1) + mux7;

    logic [`F-1:0] mux1 = S1 == 1'b1 ? accumulate : f_x;
    logic [`F-1:0] mux2 = S2 == 1'b1 ? accumulate : f_y;
    logic [`F-1:0] mux3 = S3 == 1'b1 ? accumulate : f_z;

    logic [`F-1:0] neg_f = ~mux6 + 1; // Two's complement negation

    logic [`B-1:0] mux8 = S8 == 2'b01 ? {{(`B - `F){1'b0}},neg_f} : S8 == 2'b10 ? {{(`B - `F){1'b0}},mux6} : 0;
    logic [`B-1:0] mux4 = S4 == 1'b1 ? 1'b1 : 1'b0;
    logic [`B-1:0] mux5 = S5 == 1'b1 ? (partial_dist2 << 2) : partial_dist2;


    // --------------------------------- Lower `Bound Logic ---------------------------------

    // Absolute Logic
    logic [`F-1:0] abs_f_x = f_x[`F-1] ? (~f_x + 1) : f_x;
    logic [`F-1:0] abs_f_y = f_y[`F-1] ? (~f_y + 1) : f_y;
    logic [`F-1:0] abs_f_z = f_z[`F-1] ? (~f_z + 1) : f_z;

    logic [`F-1:0] sumOfAbs = abs_f_x + abs_f_y + abs_f_z;
    logic [`F-1:0] shiftNeg = ~(sumOfAbs << 1) + 1;

    logic [`F-1:0] f_x_Iszero = f_x == 0 ? 'b1 : 'b0;
    logic [`F-1:0] f_y_Iszero = f_y == 0 ? 'b1 : 'b0;
    logic [`F-1:0] f_z_Iszero = f_z == 0 ? 'b1 : 'b0;

    logic [`B-1:0] sum_to_shift = shiftNeg + f_x_Iszero + f_y_Iszero + f_z_Iszero;
    logic [$clog2(`B)-1:0] shift_amt = 2 * (`B - b);
    logic [`B-1:0] curr_lower_bound = sum_to_shift << shift_amt;


    // --------------------------------- Register Updates ---------------------------------

    always_ff@(posedge clk) begin
        if(rst) begin
            f_x <= 0;
            f_y <= 0;
            f_z <= 0;
            partial_dist2 <= 0;

            q_x <= 0;
            q_y <= 0;
            q_z <= 0;
            r_x <= 0;
            r_y <= 0;
            r_z <= 0;
            ctr <= 0;

        end else begin
            f_x <= terminate || done ? 0 : valid ? mux1 : f_x;
            f_y <= terminate || done ? 0 : valid ? mux2 : f_x;
            f_z <= terminate || done ? 0 : valid ? mux3 : f_x;
            partial_dist2 <= terminate || done ? 0 : valid ? mux4 + mux5 + (mux8 << 2) : partial_dist2; 
            
            ctr <= terminate || done ? 0 : valid ? ctr + 1'b1 : ctr;
            q_x <= terminate || done ? 0 : valid && S1 ? {q_x[`B-2:0], q_bit} : q_x;
            q_y <= terminate || done ? 0 : valid && S2 ? {q_y[`B-2:0], q_bit} : q_y;
            q_z <= terminate || done ? 0 : valid && S3 ? {q_z[`B-2:0], q_bit} : q_z;
            r_x <= terminate || done ? 0 : valid && S1 ? {r_x[`B-2:0], r_bit} : r_x;
            r_y <= terminate || done ? 0 : valid && S2 ? {r_y[`B-2:0], r_bit} : r_y;
            r_z <= terminate || done ? 0 : valid && S3 ? {r_z[`B-2:0], r_bit} : r_z;
        end
    end

    // --------------------------------- Output Values ---------------------------------

    assign terminate = (threshold <= curr_lower_bound) ? 1'b1: 1'b0;
    assign done = (ctr == `B*3);
    assign partial_distance_output = partial_dist2;
    assign ref_coor_x = r_x;
    assign ref_coor_y = r_y;
    assign ref_coor_z = r_z;


endmodule
