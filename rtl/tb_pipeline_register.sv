module tb_pipeline_register;

    parameter DATA_WIDTH = 32;
    
    logic clk, rst, in_valid, in_ready, out_valid, out_ready;
    logic [DATA_WIDTH-1:0] in_data, out_data;

    // Instantiate DUT
    pipeline_register #(.DATA_WIDTH(DATA_WIDTH)) dut (.*);

    // Clock Gen
    initial clk = 0;
    always #5 clk = ~clk;

    // Table Header
    initial begin
        #1; // Small delay to let reset initialize
        $display("\nREADY VALID TEST");
        $display("---------------------");
        $display("RST | IN_VAL | OUT_VAL | IN_DATA  | OUT_DATA");
        $display("---------------------");
    end

    // Table Data Rows - Prints on every clock edge
    always @(posedge clk) begin
        $display("%b   | %b      | %b       | %h | %h", 
                 rst, in_valid, out_valid, in_data, out_data);
    end

    initial begin
        // 1. Reset State
        rst = 1; in_valid = 0; out_ready = 0; in_data = 0;
        repeat(2) @(posedge clk);
        rst = 0;

        // 2. Simple Transfer
        @(posedge clk);
        in_valid = 1; in_data = 32'hAAAA_BBBB;
        out_ready = 1; 
        @(posedge clk);
        in_valid = 0;
        @(posedge clk);

        // 3. Backpressure (Fill and Hold)
        @(posedge clk);
        in_valid = 1; in_data = 32'h1111_2222;
        out_ready = 0; 
        @(posedge clk);
        in_valid = 1; in_data = 32'h3333_4444; 
        
        repeat(2) @(posedge clk); 
        
        // 4. Release Backpressure
        out_ready = 1;
        in_valid = 0;
        @(posedge clk);

        repeat(2) @(posedge clk);
        $display("---------------------");
        $finish;
    end

    // Waveform Generation
    initial begin
        $dumpfile("pipeline_register.vcd");
        $dumpvars(0, tb_pipeline_register);
    end

endmodule