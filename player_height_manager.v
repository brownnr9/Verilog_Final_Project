module player_height_manager #(
    parameter BASE_HEIGHT = 10'd30 // Height of one segment
) (
    input 					clk, 		// 50 MHz clock
    input 					rst, 		// Reset signal (active high)
    input 					game_en,	// Slow clock enable from game_clock_generator
	input						collision,  // Collision input (comes from detector)
	
    output reg [9:0] 		current_height // Output current total height
);

    reg collision_flag_q; // Latched collision signal for edge detection
    
    // --- Collision Edge Detector ---
    // Detects when collision goes high on a game clock cycle
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            collision_flag_q <= 1'b0;
        end else if (game_en) begin
            collision_flag_q <= collision;
        end
    end

    // --- Height Update Logic ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            // Start at one segment tall
            current_height <= BASE_HEIGHT; 
        end else if (game_en) begin
            // Detect the rising edge of collision (to prevent continuous growth)
            if (collision && !collision_flag_q) begin
                // Increase height by one segment
                current_height <= current_height + BASE_HEIGHT;
            end
        end
    end

endmodule