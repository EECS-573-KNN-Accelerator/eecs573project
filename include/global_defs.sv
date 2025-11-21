`ifndef __GLOBAL_DEFS_SV__
`define __GLOBAL_DEFS_SV__

`define BIT_WIDTH 16 // bit width for each dimension
`define DIST_WIDTH 32
`define NUM_BDU 8
`define K 4 // Max number of nearest neighbors to find
`define MEM_ADDR_WIDTH 20 // Address width for point memory
//`STORE_POINTS 1 - if defined, store full point coordinates in KNN buffer, else store memory address
// This is useful, because if we use a parallel comparator to compare between previous KNN cache and
// new query, we won't need to refetch from memory
// However, we end up needing BIT_WIDTH * 3 * K more bits in the KNN buffer and the side buffer???


// What each KNN buffer entry will contain
typedef struct packed {
  logic valid;  // valid bit - if invalid, use side buffer
  logic [2*`BIT_WIDTH-1:0] distance; // distance from point to query, or partial distance for side_buffer
`ifdef STORE_POINTS
  logic [`BIT_WIDTH-1:0] x;  // X coordinate of the point
  logic [`BIT_WIDTH-1:0] y;  // Y coordinate of the point
  logic [`BIT_WIDTH-1:0] z;  // Z coordinate of the point
`endif
`ifndef STORE_POINTS
  logic [`MEM_ADDR_WIDTH-1:0] addr;  // Address of the point in memory
`endif
} knn_entry_t;



//////////////////////////////////
// ---- Memory Definitions ---- //
//////////////////////////////////

typedef logic [31:0] ADDR;

//Base Addresses
parameter ADDR K_BASE = 'h0000_1000;
parameter ADDR V_BASE = 'h0000_2000;
parameter ADDR Q_BASE = 'h0000_3000;
parameter ADDR O_BASE = 'h0000_4000;

`define MEM_LATENCY_IN_CYCLES (100.0/`CLOCK_PERIOD+0.49999)
// the 0.49999 is to force ceiling(100/period). The default behavior for
// float to integer conversion is rounding to nearest

// memory tags represent a unique id for outstanding mem transactions
// 0 is a sentinel value and is not a valid tag
`define NUM_MEM_TAGS 15
typedef logic [3:0] MEM_TAG;

`define MEM_SIZE_IN_BYTES (64*1024)

`define MEM_64BIT_LINES   (`MEM_SIZE_IN_BYTES/8)

`define MEM_BLOCKS_PER_VECTOR ((`MAX_EMBEDDING_DIM*`INTEGER_WIDTH/8)/`MEM_BLOCK_SIZE_BYTES)

// A memory or cache block
typedef union packed {
    logic [7:0][7:0]  byte_level;
    logic [3:0][15:0] half_level;
    logic [1:0][31:0] word_level;
    logic      [63:0] dbbl_level;
} MEM_BLOCK;

typedef enum logic [1:0] {
    BYTE   = 2'h0,
    HALF   = 2'h1,
    WORD   = 2'h2,
    DOUBLE = 2'h3
} MEM_SIZE;

// Memory bus commands
typedef enum logic [1:0] {
    MEM_NONE   = 2'h0,
    MEM_LOAD   = 2'h1,
    MEM_STORE  = 2'h2
} MEM_COMMAND;



// BDU input 
typedef union packed {
  logic valid; 
  logic q_bit; 
  logic r_bit; 
  logic [1:0] code; 
  logic [$clog2(`B+1)-1:0] b; // which bit this is 
  logic [`B-1:0] threshold
}BDU_Input; 

// BDU output 
typedef union packed {
  logic terminate; 
  logic done; 
  logic [`B-1:0] partial_distance_output; 
  logic [`B-1:0] ref_coor_x; 
  logic [`B-1:0] ref_coor_y; 
  logic [`B-1:0] ref_coor_z; 
}BDU_Output; 






`endif // __GLOBAL_DEFS_SV__