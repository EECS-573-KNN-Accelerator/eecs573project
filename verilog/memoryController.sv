module memory_controller import sys_defs_pkg::*; #(
    // Addressing: base addresses for Reference Points, Query Points, and KNN IDs
    parameter ADDR R_BASE          = R_BASE,
    parameter ADDR V_BASE          = V_BASE,
    parameter ADDR Q_BASE          = Q_BASE,
    parameter ADDR O_BASE          = O_BASE,
    parameter int  VECTOR_BYTES    = (`MEM_BLOCKS_PER_VECTOR*8)
)(
    input clk,
    input rst,

    // Memory interface signals
    input  MEM_TAG     mem2proc_transaction_tag, // Memory tag for current transaction
    input  MEM_BLOCK   mem2proc_data,            // Data coming back from memory
    input  MEM_TAG     mem2proc_data_tag,        // Tag for which transaction data is for
    output MEM_COMMAND proc2mem_command, // Command sent to memory
    output ADDR        proc2mem_addr,    // Address sent to memory
    output MEM_BLOCK   proc2mem_data,     // Data sent to memory

    

    // Data signals to/from Q K V and O SRAMs
    input  O_VECTOR_T  drained_vector,
    output Q_VECTOR_T  loaded_vector,

    output logic       done
);


endmodule