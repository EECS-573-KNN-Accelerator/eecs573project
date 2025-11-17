`include "global_defs.sv"

module TopK (
    input logic clk,
    input logic reset,
    input logic valid, // bdu_done
    input logic [2*`BIT_WIDTH-1:0] running_mean,
    input knn_entry_t point_in, // new point to consider for KNN, valid is bdu_terminate

    output logic [2*`BIT_WIDTH-1:0] threshold, // threshold for distance comparison, the largest value in KNN buffer
    output knn_entry_t knn_buffer_out [0:`K-1] // distances of the KNN points
);

// KNN buffer - size K linked list to store nearest K neighbors
// Each entry contains: valid bit, distance, (optionally) point coordinates or memory address, distance ranking index

knn_entry_t knn_buffer [`K-1:0]; // KNN buffer entries
logic [$clog2(`K)-1:0] knn_next [`K-1:0]; // linked list next pointers
logic [$clog2(`K)-1:0] knn_head; // head pointer - greatest in KNN list
logic [$clog2(`K)-1:0] knn_tail; // tail pointer - smallest in KNN list

logic [$clog2(`K)-1:0] new_point_pos; // position to insert new point
logic compare_bit [`K-1:0]; // comparison results - need to be 1 indexed

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        // Initialize KNN buffer and pointers
        knn_head <= `K-1;
        knn_tail <= '0;
        for (int i = 0; i < `K; i++) begin
            knn_buffer[i].valid <= 1'b0;
            knn_buffer[i].distance <= '1; // max distance
        end
    end
    else if (valid) begin
        knn_buffer[new_point_pos] <= point_in;
    end
end

// Compare logic
always_comb begin
    for (int i = 0; i < `K; i++) begin
        compare_bit[i] = (point_in.distance < knn_buffer[i].distance);
    end
end

// Insertion logic
always_comb begin
    if (compare_bit[0] == 1'b1) begin
        new_point_pos = knn_head;
        knn_head = knn_next[knn_head];
        knn_tail = new_point_pos;
    end
    else begin
        for (int i = 1; i < `K; i++) begin
            if (compare_bit[i] && ~compare_bit[knn_next[i-1]]) begin
                new_point_pos = knn_head;
                knn_head = knn_next[knn_head];
                knn_next[new_point_pos] = knn_next[i]
                knn_next[i-1] = new_point_pos;
                break; // idk if this is necessary
            end
        end
    end
end

// Output logic
always_comb begin
    threshold = (knn_buffer[knn_head].valid) ? knn_buffer[knn_head].distance : running_mean;
    // Output KNN buffer entries in order
    knn_buffer_out[`K-1] = knn_buffer[knn_head];
    for (int i = `K-2; i < `K; i++) begin
        knn_buffer_out[i] = knn_buffer[knn_next[i+1]];
    end

end

endmodule