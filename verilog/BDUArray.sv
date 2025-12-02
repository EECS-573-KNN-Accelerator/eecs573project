module BDUArray (
    
    input logic clk, 
    input logic rst, 
    input BDU_Input BDU_inputs [`NUM_BDU], 
    
    input logic [`B-1:0] threshold_in, 

    output knn_entry_t shift

); 

logic alldone; 
logic [`NUM_BDU-1:0] dones;
knn_entry_t BDU_outputs [`NUM_BDU]; 
knn_entry_t [`NUM_BDU-1:0] syst_arr;

assign alldone = &dones;



genvar i;
generate
    for(i = 0; i < `NUM_BDU; i++) begin
        BDU bdu1(
            .clk(clk),
            .rst(rst),
            .valid(BDU_inputs[i].valid),
            .q_bit(BDU_inputs[i].q_bit), 
            .r_bit(BDU_inputs[i].r_bit), 
            .code(BDU_inputs[i].code), 
            .b(BDU_inputs[i].b), 
            .threshold(threshold_in), 

            .complete(dones[i]), 
            .bdu_out(BDU_outputs[i])
        ); 
    end
endgenerate

assign shift = syst_arr[0];

always_ff @(posedge clk) begin
    if(rst) begin
        syst_arr <= 1'b0; 
    end
    else begin
        if(alldone) begin
            syst_arr <= BDU_outputs
        end
        else begin
            for (int j = 0; j < `NUM_BDU-2; j++) begin
                syst_arr[j] <= syst_arr[j+1];
            end
        end
    end
end


endmodule 