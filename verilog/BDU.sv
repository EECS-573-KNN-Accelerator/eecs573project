
`define B 32 // bit width for each dimension

module BDU (
    input logic clk,
    input logic rst,
    
   
    input logic q_bit, // the data comes in as xyzxyzxyz... one bit of each dimension at a time of the point 
    input logic r_bit, 
    input logic [1:0] code,
    input logic [6:0] which_bit, // 2(B-b)
    input logic [2*B-1:0] threshold, // threshold for distance comparison (kth dist^2), the last KNN value

    output logic terminate, // signal indicating computation is done
    output logic done,// whether the distance is less than threshold
    output logic [B-1:0] partial_distance  // computed distance
);
    // Intermediate REGs 
    logic [B/2-1:0] f_x, f_y, f_z; // Acumulators for each dimension 
    logic [B-1:0] partial_dist2; // Partial Distance Squared

    // Control Signals 
    logic code1 = code[1];
    logic code0 = code[0];
    logic S1 = ~code1 & code0;
    logic S2 = code1 & ~code0;
    logic S3 = code1 & code0;
    logic S4 = code1 ^ code0;
    logic S5 = ~code1 & code0;
    logic S6 = code;
    logic [1:0] S7 = {q_bit, r_bit};
    logic [1:0] S8 = {q_bit, r_bit};


    // Squared Distance Logic_______________________________________________

    logic [B/2-1:0] mux7 = S7 == 2'b01 ? -1 : S7 == 2'b10 ? 1 : 0;

    logic [B/2-1:0] mux6 = S6 == 2'b01 ? f_x : S6 == 2'b10 ? f_y : S6 == 2'b11 ? f_z : 0;

    logic [B/2-1:0] accumulate = (mux6 << 1) + mux7;

    logic [B/2-1:0] mux1 = S1 == 1'b1 ? accumulate : f_x;
    logic [B/2-1:0] mux2 = S2 == 1'b1 ? accumulate : f_y;
    logic [B/2-1:0] mux3 = S3 == 1'b1 ? accumulate : f_z;

    always_ff@(posedge clk) begin
        if(rst) begin
            f_x <= 0;
            f_y <= 0;
            f_z <= 0;
            partial_dist2 <= 0;
        end else begin
            f_x <= mux1;
            f_Y <= mux2;
            f_Z <= mux3;
        end
    end
    
    logic [B/2-1:0] neg_f = ~mux6 + 1;

    logic [B/2-1:0] mux8 = S8 == 2'b01 ? neg_f : S8 == 2'b10 ? mux6 : 0;
    logic [B/2-1:0] mux4 = S4 == 1'b1 ? 1'b1 : 1'b0; 
    

endmodule
