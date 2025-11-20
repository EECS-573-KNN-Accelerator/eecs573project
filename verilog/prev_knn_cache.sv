`define K 10

module prev_knn_cache (

    input clk,
    input rst,

    input top_k_done,
    input knn_entry_t top_k_entry [`K-1:0],

    input new_query, // from control logic

    output knn_entry_t entry_to_compute,   // send to parallelDistCompare
    output entry_valid,

    output logic prev_knn_cache_valid,

);

    knn_entry_t knn_mem [`K-1:0];
    logic [$clog2(`K):0] read_ptr;
    logic reading;

    assign prev_knn_cache_valid = !top_k_done;

    always_ff@(posedge clk) begin
        if(rst) begin
            knn_mem <= '0;
            read_ptr <= 0;
        end else begin
            knn_mem <= top_k_done ? top_k_entry : knn_mem;
            reading <= new_query ? 1'b1 : read_ptr == `K-1 ? 0 : reading;
            read_ptr <= new_query ? 1'b1 : reading ? (read_ptr == `K-1 ? 0 : read_ptr + 1'b1) : read_ptr;

            if(reading) begin
                read_ptr <= new_query ? 1'b1 : read_ptr == `K-1 ? 0 : read_ptr + 1'b1;
                reading <= read_ptr == `K-1 ? 0 : reading;
            end
        end
    end

    assign entry_to_compute = knn_mem[read_ptr];


endmodule