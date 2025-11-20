`define W = 10

module running_mean (
    input clk,
    input rst,

    input top_k_done,
    input [`B-1:0] kth_distance,

    output [`B-1:0] running_mean_out,
    output running_mean_valid
);
    logic [`W +`B-1:0] running_sum;
    logic [`W-1:0] q_ctr;

    assign running_mean_out = running_sum / q_ctr;


    always_ff@(posedge clk) begin
        if(rst) begin
            running <= 0;
            q_ctr <= 0;
        end else begin
            q_ctr <= top_k_done ?  (&q_ctr ? qctr : q_ctr + 1'b1) : q_ctr;
            running_sum <= top_k_done ? (&q_ctr ? running_sum - running_mean_out + kth_distance : running_sum + kth_distance) : running_sum;
        end
    end

    assign running_mean_valid = !top_k_done;


endmodule