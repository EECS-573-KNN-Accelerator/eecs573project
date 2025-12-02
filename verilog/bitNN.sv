module bitNN (
    input logic clk,
    input logic reset,

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

    logic [`DIST_WIDTH-1:0] running_mean;
    knn_entry_t knn_buffer_out [`K-1:0];
    logic [`DIST_WIDTH-1:0] threshold;

    knn_entry_t BDU_output_point;
    logic bdus_done;
    knn_entry_t topK_input_point;
    logic inputs_valid; // NOTE: Might end up with off by N cycles depending on how pipelining works w/ prev KNN -> topK

    knn_entry_t comparator_input_point;
    knn_entry_t comparator_output_point;

    assign topK_input_point = ? comparator_output_point : BDU_output_point; //TODO need control logic to decide between comparator output (prev KNN) and BDU output
    assign inputs_valid = ? 1'b1 : bdus_done; // TODO need control logic to decide if prev_knn_cache is being sent to topK

    memory_controller mem_ctrl_inst (
        .clk(clk),
        .rst(reset),

        .mem2proc_transaction_tag(mem2proc_transaction_tag),
        .mem2proc_data(mem2proc_data),
        .mem2proc_data_tag(mem2proc_data_tag),
        .proc2mem_command(proc2mem_command),
        .proc2mem_addr(proc2mem_addr),
        .proc2mem_data(proc2mem_data),

        // bdu inputs (route to BDU array)

        // query point finished (route to prev_knn_cache, running mean)

        // query point xyz bit parallel (route to parallelDistCompute)
        // new query point signal 1 cycle high (route to prev_knn_cache)

        // logic to select between prev_knn_cache output and BDU output going into topK input

        .done(done)
    );

    BDUArray bdu_array_inst (
        .clk(clk),
        .rst(reset),
        .BDU_inputs(), // connect to BDU inputs
        .threshold_in(threshold), // connect to threshold from topK
        .shift(BDU_output_point), // connect to point_in of topK
        .alldone(bdus_done)
    );

    topK topk_inst (
        .clk(clk),
        .reset(reset),
        .inputs_valid(inputs_valid), // connect to BDU done signal 
        .running_mean(running_mean), // connect to running mean signal
        .point_in(topK_input_point), // connect to BDU output point
        .threshold(threshold), // connect to threshold output
        .knn_buffer_out(knn_buffer_out)
    )
    
    prev_knn_cache prev_knn_cache_inst (
        .clk(clk),
        .rst(reset),
        .top_k_done(), // connect to entire KNN done signal
        .top_k_entry(knn_buffer_out), // connect to topK knn buffer output
        .new_query(), // connect to control logic new query signal
        .entry_to_compute(prev_knn_to_compute) // connect to parallelDistCompare input
    );

    parallelDistCompute parallel_dist_compute_inst (
        .qp_x(), // connect to query point x
        .qp_y(), // connect to query point y
        .qp_z(), // connect to query point z
        .prev_knn_point_in(prev_knn_to_compute), // connect to prev_knn_cache output
        .prev_knn_point_out(comparator_input_point) // connect to comparator input
    );

    comparator comparator_inst (
        .prev_knn_point_in(comparator_input_point), // connect to prev_knn_cache output
        .running_mean(running_mean), // connect to running mean signal
        .prev_knn_point_out(comparator_output_point) // connect to topk input
    )

    running_mean running_mean_generator (
        .clk(clk),
        .rst(reset),
        .top_k_done(), // connect to entire KNN done signal
        .kth_distance(knn_buffer_out[`K-1]), // connect to topK kth distance output
        .running_mean_out(running_mean) // connect to topK running mean input
    );


endmodule