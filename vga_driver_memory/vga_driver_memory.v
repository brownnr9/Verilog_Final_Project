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

	// Turn off all displays.
	assign	HEX0		=	7'h7F; // Display nothing
	assign	HEX1		=	7'h7F;
	assign	HEX2		=	7'h7F;
	assign	HEX3		=	7'h7F;
	
	// Internal Wires and Registers
	wire [9:0] x; // current x (0 to 639)
	wire [9:0] y; // current y (0 to 479)
	wire active_pixels; // high when drawing in the 640x480 region
	
	wire clk;
	wire rst;

	assign clk = CLOCK_50;
	assign rst = SW[0]; // SW[0] acts as a system reset (active high in this usage)

	// LEDR[0] indicates if we are in the active drawing area
	assign LEDR[0] = active_pixels;
    // Keep other LEDs off
    assign LEDR[9:1] = 9'h000;

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
	parameter BOX_Y_START 	= 10'd225; // Center the box vertically: (480/2) - (30/2) = 240 - 15 = 225
	parameter MOVE_STEP 	= 10'd2;   // Move 2 pixels per update
	parameter MAX_X 		= 10'd639; // Screen width end pixel

	// --- State Registers for Box Position and Direction ---
	reg [9:0] box_x = 10'd50; // Current left edge X position
	reg direction = 1'b1;     // 1'b1: Right, 1'b0: Left

	// --- Speed Control Logic ---
	// 22-bit counter: 50MHz / 2^22 = ~11.9 updates per second
	reg [21:0] move_counter = 22'd0;
	parameter MOVE_SPEED_DIV = 22'd2097152; // 2^22
	wire move_en = (move_counter == (MOVE_SPEED_DIV - 1'b1));


	// --- Box Movement Logic (50MHz Clock) ---
	always @(posedge clk or negedge rst)
	begin
		if (rst == 1'b0) begin
			// Reset state
			box_x <= 10'd50;
			direction <= 1'b1;
			move_counter <= 22'd0;
		end
		else begin
			// Increment counter
			move_counter <= move_counter + 1'b1;

			if (move_en) begin // Update position only when the slow clock is enabled
				// Reset the counter on movement cycle
				move_counter <= 22'd0;

				if (direction == 1'b1) begin // Moving Right
					// Check right edge: box's right edge (box_x + BOX_WIDTH) vs MAX_X (639)
					if (box_x >= (MAX_X - BOX_WIDTH + 10'd1) - MOVE_STEP) begin
						// Hit right edge, reverse direction and move one step left
						direction <= 1'b0;
						box_x <= box_x - MOVE_STEP;
					end else begin
						// Move right
						box_x <= box_x + MOVE_STEP;
					end
				end
				else begin // Moving Left
					// Check left edge: box's left edge (box_x) vs 0
					if (box_x <= MOVE_STEP) begin
						// Hit left edge, reverse direction and move one step right
						direction <= 1'b1;
						box_x <= box_x + MOVE_STEP;
					end else begin
						// Move left
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