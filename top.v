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
	parameter PLAYER_WIDTH 	    = 10'd30;
	parameter PLAYER_BASE_HEIGHT= 10'd30; // Player segment height
	parameter PLAYER_Y_START    = 10'd315; // Fixed Y position for player base
	// Movement Speed (used by player_control)
	parameter MOVE_STEP 	    = 10'd4;

    // Obstacle Parameters
    parameter OBSTACLE_WIDTH    = 10'd30; // Changed to match player size
    parameter OBSTACLE_HEIGHT   = 10'd30; // Changed to match player size
    parameter OBSTACLE_SPEED    = 10'd8;


	// --- System Clock and Reset ---
	wire clk;
	wire rst;

	assign clk = CLOCK_50;
	assign rst = SW[0]; // SW[0] is the system reset (active high)

	// --- Internal Communication Wires ---
	
	// Wires for Timing
	wire game_en; // Wire for the slow clock enable signal
	
	// Wires for VGA Timing (Outputs from vga_driver)
	wire [9:0] x; // Current X pixel coordinate
	wire [9:0] y; // Current Y pixel coordinate
	wire active_pixels; // High when inside 640x480 boundary

	// Wire for Player Position (Output from player_control)
	wire [9:0] player_x_pos;

    // Wires for Obstacle Position and Size
    wire [9:0] obstacle_x_pos;
    wire [9:0] obstacle_y_pos;
    wire [9:0] obstacle_width_wire;
    wire [9:0] obstacle_height_wire;
	
	// Wire for Collision Detection (Output from detector, Input to control)
	wire obsticle_collision; 
	
	// Wire for Player's current dynamic height
	wire [9:0] player_current_height; // New wire for player's accumulated height

	// Wires for Color Data (Output from vga_driver_memory/Renderer)
	wire [7:0] vga_r_color;
	wire [7:0] vga_g_color;
	wire [7:0] vga_b_color;


	// --- 1. Game Clock Generator Instantiation ---
	game_clock_generator game_clk(
		.clk(clk), 
		.rst(rst), 
		.game_en(game_en) // Connects to the internal wire
	);

	// --- 2. VGA Driver Instantiation (Timing Generator) ---
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
	
	//--- 3. Instantiate player control module
	player_control#(.BOX_WIDTH(PLAYER_WIDTH), .MOVE_STEP(MOVE_STEP)) the_controller(
		.clk(clk), 
		.rst(rst), 
		.game_en(game_en), 
		.buttons(KEY[1:0]), 		
		.box_x(player_x_pos)
	);
	
    // --- 3b. Instantiate Player Health/Height Manager ---
    // Tracks and updates the player's total height based on collision events
    player_height_manager #(.BASE_HEIGHT(PLAYER_BASE_HEIGHT)) the_height_manager (
        .clk(clk),
        .rst(rst),
        .game_en(game_en),
        .collision(obsticle_collision),
        .current_height(player_current_height) // Output of current dynamic height
    );

    // --- 4. Instantiate Obstacle Control Module ---
    // Passes collision signal to the obstacle_control module
    obstacle_control #(.OBSTACLE_WIDTH(OBSTACLE_WIDTH),
                         .OBSTACLE_HEIGHT(OBSTACLE_HEIGHT),
                         .OBSTACLE_Y_SPEED(OBSTACLE_SPEED)) the_obstacle_control (
        .clk(clk),
        .rst(rst),
        .game_en(game_en),
		.collision(obsticle_collision), 
        .obstacle_x_pos(obstacle_x_pos),
        .obstacle_y_pos(obstacle_y_pos),
        // These wires are needed for the collision module later
        .obstacle_width(obstacle_width_wire),
        .obstacle_height(obstacle_height_wire)
    );
	
	// --- 4b. Instantiate Collision Detector Module ---
	// Uses the dynamic player height for vertical collision checks
	collision_detector#(.PLAYER_WIDTH(PLAYER_WIDTH), 
						.PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT), // Parameter for base height
						.PLAYER_Y(PLAYER_Y_START)) obsticle_collision_detector(
			.player_x(player_x_pos),
			.player_height(player_current_height), // Dynamic height input
			.obstacle_x(obstacle_x_pos),
        	.obstacle_y(obstacle_y_pos),
        	.obstacle_width(obstacle_width_wire),
        	.obstacle_height(obstacle_height_wire),
		 	.collision_detected(obsticle_collision));

	// --- 5. VGA Display Renderer Instantiation (Color Logic) ---
	// Now passes the dynamic player height
	vga_driver_memory #(.BOX_WIDTH(PLAYER_WIDTH),
                         .BOX_BASE_HEIGHT(PLAYER_BASE_HEIGHT), // Parameter for base height
                         .BOX_Y_START(PLAYER_Y_START)) the_renderer (
		.player_x(player_x_pos),
		.player_height(player_current_height), // Dynamic height input
        .obstacle_x(obstacle_x_pos),
        .obstacle_y(obstacle_y_pos),
        .obstacle_width(obstacle_width_wire),
        .obstacle_height(obstacle_height_wire),
		.x(x),
		.y(y),
		.active_pixels(active_pixels),
		.VGA_R(vga_r_color),
		.VGA_G(vga_g_color),
		.VGA_B(vga_b_color)
	);


	// --- Connect Internal Color Wires to Top-Level VGA Ports ---
	always @(posedge clk) begin
		VGA_R <= vga_r_color;
		VGA_G <= vga_g_color;
		VGA_B <= vga_b_color;
	end
	

endmodule