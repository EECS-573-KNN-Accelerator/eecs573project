`include "global_defs.sv"

module TopK (
    input logic clk,
    input logic reset,
    input logic valid,
    input knn_entry_t point_in, // new point to consider for KNN


    output logic [`BIT_WIDTH-1:0] threshold, // threashold for distance comparison, the largest value in KNN buffer
);

// KNN buffer - size K linked list to store nearest K neighbors
// Each entry contains: valid bit, distance, (optionally) point coordinates or memory address, distance ranking index

knn_entry_t knn_buffer [`K-1:0];    
logic [3:0] knn_next [`K-1:0]; // linked list next pointers
logic [3:0] knn_head; // head pointer
logic [3:0] knn_tail; // tail pointer
logic [4:0] knn_count; // number of valid entries in KNN buffer

logic [3:0] new_point_pos; // position to insert new point
logic compare_bit [`K-1:0]; // comparison results

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        // Initialize KNN buffer and pointers
        knn_head <= '0;
        knn_tail <= '0;
        knn_count <= '0;
        for (int i = 0; i < `K; i++) begin
            knn_buffer[i].valid <= 1'b0;
            knn_next[i] <= '0;
        end
    end 
    else if (valid) begin
        
    end
end

always_comb begin
    for (int i = 0; i < `K; i++) begin
        compare_bit[i] = (point_in.distance < knn_buffer[i].distance);
    end
end

always_comb begin
    for (int i = 0; i < `K; i++) begin
        if (knn_buffer[i].valid && compare_bit[i] && ~compare_bit[knn_next[i]]) begin
            new_point_pos <= i;
            break;
        end
    end
end

endmodule