module vga_driver_memory #(
    parameter BOX_WIDTH 	= 10'd30,
    parameter BOX_HEIGHT 	= 10'd30,
    parameter BOX_Y_START 	= 10'd315
) (
	// Inputs for player position
	input [9:0] player_x,		// Input: Player's X position

    // Inputs for obstacle position and size
    input [9:0] obstacle_x,
    input [9:0] obstacle_y,
    input [9:0] obstacle_width,
    input [9:0] obstacle_height,

	// Inputs from VGA Timing Generator
	input [9:0] x,				// Input: Current X pixel
	input [9:0] y,				// Input: Current Y pixel
	input active_pixels,		// Input: High when inside 640x480 boundary
	
	// VGA Outputs (Color components only)
	output reg [7:0] VGA_R,		// Output: Red color component
	output reg [7:0] VGA_G,		// Output: Green color component
	output reg [7:0] VGA_B		// Output: Blue color component
);

	// --- VGA Color Assignment Logic (Combinational Renderer) ---
	always @(*)
	begin
		// Default Background Color: Soft Gray-Blue (0x506070)
		VGA_R = 8'h50;
		VGA_G = 8'h60;
		VGA_B = 8'h70;
		
		// Only draw if we are in the active pixel region
		if (active_pixels) begin
            
			// 1. Draw the Player Box (Bright Red: 0xFF0000)
			if (x >= player_x && x < (player_x + BOX_WIDTH) &&
				y >= BOX_Y_START && y < (BOX_Y_START + BOX_HEIGHT))
			begin
				VGA_R = 8'hFF;
				VGA_G = 8'h00;
				VGA_B = 8'h00;
			end

            // 2. Draw the Obstacle Box (Bright Green: 0x00FF00)
            // Check if the current pixel (x, y) is inside the obstacle box
			else if (x >= obstacle_x && x < (obstacle_x + obstacle_width) &&
				     y >= obstacle_y && y < (obstacle_y + obstacle_height))
			begin
				VGA_R = 8'h00;
				VGA_G = 8'hFF;
				VGA_B = 8'h00;
			end
		end
	end

endmodule