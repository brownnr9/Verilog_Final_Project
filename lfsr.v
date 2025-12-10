module random_generator #(
    parameter MIN_VALUE  = 10'd25, // Minimum amplitude (e.g., 10 pixels)
    parameter MAX_VALUE  = 10'd175  // Maximum amplitude (e.g., 80 pixels)
) (
    input clk,
    input rst,
    input game_en, // Slow clock enable for updates

    output reg [9:0] random_out
);

    reg [9:0] lfsr_reg; // 10-bit LFSR register (Taps: 10, 7, 3, 2 for maximal period)
    
    // Constant for the range of the random output
    parameter RANGE = MAX_VALUE - MIN_VALUE; 

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            lfsr_reg <= 10'd1; // Seed
            random_out <= MIN_VALUE;
        end else if (game_en) begin
            // 1. Calculate the next LFSR state
            lfsr_reg <= {lfsr_reg[8:0], lfsr_reg[9] ^ lfsr_reg[6] ^ lfsr_reg[2] ^ lfsr_reg[1]};

            // 2. Map the LFSR output to the desired range [MIN_VALUE, MAX_VALUE]
            // We use the full lfsr_reg value for better distribution, then use the modulus operator.
            // Result = MIN_VALUE + (lfsr_reg % RANGE)
            random_out <= MIN_VALUE + (lfsr_reg % RANGE);
        end
    end

endmodule