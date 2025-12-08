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
    parameter OBSTACLE_X_SPEED  = 10'd5;  // Horizontal speed (used by obstacle_control)
    parameter Y_AMPLITUDE       = 10'd60; // Vertical amplitude for the push up
    parameter Y_INITIAL_OFFSET  = 10'd50; // NEW: Initial height for the obstacle
    
    // Bank Parameters
    parameter BANK_X_START      = 10'd50;  // Left side location
	parameter BANK_Y_START      = 10'd315; // Same baseline as player
	parameter BANK_WIDTH        = 10'd60;


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
	wire [9:0] player_current_height; 
	
	// Wire for Box Drop (Output from bank_control, Input to player_height_manager)
    wire box_dropped;
    
    // Wire for Bank Level/Score (Output from bank_control)
    wire [7:0] bank_level; 

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
	
    // --- 3b. Instantiate Player Height Manager ---
    player_height_manager #(.BASE_HEIGHT(PLAYER_BASE_HEIGHT)) the_health_manager (
        .clk(clk),
        .rst(rst),
        .game_en(game_en),
        .collision(obsticle_collision),
        .box_dropped_in(box_dropped),
        .current_height(player_current_height) // Output of current dynamic height
    );
    
    // --- 3c. Instantiate Bank Control Module ---
    bank_control #(.PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT),
                   .BANK_X_START(BANK_X_START),
                   .BANK_WIDTH(BANK_WIDTH)) the_bank_control (
        .clk(clk),
        .rst(rst),
        .game_en(game_en),
        .key_2_in(KEY[2]), // KEY[2] input for drop action
        .player_x_pos(player_x_pos),
        .player_current_height(player_current_height),
        .box_dropped(box_dropped),
        .bank_level(bank_level)
    );


    // --- 4. Instantiate Obstacle Control Module ---
    obstacle_control #(.OBSTACLE_WIDTH(OBSTACLE_WIDTH),
                         .OBSTACLE_HEIGHT(OBSTACLE_HEIGHT),
                         .OBSTACLE_X_SPEED(OBSTACLE_X_SPEED),
                         .Y_AMPLITUDE(Y_AMPLITUDE),
                         .Y_INITIAL_OFFSET(Y_INITIAL_OFFSET)) // Passing the new parameter
    the_obstacle_control (
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
	// Now passes the dynamic player height and bank parameters
	vga_driver_memory #(.BOX_WIDTH(PLAYER_WIDTH),
                         .BOX_BASE_HEIGHT(PLAYER_BASE_HEIGHT), 
                         .BOX_Y_START(PLAYER_Y_START),
                         .BANK_X_START(BANK_X_START), 
                         .BANK_WIDTH(BANK_WIDTH)) the_renderer ( 
		.player_x(player_x_pos),
		.player_height(player_current_height), 
        .obstacle_x(obstacle_x_pos),
        .obstacle_y(obstacle_y_pos),
        .obstacle_width(obstacle_width_wire),
        .obstacle_height(obstacle_height_wire),
		.x(x),
		.y(y),
        .bank_level(bank_level), 
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