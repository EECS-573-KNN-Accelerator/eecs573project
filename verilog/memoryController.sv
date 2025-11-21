module memory_controller import sys_defs_pkg::*; #(
    // Addressing: base addresses for K, V, Q inputs and O outputs
    parameter ADDR K_BASE          = K_BASE,
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

    // Handshake signals with Q K V and O SRAMs
    input  logic Q_sram_rdy,
    input  logic K_sram_rdy,
    input  logic V_sram_rdy,
    input  logic O_sram_vld,
    output logic ctrl_O_rdy,
    output logic ctrl_Q_vld,
    output logic ctrl_K_vld,
    output logic ctrl_V_vld,

    // Data signals to/from Q K V and O SRAMs
    input  O_VECTOR_T  drained_vector,
    output Q_VECTOR_T  loaded_vector,

    output logic       done
);


endmodule