module pipeline_register #(
    parameter int DATA_WIDTH = 32  // Parameterized data width
) (
    input  logic                    clk,
    input  logic                    rst,
    
    // Input interface
    input  logic                    in_valid,
    output logic                    in_ready,
    input  logic [DATA_WIDTH-1:0]   in_data,
    
    // Output interface
    output logic                    out_valid,
    input  logic                    out_ready,
    output logic [DATA_WIDTH-1:0]   out_data
);

    // Internal storage
    logic [DATA_WIDTH-1:0] data_reg;
    logic                  valid_reg;
    
    // Handshake logic
    logic input_fire;   // Input transaction occurs
    logic output_fire;  // Output transaction occurs
    
    assign input_fire  = in_valid && in_ready;
    assign output_fire = out_valid && out_ready;
    
    // Ready logic: Can accept new data when register is empty OR 
    // when current data is being consumed
    assign in_ready = !valid_reg || output_fire;
    
    // Output valid signal comes directly from the valid register
    assign out_valid = valid_reg;
    
    // Output data comes directly from the data register
    assign out_data = data_reg;
    
    // Sequential logic
    always_ff @(posedge clk) begin
        if (rst) begin
            valid_reg <= 1'b0;
            data_reg  <= '0;  // Optional: clear data on reset
        end else begin
            // Update valid register
            if (input_fire && !output_fire) begin
                // Accept new data, output not consumed
                valid_reg <= 1'b1;
            end else if (!input_fire && output_fire) begin
                // Output consumed, no new input
                valid_reg <= 1'b0;
            end
            // else: both fire or neither fires - valid_reg stays same
            
            // Update data register when accepting new input
            if (input_fire) begin
                data_reg <= in_data;
            end
        end
    end

    // Optional assertions for verification (can be disabled in synthesis)
    `ifdef FORMAL
    // Check no data loss
    assert property (@(posedge clk) disable iff (rst)
        in_valid && in_ready |=> out_valid || (out_valid && !out_ready));
    
    // Check data stability
    assert property (@(posedge clk) disable iff (rst)
        out_valid && !out_ready |=> $stable(out_data));
    `endif

endmodule
