module parallelDistCompute #(
    parameter BIT_WIDTH = `BIT_WIDTH,
    parameter K = `K
)(
    input logic clk, 
    input logic reset, 
    input logic start, 
    // Query point coordinates
    input [BIT_WIDTH-1:0] qp_x,
    input [BIT_WIDTH-1:0] qp_y,
    input [BIT_WIDTH-1:0] qp_z,
    // Previous KNN points
    input knn_entry_t prev_knn_point_in [0:K-1],
    
    output logic valid_out,
    output knn_entry_t prev_knn_point_out
);

    logic [$clog2(K)-1:0] compute_idx;
    logic signed [BIT_WIDTH-1:0] delta_x, delta_y, delta_z;
    logic [2*BIT_WIDTH-1:0] distance_squared;

    always_ff @(posedge clk) begin
        if (reset) begin
            compute_idx <= 0;
            valid_out <= 1'b0;
        end else if (start) begin
            if (compute_idx < K) begin
                delta_x <= $signed(prev_knn_point_in[compute_idx].x) - $signed(qp_x);
                delta_y <= $signed(prev_knn_point_in[compute_idx].y) - $signed(qp_y);
                delta_z <= $signed(prev_knn_point_in[compute_idx].z) - $signed(qp_z);

                distance_squared <= delta_x * delta_x + delta_y * delta_y + delta_z * delta_z;

                prev_knn_point_out.x        <= prev_knn_point_in[compute_idx].x;
                prev_knn_point_out.y        <= prev_knn_point_in[compute_idx].y;
                prev_knn_point_out.z        <= prev_knn_point_in[compute_idx].z;
                prev_knn_point_out.addr     <= prev_knn_point_in[compute_idx].addr;
                prev_knn_point_out.distance <= distance_squared;
                prev_knn_point_out.valid    <= prev_knn_point_in[compute_idx].valid;

                valid_out <= 1'b1;
                compute_idx <= compute_idx + 1;
            end else begin
                valid_out <= 1'b0; // finished all points
            end
        end else begin
            valid_out <= 1'b0; // idle
        end
    end

endmodule
