`include "global_defs.sv"


module TopK (
    input logic clk,
    input logic reset,
    input logic [`K-1:0] [`BIT_WIDTH-1:0] initial_knn, // initial KNN distances to start with - either previous KNN or running mean 
    input logic [`NUM_BDU-1:0] bdu_done, // Used to load into the side buffer
    input logic [`NUM_BDU-1:0] bdu_match, // Used to load into the KNN buffer
    input logic [`NUM_BDU-1:0] [2*`BIT_WIDTH-1:0] bdu_distances, // distance outputs from each BDU
`ifdef STORE_POINTS
    input logic [`NUM_BDU-1:0] [`BIT_WIDTH-1:0] bdu_x, // Note: we'll receive point coordinates serially, so we'd need three buffers to store these
    input logic [`NUM_BDU-1:0] [`BIT_WIDTH-1:0] bdu_y,
    input logic [`NUM_BDU-1:0] [`BIT_WIDTH-1:0] bdu_z,
`endif

`ifndef STORE_POINTS
    input logic [`NUM_BDU-1:0] [`MEM_ADDR_WIDTH-1:0] bdu_addr, // Address outputs from each BDU
`endif

    output logic [`BIT_WIDTH-1:0] threshold, // threashold for distance comparison, the largest value in KNN buffer
    output logic done, // signal indicating computation is done
    output logic [(`K*2*`BIT_WIDTH-1):0] knn_distances // distances of the KNN points
);

// KNN buffer - size K linked list to store nearest K neighbors
// Each entry contains: valid bit, distance, (optionally) point coordinates or memory address




// Side buffer - size K ordered shift register

// logic to assign BDU outputs into knn or side buffer
// If new value is assigned, compare with each value in the buffer sequentially from highest to lowest to assign order
// Make sure the output threshold will always read from the highest index in the knn buffer
// terminate early if KNN buffer is full with values under the threshold

endmodule
