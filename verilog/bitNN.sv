module bitNN (
    input logic clk,
    input logic reset,
    output knn_entry_t knn_buffer_out [0:`K-1] // distances of the KNN points

    //Memory interface signals copied from 470 template
    input  MEM_TAG     mem2proc_transaction_tag, // Memory tag for current transaction
    input  MEM_BLOCK   mem2proc_data,            // Data coming back from memory
    input  MEM_TAG     mem2proc_data_tag,        // Tag for which transaction data is for

    output MEM_COMMAND proc2mem_command, // Command sent to memory
    output ADDR        proc2mem_addr,    // Address sent to memory
    output MEM_BLOCK   proc2mem_data,     // Data sent to memory

    // Done flag for the testbench
    output logic       done
);

    memory_controller mem_ctrl_inst (
        .clk(clk),
        .rst(rst),

        .mem2proc_transaction_tag(mem2proc_transaction_tag),
        .mem2proc_data(mem2proc_data),
        .mem2proc_data_tag(mem2proc_data_tag),
        .proc2mem_command(proc2mem_command),
        .proc2mem_addr(proc2mem_addr),
        .proc2mem_data(proc2mem_data),
        
        .drained_vector(drained_vector),
        .loaded_vector(loaded_vector),

        .done(done)
    );

    BDU [`NUM_BDU-1:0] bdu_array (
        .clk(clk),
        .rst(rst),
        .valid(),
        .q_bit(),
        .r_bit(),
        .code(),
        .b(),
        .threshold(),
        .terminate(),
        .done(),
        .partial_distance_output(),
        .ref_coor_x(),
        .ref_coor_y(),
        .ref_coor_z()
    );

    topK topk_inst (
        .clk(clk),
        .reset(reset),
        .bdu_done(), // connect to BDU done signal 
        .running_mean(), // connect to running mean signal
        .point_in(), // connect to BDU output point
        .threshold(), // connect to threshold output
        .knn_buffer_out()
    )


endmodule