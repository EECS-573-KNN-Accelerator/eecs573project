
`define B 32 // bit width for each dimension
`define F 18

// Comparing the prev Knn to the running_mean to find the valid/invalid bit and then all the points from the BDU
// Sends the prev_knn into the topK along with x,y,z and whether or not it is valid (less than running mean)

module comparator(
	input knn_entry_t prev_knn_point_in, //distance from the previous neighbor to the new query point
	input [`B-1:0] running_mean,
    input running_mean_valid,

	// Output is a knn_entry_t
	output knn_entry_t prev_knn_point_out,
	output not_taken, //equivalent to bdu_terminate - tells the topK whether the entry is greater than the running mean
	output vaild_comp
);

	assign not_taken = prev_knn_point_in.distance < running_mean;
	assign prev_knn_point_out = prev_knn_point_in; 
	assign vaild_comp = prev_knn_point_in.valid && running_mean_valid; 

endmodule
