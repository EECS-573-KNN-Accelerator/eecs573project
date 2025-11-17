`ifndef __GLOBAL_DEFS_SV__
`define __GLOBAL_DEFS_SV__

`define BIT_WIDTH 16 // bit width for each dimension
`define NUM_BDU 8
`define K 16 // Max number of nearest neighbors to find
`define MEM_ADDR_WIDTH 20 // Address width for point memory
//`STORE_POINTS 1 - if defined, store full point coordinates in KNN buffer, else store memory address
// This is useful, because if we use a parallel comparator to compare between previous KNN cache and
// new query, we won't need to refetch from memory
// However, we end up needing BIT_WIDTH * 3 * K more bits in the KNN buffer and the side buffer???


// What each KNN buffer entry will contain
typedef struct packed {
  logic valid;  // valid bit - if invalid, use side buffer
  logic [2*BIT_WIDTH-1:0] distance; // distance from point to query, or partial distance for side_buffer
`ifdef STORE_POINTS
  logic [BIT_WIDTH-1:0] x;  // X coordinate of the point
  logic [BIT_WIDTH-1:0] y;  // Y coordinate of the point
  logic [BIT_WIDTH-1:0] z;  // Z coordinate of the point
`endif
`ifndef STORE_POINTS
  logic [`MEM_ADDR_WIDTH-1:0] addr;  // Address of the point in memory
`endif
} knn_entry_t;

`endif // __GLOBAL_DEFS_SV__