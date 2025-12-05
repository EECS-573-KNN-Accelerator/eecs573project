module parallelDistCompute (
    input [`BIT_WIDTH-1:0] qp_x,
    input [`BIT_WIDTH-1:0] qp_y,
    input [`BIT_WIDTH-1:0] qp_z,

    input knn_entry_t prev_knn_point_in [0:`K-1], 

    output knn_entry_t prev_knn_point_out, // add in the distance squared!!
);

    //Intermediate Values
    logic [`BIT_WIDTH-1:0] delta_x, delta_y, delta_z;

    assign delta_x = prev_knn_point_in.x - qp_x; 
    assign delta_y = prev_knn_point_in.x - qp_x;
    assign delta_z = prev_knn_point_in.x - qp_x;

    logic [`BIT_WIDTH-1:0] abs_x, ab_y, abs_z;

    assign abs_x = delta_x[`BIT_WIDTH-1] ? (~delta_x + 1) ? delta_x; 
    assign abs_y = delta_y[`BIT_WIDTH-1] ? (~delta_y + 1) ? delta_y; 
    assign abs_z = delta_z[`BIT_WIDTH-1] ? (~delta_z + 1) ? delta_z; 


    // Assign the calulated distance 
    assign prev_knn_point_out.distance = (abs_f_x << 1) + (abs_f_y << 1) + (abs_f_z << 1); 

    // Pass through the other values 
    assign prev_knn_point_out.x = prev_knn_point_in.x;
    assign prev_knn_point_out.y = prev_knn_point_in.y;
    assign prev_knn_point_out.z = prev_knn_point_in.z;
    assign prev_knn_point_out.point_id = prev_knn_point_in.point_id;
    assign prev_knn_point_out.valid = prev_knn_point_in.valid;

endmodule