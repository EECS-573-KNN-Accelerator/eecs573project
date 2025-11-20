`include "global_defs.sv"

module topK (
    input logic clk,
    input logic reset,
    input logic bdu_done,
    input logic [`DIST_WIDTH-1:0] running_mean,
    input knn_entry_t point_in, // new point to consider for KNN, valid is bdu_terminate

    output logic [`DIST_WIDTH-1:0] threshold, // threshold for distance comparison, the largest value in KNN buffer
    output knn_entry_t knn_buffer_out [0:`K-1] // distances of the KNN points
);

// KNN buffer - size K ordered array to store the nearest points found so far
// Each entry contains: valid bit, distance, (optionally) point coordinates or memory address, distance ranking index

knn_entry_t knn_buffer [`K-1:0]; // KNN buffer entries
logic [`DIST_WIDTH-1:0] max_distance;
logic [$clog2(`K)-1:0] tail_index;
logic inserted;



//do the compare and insert logic
always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        // Initialize KNN buffer on reset
        for (int i = 0; i < `K; i++) begin
            knn_buffer[i].valid <= 1'b0;
            knn_buffer[i].distance <= {`DIST_WIDTH{1'b1}}; // Set to max distance
        end
    end
    else if (bdu_done) begin
        // Compare new point distance with KNN buffer entries
        inserted = 1'b0;
        for (int i = 0; i < `K; i++) begin
            if (!inserted && (!knn_buffer[i].valid || point_in.distance < knn_buffer[i].distance)) begin
                // Shift down entries to make space for new point
                for (int j = `K-1; j > i; j--) begin
                    knn_buffer[j] <= knn_buffer[j-1];
                end
                // Insert new point
                knn_buffer[i] <= point_in;
                inserted = 1'b1;
            end
        end
    end
end

// Update max distance and tail index
always_comb begin
    max_distance = {`DIST_WIDTH{1'b0}};
    tail_index = 0;
    for (int i = 0; i < `K; i++) begin
        if (knn_buffer[i].valid && knn_buffer[i].distance > max_distance) begin
            max_distance = knn_buffer[i].distance;
            tail_index = i;
        end
    end
end

// Output assignments
assign threshold = max_distance;

endmodule