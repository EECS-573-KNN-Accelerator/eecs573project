`include "include/global_defs.svh"
`define TB_MAX_CYCLES 200000


module testbench;
    // string inputs for loading memory and output files
    // run like: cd build && ./simv +MEMORY=../mem/<my_test>.mem +OUTPUT=../output/<my_test>
    // this testbench will generate 4 output files based on the output
    // named OUTPUT.{out cpi, wb, ppln} for the memory, cpi, writeback, and pipeline outputs.
    string R_mem, Q_mem, KNN_mem;
    string output_name;
    string out_outfile;// mem_output file
    int out_fileno; // verilog uses integer file handles with $fopen and $fclose

    // variables used in the testbench
    logic        clock;
    logic        reset;
    
    logic [31:0] clock_count; // also used for terminating infinite loops

    
    MEM_COMMAND proc2mem_command;
    ADDR        proc2mem_addr;
    MEM_BLOCK   proc2mem_data;
    MEM_TAG     mem2proc_transaction_tag;
    MEM_BLOCK   mem2proc_data;
    MEM_TAG     mem2proc_data_tag;
    MEM_SIZE    proc2mem_size;
    
    logic done;

    //EXCEPTION_CODE error_status = NO_ERROR;

    
    // INST          [`N-1:0] insts;
    // ADDR          [`N-1:0] PCs;
    // COMMIT_PACKET [`N-1:0] committed_insts;

    // UPDATED MEMORY
    MEM_BLOCK updated_memory [`MEM_64BIT_LINES-1:0];

    localparam WIDTH = $bits(MEM_BLOCK);

    
    localparam integer R_IDX = R_BASE >> 3;  
    localparam integer Q_IDX = Q_BASE >> 3;
    localparam integer O_IDX = O_BASE >> 3;
    localparam integer BUF_SZ = BUF_SIZE_BYTES >> 3;

    
    // Instantiate the the Top-Level
    bitNN bitNN_dut (
        // Inputs
        .clock (clock),
        .reset (reset),
        
        .mem2proc_transaction_tag (mem2proc_transaction_tag),
        .mem2proc_data            (mem2proc_data),
        .mem2proc_data_tag        (mem2proc_data_tag),

        // Outputs
        .proc2mem_command (proc2mem_command),
        .proc2mem_addr    (proc2mem_addr),
        .proc2mem_data    (proc2mem_data),

        .done(done)
    );

    // Instantiate the Data Memory
    mem memory (
        // Inputs
        .clock            (clock),
        .proc2mem_command (proc2mem_command),
        .proc2mem_addr    (proc2mem_addr),
        .proc2mem_data    (proc2mem_data),

        // Outputs
        .mem2proc_transaction_tag (mem2proc_transaction_tag),
        .mem2proc_data            (mem2proc_data),
        .mem2proc_data_tag        (mem2proc_data_tag)
    );
    

    // Generate System Clock
    always begin
        #(`CLOCK_PERIOD/2.0);
        clock = ~clock;
    end

    initial begin
        //$dumpfile("../aura.vcd");
        //$dumpvars(0, testbench.AURA_dut);

        $display("\n---- Starting CPU Testbench ----\n");

        // set paramterized strings, see comment at start of module
        if ($value$plusargs("R_MEMORY=%s", R_mem)) begin
            $display("Using Q memory file  : %s", Q_mem);
        end else begin
            $display("Did not receive '+Q_MEMORY=' argument. Exiting.\n");
            $finish;
        end

        if ($value$plusargs("Q_MEMORY=%s", Q_mem)) begin
            $display("Using K memory file  : %s", K_mem);
        end else begin
            $display("Did not receive '+K_MEMORY=' argument. Exiting.\n");
            $finish;
        end

        if ($value$plusargs("OUTPUT=%s", output_name)) begin
            $display("Using output files : %s.out", output_name);
            out_outfile       = {output_name,".out"}; // this is how you concatenate strings in verilog
        end else begin
            $display("\nDid not receive '+OUTPUT=' argument. Exiting.\n");
            $finish;
        end

        clock = 1'b0;
        reset = 1'b0;

        $display("\n  %16t : Asserting Reset", $realtime);
        reset = 1'b1;

        @(posedge clock);
        @(posedge clock);

        $display("  %16t : Loading Unified Memory", $realtime);
        // load the compiled program's hex data into the memory module
        $readmemh(R_mem, memory.unified_memory, R_IDX, R_IDX + BUF_SZ - 1);
        $readmemh(Q_mem, memory.unified_memory, Q_IDX, Q_IDX + BUF_SZ - 1);

        @(posedge clock);
        @(posedge clock);
        #1; // This reset is at an odd time to avoid the pos & neg clock edges
        $display("  %16t : Deasserting Reset", $realtime);
        reset = 1'b0;

        out_fileno = $fopen(out_outfile);

        $display("  %16t : Running Processor", $realtime);
    end

    always @(negedge clock) begin
        if (reset) begin
            // Count the number of cycles and number of instructions committed
            clock_count = 0;
        end else begin
            #2; // wait a short time to avoid a clock edge

            clock_count = clock_count + 1;

            if (clock_count % 10000 == 0) begin
                $display("  %16t : %d cycles", $realtime, clock_count);
            end

            // stop the processor
            if (done || clock_count > `TB_MAX_CYCLES) begin

                $display("  %16t : Processing Finished", $realtime);

                @(negedge clock);
                show_final_mem_and_status();

                $display("\n---- Finished CPU Testbench ----\n");

                #100 $finish;
            end
        end // if(reset)
    end


    // Show contents of Unified Memory in both hex and decimal
    // Also output the final processor status
    task show_final_mem_and_status;
        
        begin
            
            updated_memory = memory.unified_memory;
            $fdisplay(out_fileno, "\nFinal memory state and exit status:\n");
            $fdisplay(out_fileno, "@@@ Unified Memory contents hex on left, decimal on right: ");
            $fdisplay(out_fileno, "Display starts at Base Addr: %x", O_BASE);
            $fdisplay(out_fileno, "@@@");

            for(int k = 0; k < ??; k++) begin
                $fdisplay(out_fileno, "@@@ mem[%5d] = %x : %0d", k*`INTEGER_WIDTH, updated_memory[O_IDX + k], updated_memory[O_IDX + k]);
            end

            $fdisplay(out_fileno, "@@@");

            $fdisplay(out_fileno, "@@@");
            $fclose(out_fileno);
        end
    endtask // task show_final_mem_and_status

    



    // OPTIONAL: Print our your data here
    // It will go to the $program.log file
    task print_custom_data;
        $display("%3d: YOUR DATA HERE", 
           clock_count-1
        );
    endtask


endmodule // module testbench