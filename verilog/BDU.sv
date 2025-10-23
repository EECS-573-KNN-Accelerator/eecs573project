
`define B 16 // bit width for each dimension

module BDU (
    input logic clk,
    input logic [2*B-1:0] threashold, // threashold for distance comparison, the last KNN valeu
    input logic [B-1:0] qx, // query point
    input logic [B-1:0] qy,
    input logic [B-1:0] qz,
    input logic [B-1:0] rx, // reference point
    input logic [B-1:0] ry,
    input logic [B-1:0] rz,

    output logic done, // signal indicating computation is done
    output logic match,// whether the distance is less than threashold
    output logic [2*B-1:0] distance // computed distance

);

endmodule
