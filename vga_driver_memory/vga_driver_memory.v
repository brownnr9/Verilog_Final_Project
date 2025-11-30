module vga_driver_memory (
	input 						CLOCK_50,

	// SEG7
	output 		[6:0]		HEX0,
	output 		[6:0]		HEX1,
	output 		[6:0]		HEX2,
	output 		[6:0]		HEX3,

	// KEY
	input 		[3:0]		KEY,

	// LED
	output 		[9:0]		LEDR,

	// SW
	input 		[9:0]		SW,

	// VGA
	output 						VGA_BLANK_N,
	output reg	[7:0]		VGA_B,
	output 						VGA_CLK,
	output reg	[7:0]		VGA_G,
	output 						VGA_HS,
	output reg	[7:0]		VGA_R,
	output 						VGA_SYNC_N,
	output 						VGA_VS
);

	// Display Logic
	assign	HEX0 = 7'h7F; 
	assign	HEX1 = 7'h7F;
	assign	HEX2 = 7'h7F;
	assign	HEX3 = 7'h7F;
	
	// Internal Wires and Registers
	wire [9:0] x; // current VGA x pixel (0 to 639)
	wire [9:0] y; // current VGA y pixel (0 to 479)
	wire active_pixels; 
	
	wire clk;
	wire rst;

	assign clk = CLOCK_50;
	assign rst = SW[0]; // SW[0] is the system reset (active high)

	// LEDR[0] shows active pixel area
	assign LEDR[0] = active_pixels;
    assign LEDR[9:1] = 9'h00; // Keep other LEDs off

	// --- VGA Driver Instantiation ---
	vga_driver the_vga(
		.clk(clk),
		.rst(rst),
		.vga_clk(VGA_CLK),
		.hsync(VGA_HS),
		.vsync(VGA_VS),
		.active_pixels(active_pixels),
		.xPixel(x),
		.yPixel(y),
		.VGA_BLANK_N(VGA_BLANK_N),
		.VGA_SYNC_N(VGA_SYNC_N)
	);

	// --- Bouncing Box Parameters ---
	parameter BOX_WIDTH 	= 10'd30;
	parameter BOX_HEIGHT 	= 10'd30;
	parameter BOX_Y_START 	= 10'd225;
	parameter MOVE_STEP 	= 10'd4;   // Movement step size
	parameter MAX_X 		= 10'd639; // Rightmost pixel
	
	// Define Wall Boundaries for Collision Check
	parameter RIGHT_WALL_THRESHOLD = MAX_X - BOX_WIDTH + 10'd1; 
	parameter LEFT_WALL_THRESHOLD  = 10'd0; 

	// --- State Register for Box Position ---
	reg [9:0] box_x = 10'd50; // Current left edge X position


	/* - - - - - - - - - - - MOVEMENT RATE LIMITER - - - - - - - */
	
	// Push buttons are typically active LOW (0 when pressed).
	// These wires provide the raw, inverted key state (1 when pressed).
	wire key_pressed_0 = ~KEY[0]; // Move Right (held high when pressed)
	wire key_pressed_1 = ~KEY[1]; // Move Left (held high when pressed)

	// 22-bit counter for rate limiting: 50MHz / 2^22 = ~11.9 updates per second
	reg [21:0] move_counter = 22'd0;
	parameter MOVE_SPEED_DIV = 22'd2097152; 
	wire move_en = (move_counter == (MOVE_SPEED_DIV - 1'b1));

	// Rate Limiter Logic
	always @(posedge clk or negedge rst) begin
		if (rst == 1'b0) begin
			move_counter <= 22'd0;
		end else begin
			move_counter <= move_counter + 1'b1;
			if (move_en) begin
				move_counter <= 22'd0; // Reset counter when movement is enabled
			end
		end
	end


	/* - - - - - - - - - - - CONTINUOUS MOVEMENT CONTROL - - - - - - - */

	always @(posedge clk or negedge rst)
	begin
		if (rst == 1'b0) begin
			box_x <= 10'd50;
		end
		else begin
			// Only attempt to move the box when the rate limiter is enabled
			if (move_en) begin
				
				// --- Move Right Logic (Continuous while KEY[0] is held) ---
				if (key_pressed_0) begin
					// Check right collision: only move if the next step stays within the wall boundary
					if (box_x <= (RIGHT_WALL_THRESHOLD - MOVE_STEP)) begin
						box_x <= box_x + MOVE_STEP;
					end
				end

				// --- Move Left Logic (Continuous while KEY[1] is held) ---
				if (key_pressed_1) begin
					// Check left collision: only move if the next step stays within the wall boundary
					if (box_x >= (LEFT_WALL_THRESHOLD + MOVE_STEP)) begin
						box_x <= box_x - MOVE_STEP;
					end
				end
			end
		end
	end


	// --- VGA Color Assignment Logic (Combinational) ---
	// Sets the color for the current pixel (x, y)
	always @(*)
	begin
		// Default Background Color: Dark Blue
		VGA_R = 8'h10;
		VGA_G = 8'h10;
		VGA_B = 8'h80;
		
		// Only draw if we are in the active pixel region
		if (active_pixels) begin
			// Check if the current pixel (x, y) is inside the moving box
			if (x >= box_x && x < (box_x + BOX_WIDTH) && 
				y >= BOX_Y_START && y < (BOX_Y_START + BOX_HEIGHT))
			begin
				// Draw the box in Bright Red
				VGA_R = 8'hFF;
				VGA_G = 8'h00;
				VGA_B = 8'h00;
			end
		end
	end

endmodule