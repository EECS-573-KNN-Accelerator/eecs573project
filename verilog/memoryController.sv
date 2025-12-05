`include "global_defs.sv"

module memory_controller #(
    // Addressing: base addresses for Reference Points, Query Points, and KNN IDs
    parameter ADDR R_BASE          = R_BASE,
    parameter ADDR Q_BASE          = Q_BASE,
    parameter ADDR O_BASE          = O_BASE
)(
    input clk,
    input rst,

    // Memory interface signals
    input  MEM_TAG     mem2proc_transaction_tag, // Memory tag for current transaction
    input  MEM_BLOCK   mem2proc_data,            // Data coming back from memory
    input  MEM_TAG     mem2proc_data_tag,        // Tag for which transaction data is for
    output MEM_COMMAND proc2mem_command, // Command sent to memory
    output ADDR        proc2mem_addr,    // Address sent to memory
    output MEM_BLOCK   proc2mem_data,     // Data sent to memory

    // data signals
    input  logic       bdus_done,
    input  logic       new_query,
    output BDU_Input   BDU_inputs [`NUM_BDU],
    output logic       topK_input_sel,
    output logic       topK_inputs_valid_sel,

    input knn_entry_t knn_buffer_in [`K-1:0]

    output logic       done
);

    typedef enum logic [2:0] {
        RESET = 0,
        FETCH_Q = 1,
        FETCH_R = 2,
        WAIT_DRAIN = 3, //Wait for systolic shift of th BDUs into TopK
        WRITE_BACK = 4
    } state_e;

    state_e state, next_state;

    [$clog2(3*`BIT_WIDTH)-1:0] bit_counter, next_bit_counter;
    [$clog2(`NUM_POINTS/`MEMORY_BIT_WIDTH)-1:0] batch_counter, next_batch_counter;
    [$clog2(`NUM_BDU)-1:0] bdu_ctr, next_bdu_ctr;

    always_comb begin //state machine
        next_state = state;
        next_batch_counter = batch_counter;
        next_bit_counter = bit_counter;
        next_bdu_ctr = bdu_ctr;

        unique case (state)
            RESET: begin    
                if(!rst) next_state = FETCH_Q;
            end
            FETCH_Q: begin
                next_state = FETCH_R;
            end
            FETCH_R: begin
                if(!alldone) begin 
                    next_bit_counter = (bit_counter + 1) % (3*`BIT_WIDTH);
                    if(bit_counter == (3*`BIT_WIDTH - 1)) begin
                        next_state = WAIT_DRAIN;
                        next_bdu_ctr = `NUM_BDU - 1;
                    end
                end
                else begin
                    next_state = WAIT_DRAIN;
                    next_bdu_ctr = `NUM_BDU - 1;
                end
            end
            WAIT_DRAIN: begin
                if(bdu_ctr == 0) begin
                    next_batch_counter = (batch_counter + 1) % (`NUM_POINTS/`MEMORY_BIT_WIDTH);
                    if (batch_counter == (`NUM_POINTS/`MEMORY_BIT_WIDTH - 1))
                        next_state = WRITE_BACK;
                    else 
                        next_state = FETCH_R;
                end else begin 
                    next_bdu_ctr = bdu_ctr - 1;
                end
            end
            WRITE_BACK: begin
                next_state = FETCH_Q;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if(rst) begin
            state <= RESET;
            batch_counter <= '0;
            bit_counter <= '0;
            bdu_ctr <= '0;
        end else begin
            state <= next_state;
            batch_counter <= next_batch_counter;
            bit_counter <= next_bit_counter;
            bdu_ctr <= next_bdu_ctr;
        end
    end


    always_comb begin
        proc2mem_command = NONE;
        proc2mem_addr = '0;
        proc2mem_data = '0;

        if()
    end    

    

    query_point_buffer query_buffer (  
        .clk(clk),
        .rst(rst),
        .query_mem_in(mem2proc_data.dbbl_level),
        .query_mem_in_valid(mem2proc_transaction_tag != 4'd0), // assuming tag 0 is invalid
        .ref_counter(bit_counter),
        .all_done(bdus_done),
        .query_bit_out(query_bit_out),
        .query_bit_out_valid(query_bit_out_valid)
    );

    logic [`ID_WIDTH-1:0] current_query_id;
    logic [`ID_WIDTH-1:0] current_ref_id;
    logic [`ID_WIDTH-1:0] current_knn_id;   

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic
            current_query_id <= '0;
            current_ref_id <= '0;
            current_knn_id <= '0;
            proc2mem_command <= NONE;
            proc2mem_addr <= '0;
            proc2mem_data <= '0;
            BDU_inputs <= '0;
            topK_input_sel <= 1'b0;
            topK_inputs_valid_sel <= 1'b0;
            done <= 1'b0;
        end else begin
            
        end
    end



endmodule



    // Buffer implementation here

module query_point_buffer (
    input clk,
    input rst,

    input [`MEMORY_BIT_WIDTH-1:0] query_mem_in,
    input query_mem_in_valid,
    input [$clog2(3*`BIT_WIDTH) - 1:0] bit_counter,   //count from 0 to BIT_WIDTH*3-1
    input all_done,
    output logic query_bit_out,
    output logic query_bit_out_valid
);

    logic [`MEMORY_BIT_WIDTH-1:0] query_mem_buffer;
    
always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
        query_mem_buffer <= '0;
    end else begin
        if (bit_counter == '0 && query_mem_in_valid) begin
            query_mem_buffer <= query_mem_in;
        end
    end
end

always_comb begin
    if (bit_counter < 3*`BIT_WIDTH && !all_done) begin
        query_bit_out = query_mem_buffer[bit_counter];
    end else begin
        query_bit_out = 1'b0;
    end
    query_bit_out_valid = !all_done && (bit_counter < 3*`BIT_WIDTH);
end

endmodule
    // Buffer implementation here