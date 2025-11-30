module vga_driver_memory #(
    parameter BOX_WIDTH 	= 10'd30,
    parameter BOX_HEIGHT 	= 10'd30,
    parameter BOX_Y_START 	= 10'd225
) (
	// Inputs for object position
	input [9:0] player_x,		// Input: Player's X position

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
	// All rendering calculations now use the parameters defined in the header, 
    // which were passed down from the top module.
	always @(*)
	begin
		// Default Background Color: Dark Blue (0x101080)
		VGA_R = 8'h10;
		VGA_G = 8'h10;
		VGA_B = 8'h80;
		
		// Only draw if we are in the active pixel region
		if (active_pixels) begin
			// Check if the current pixel (x, y) is inside the player box
			if (x >= player_x && x < (player_x + BOX_WIDTH) && 
				y >= BOX_Y_START && y < (BOX_Y_START + BOX_HEIGHT))
			begin
				// Draw the player box in Bright Red (0xFF0000)
				VGA_R = 8'hFF;
				VGA_G = 8'h00;
				VGA_B = 8'h00;
			end
	end
end

endmodule