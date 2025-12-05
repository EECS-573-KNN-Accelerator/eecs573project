module memory_controller #(
    // Addressing: base addresses for Reference Points, Query Points, and KNN IDs
    parameter ADDR R_BASE          = R_BASE,
    parameter ADDR Q_BASE          = Q_BASE,
    parameter ADDR O_BASE          = O_BASE
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

    // data signals
    input  logic       bdus_done,
    output BDU_Input   BDU_inputs [`NUM_BDU],
    output logic       topK_input_sel,
    output logic       topK_inputs_valid_sel,

    output logic       done
);

    always_comb begin
        proc2mem_command = NONE;
        proc2mem_addr = '0;
        proc2mem_data = '0;
        BDU_inputs = '0;

        
    end




endmodule