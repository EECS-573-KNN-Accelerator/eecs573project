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
    output BDU_Input   BDU_inputs [`NUM_BDU],
    output logic       topK_input_sel,
    output logic       topK_inputs_valid_sel,

    input knn_entry_t knn_buffer_in [`K-1:0],   //input from topk. write back to memory
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
    [$clog2(`NUM_POINTS)-1:0] query_counter, next_query_counter;

    //state machine
    always_comb begin 
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

    // State register
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

    //State Machine outputs
    always_comb begin
        proc2mem_command = NONE;
        proc2mem_addr = '0;
        proc2mem_data = '0;

        unique case (state)
            FETCH_Q: begin
                proc2mem_command = MEM_LOAD;
                proc2mem_addr = Q_BASE + query_counter * (`MEMORY_BIT_WIDTH/8);
            end
            FETCH_R: begin
                proc2mem_command = MEM_LOAD;
                proc2mem_addr = R_BASE + (batch_counter * 3*`BIT_WIDTH * (`MEMORY_BIT_WIDTH/8) + bit_counter * (`MEMORY_BIT_WIDTH/8));
            end
            WRITE_BACK: begin
                proc2mem_command = MEM_STORE;
                proc2mem_addr = O_BASE + (query_counter * (`MEMORY_BIT_WIDTH/8));
                //prepare data to write back
                for (int i = 0; i < `K; i++) begin
                    proc2mem_data.half_level[i] = knn_buffer_in[i].point_id;
                end
            end
        endcase
    end 

    // Assign BDU inputs
    always_comb begin
        for(int i = 0; i < `NUM_BDU; i++) begin
            BDU_inputs[i].valid = !alldone;
            BDU_inputs[i].q_bit = query_bit_out;
            BDU_inputs[i].r_bit = mem2proc_data.dbbl_level[i];
            case (bit_counter % 3)
                0: BDU_inputs[i].code = 2'b01; // x
                1: BDU_inputs[i].code =  2'b10; // y
                2: BDU_inputs[i].code =  2'b11; // z
            endcase
            BDU_inputs[i].b = bit_counter/3 + 1;
            BDU_inputs[i].point_id = batch_counter * (`MEMORY_BIT_WIDTH) + i;
        end
    end


    // Instantiate query point buffer
    query_point_buffer query_buffer (  
        .clk(clk),
        .rst(rst),
        .query_mem_in(mem2proc_data.dbbl_level),
        .query_mem_in_valid(state == FETCH_Q), // assuming tag 0 is invalid
        .bit_counter(bit_counter),
        .all_done(bdus_done),
        .query_bit_out(query_bit_out),
        .query_bit_out_valid(query_bit_out_valid)
    );
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
