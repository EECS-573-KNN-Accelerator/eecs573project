// Comparing the prev Knn to the running_mean to find the valid/invalid bit and then all the points from the BDU
// Sends the prev_knn into the topK along with x,y,z and whether or not it is valid (less than running mean)

module comparator(
	input knn_entry_t prev_knn_point_in, //distance from the previous neighbor to the new query point

	input [`B-1:0] running_mean,

	// Output is a knn_entry_t
	output knn_entry_t prev_knn_point_out
);

    wire taken;
    assign taken = (prev_knn_point_in.distance <= running_mean);

	//assign prev_knn_point_out = prev_knn_point_in; 
    assign prev_knn_point_out.valid = prev_knn_point_in.valid && taken;
    assign prev_knn_point_out.distance = prev_knn_point_in.distance;
    assign prev_knn_point_out.x = prev_knn_point_in.x;
    assign prev_knn_point_out.y = prev_knn_point_in.y;
    assign prev_knn_point_out.z = prev_knn_point_in.z;
    assign prev_knn_point_out.point_id = prev_knn_point_in.point_id;
    
endmodule
