
`define B 32 // bit width for each dimension
`define F 18

module BDU (
    input logic clk,
    input logic rst,   
   
    input logic valid,  // signal to indicate valid inputs 
    input logic q_bit, // the query bit comes in as xyzxyzxyz... one bit of each dimension at a time of the point 
    input logic r_bit,  // the reference bit comes in as xyzxyzxyz... one bit of each dimension at a time of the point 
    input logic [1:0] code, // the input that indicates which dimension the query and ref bit belongs to, 01 - x, 10 - y, 11 - z
    input logic [$clog2(`B+1)-1:0] b, // which bit is this, MSB = 1, LSB = `B, used for 2(`B-b) calculation
    input logic [`B-1:0] threshold, // threshold for distance comparison (kth dist^2), the last KNN value

    output knn_entry_t result;

    output logic terminate, // signal indicating early termination of the reference coordinate (ref point not selected as kNN)
    output logic done,// signal indicating ref. coordinate dist calculation is complete and passes the threshold (ref point is selected as kNN)
    output logic [`B-1:0] partial_distance_output,  // computed distance (only when done == 1, when this value is valid for use)
    output logic [`B-1:0] ref_coor_x, // ref. coordinate at x dimension (only when done == 1, when this value is valid for use)
    output logic [`B-1:0] ref_coor_y, // ref. coordinate at y dimension (only when done == 1, when this value is valid for use)
    output logic [`B-1:0] ref_coor_z, // ref. coordinate at z dimension (only when done == 1, when this value is valid for use)
    
    output logic [`B-1:0] debug
);
    // Intermediate REGs 
    logic [`F-1:0] f_x, f_y, f_z; // Acumulators for each dimension 
    logic [`B-1:0] partial_dist2; // Partial Distance Squared

    // Coordinate Registers
    logic [`B-1:0] q_x, q_y, q_z;
    logic [`B-1:0] r_x, r_y, r_z;
    logic [$clog2(`B+1)+ 2:0] ctr; // there should be 3*`B cycles (for each bit for each dimension) before it is done

    // Control Signals 
    logic S1, S2, S3, S4, S5;
    logic [1:0] S6, S7, S8;

    assign S1 = ~code[1] & code[0];  // x dimension
    assign S2 = code[1] & ~code[0];  // y dimension
    assign S3 = code[1] & code[0];   // z dimension
    assign S4 = q_bit ^ r_bit;
    assign S5 = ~code[1] & code[0];
    assign S6 = code;
    assign S7 = {q_bit, r_bit};
    assign S8 = {q_bit, r_bit};


    // --------------------------------- Squared Distance Logic ---------------------------------

    logic [`F-1:0] mux6, mux7, accumulate, neg_f;
    assign mux7 = S7 == 2'b01 ? -1 : S7 == 2'b10 ? 1 : 0;
    assign mux6 = S6 == 2'b01 ? f_x : S6 == 2'b10 ? f_y : S6 == 2'b11 ? f_z : 0;
    assign accumulate = (mux6 << 1) + mux7;
    assign neg_f = ~mux6 + 1; // Two's complement negation

    logic [`F-1:0] mux1, mux2, mux3;
    assign mux1 = S1 == 1'b1 ? accumulate : f_x;
    assign mux2 = S2 == 1'b1 ? accumulate : f_y;
    assign mux3 = S3 == 1'b1 ? accumulate : f_z;

    logic [`B-1:0] mux4, mux5, mux8;
    assign mux8 = S8 == 2'b01 ? 0 - mux6 : S8 == 2'b10 ? mux6 : 0;
    assign mux4 = S4 == 1'b1 ? 1'b1 : 1'b0;
    assign mux5 = S5 == 1'b1 ? (partial_dist2 << 2) : partial_dist2;


    // --------------------------------- Lower Bound Logic ---------------------------------

    // Absolute Logic
    logic [`F-1:0] abs_f_x, abs_f_y, abs_f_z;
    assign abs_f_x = f_x[`F-1] ? (~f_x + 1) : f_x;
    assign abs_f_y = f_y[`F-1] ? (~f_y + 1) : f_y;
    assign abs_f_z = f_z[`F-1] ? (~f_z + 1) : f_z;

    logic [`F-1:0] sumOfAbs, shiftNeg;
    assign sumOfAbs = abs_f_x + abs_f_y + abs_f_z;
    assign shiftNeg = ~(sumOfAbs << 1) + 1;

    logic [`F-1:0] f_x_Iszero, f_y_Iszero, f_z_Iszero;
    assign f_x_Iszero = f_x == 0 ? 0 : 1;
    assign f_y_Iszero = f_y == 0 ? 0 : 1;
    assign f_z_Iszero = f_z == 0 ? 0 : 1;

    logic [`B-1:0] sum_to_shift, shifted_sum, curr_lower_bound;
    logic [$clog2(`B+1)-1:0] shift_amt;
    assign sum_to_shift = partial_dist2 + f_x_Iszero + f_y_Iszero + f_z_Iszero - (sumOfAbs << 1);
    assign shift_amt = 2 * (`B - b);
    assign shifted_sum = sum_to_shift << shift_amt;
    assign curr_lower_bound = partial_dist2 > shifted_sum ? partial_dist2 : shifted_sum;


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

    //knn_entry_t result;
    assign result.valid = (ctr == `B*3);
    assign result.distance = partial_dist2;
    `ifdef STORE_POINTS
    assign result.x = r_x;
    assign result.y = r_y;
    assign result.z = r_z;

    assign debug = curr_lower_bound;

endmodule
