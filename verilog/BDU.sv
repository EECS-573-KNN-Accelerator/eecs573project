`include "global_defs.sv"

module BDU (
    input logic clk,
    input logic [2*`BIT_WIDTH-1:0] threshold, // threashold for distance comparison, the last KNN value
    input logic [`BIT_WIDTH-1:0] qx, // query point
    input logic [`BIT_WIDTH-1:0] qy,
    input logic [`BIT_WIDTH-1:0] qz,
    input logic [`BIT_WIDTH-1:0] rx, // reference point
    input logic [`BIT_WIDTH-1:0] ry,
    input logic [`BIT_WIDTH-1:0] rz,

    output logic done, // signal indicating computation is done
    output logic match,// whether the distance is less than threshold
    output logic [2*`BIT_WIDTH-1:0] distance // computed distance (complete or partial if early termination)

);

endmodule
