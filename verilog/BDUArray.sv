module BDUArray (
    
    input logic clk, 
    input logic rst, 
    input BDU_Input BDU_inputs [`NUM_BDU], 
    
    input logic [`B-1:0] threshold_in, 

    output logic shift

); 

logic alldone; 
//logic [`NUM_BDU-1:0] dones;
BDU_Outut BDU_outputs [`NUM_BDU]; 

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

            .terminate(BDU_outputs[i].terminate), 
            .done(dones[i]), 
            .ref_coor_x(BDU_outputs[i].ref_coor_x), 
            .ref_coor_y(BDU_outputs[i].ref_coor_y), 
            .ref_coor_z(BDU_outputs[i].ref_coor_z)
        ); 
    end
endgenerate

assign shift = 



endmodule 