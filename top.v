module top(
	input 						CLOCK_50,

	// KEY (Active Low)
	input 		[3:0]		KEY,

	// SW
	input 		[9:0]		SW,

	// VGA Outputs (These are the actual FPGA pins)
	output 						VGA_BLANK_N,
	output reg	[7:0]		VGA_B,
	output 						VGA_CLK,
	output reg	[7:0]		VGA_G,
	output 						VGA_HS,
	output reg	[7:0]		VGA_R,
	output 						VGA_SYNC_N,
	output 						VGA_VS
);

	// --- GLOBAL GAME PARAMETERS (Defined once here) ---                                                          
	// Player/Box Dimensions
	parameter BOX_WIDTH 	= 10'd30;
	parameter BOX_HEIGHT 	= 10'd30;
	parameter BOX_Y_START 	= 10'd315;
	// Movement Speed (used by player_control)
	parameter MOVE_STEP 	= 10'd4; 

	// --- System Clock and Reset ---
	wire clk;
	wire rst; 

	assign clk = CLOCK_50;
	assign rst = SW[0]; // SW[0] is the system reset (active high)

	// --- Internal Communication Wires ---
	
	// Wires for VGA Timing (Outputs from vga_driver)
	wire [9:0] x; // Current X pixel coordinate
	wire [9:0] y; // Current Y pixel coordinate
	wire active_pixels; // High when inside 640x480 boundary

	// Wire for Player Position (Output from player_control)
	wire [9:0] player_x_pos; 

	// Wires for Color Data (Output from vga_driver_memory/Renderer)
	wire [7:0] vga_r_color;
	wire [7:0] vga_g_color;
	wire [7:0] vga_b_color;


	// --- 1. VGA Driver Instantiation (Timing Generator) ---
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

	// --- 2. VGA Display Renderer Instantiation (Color Logic) ---
	// Passes all necessary inputs (position, coordinates, active area) to draw the box.
	vga_driver_memory #(.BOX_WIDTH(BOX_WIDTH), 
                        .BOX_HEIGHT(BOX_HEIGHT), 
                        .BOX_Y_START(BOX_Y_START)) the_renderer (
		.player_x(player_x_pos),
		.x(x),
		.y(y),
		.active_pixels(active_pixels),
		.VGA_R(vga_r_color), // Color wires are driven here
		.VGA_G(vga_g_color),
		.VGA_B(vga_b_color)
	);

	// --- Connect Internal Color Wires to Top-Level VGA Ports ---
	// This synchronous block drives the output registers of the top module.
	always @(posedge clk) begin
		VGA_R <= vga_r_color;
		VGA_G <= vga_g_color;
		VGA_B <= vga_b_color;
	end
	
	// ---3. Instantiate slower game clock (pass into control module and moving objects)
	wire game_en;
	game_clock_generator game_clk(clk, rst, game_en);
	
	//---4. Instantiate player control module
	
	player_control#(.BOX_WIDTH(BOX_WIDTH), .MOVE_STEP(MOVE_STEP)) the_controller(
		clk, rst, game_en, KEY[1:0], 		player_x_pos);

endmodule