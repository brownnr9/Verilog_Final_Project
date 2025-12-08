module top(
	input 		CLOCK_50,
	input [3:0]	KEY,      // KEY[0]=Start, KEY[1]=Instr
	input [9:0]	SW,       // SW[0]=Reset
	output 		VGA_BLANK_N,
	output reg [7:0] VGA_B,
	output 		VGA_CLK,
	output reg [7:0] VGA_G,
	output 		VGA_HS,
	output reg [7:0] VGA_R,
	output 		VGA_SYNC_N,
	output 		VGA_VS
);

    // --- PARAMETERS [cite: 62] ---
    parameter PLAYER_WIDTH 	    = 10'd30;
    parameter PLAYER_BASE_HEIGHT= 10'd30;
    parameter PLAYER_Y_START    = 10'd315;
    parameter MOVE_STEP 	    = 10'd4;
    parameter OBSTACLE_WIDTH    = 10'd30;
    parameter OBSTACLE_HEIGHT   = 10'd30;
    parameter OBSTACLE_X_SPEED  = 10'd5;
    parameter Y_INITIAL_OFFSET  = 10'd50;
    parameter BANK_X_START      = 10'd50;
    parameter BANK_WIDTH        = 10'd60;

    // --- CLOCK & RESET ---
    wire clk = CLOCK_50;
    wire hard_rst = SW[0];

    // --- FSM & STATE LOGIC ---
    wire [1:0] current_game_state;
    wire obsticle_collision; // From collision detector
    
    // Instantiate State Machine
    game_state_machine fsm (
        .clk(clk),
        .rst(hard_rst),
        .key_action(KEY[0]), // Press to Start/Restart
        .key_instr(KEY[1]),  // Press for Instructions
        .collision(obsticle_collision),
        .state(current_game_state)
    );

    // --- CONTROL LOGIC: Pause & Soft Reset ---
    // 1. Only enable movement logic if we are in PLAYING state (2'b01)
    wire global_game_en; // From clock generator
    wire active_game_en = (current_game_state == 2'b01) ? global_game_en : 1'b0;

    // 2. Soft Reset: Triggers if Hard Reset is pushed OR if we are on the Start Screen.
    // This ensures Player and Obstacles reset to starting positions when you return to menu.
    wire soft_rst = hard_rst && (current_game_state != 2'b00); 
    // Note: SW[0] (hard_rst) is usually active low or high depending on board. 
    // Based on your code [cite: 72] "assign rst = SW[0]", assuming Active High reset logic.
    // If we are in S_START (2'b00), soft_rst becomes 0 (Active Low Reset logic in your modules seems to be mixed, 
    // but your code says "rst == 1'b0" is reset [cite: 104]).
    // Let's standardize: create a wire that drives the 'rst' port of your modules.
    
    // Your modules check "if (rst == 1'b0)". So we need to feed them 0 to reset.
    // We want to feed 0 if SW[0] is 0 OR if state is START.
    wire module_reset_signal = (SW[0] == 1'b1) && (current_game_state != 2'b00);
    // Explanation: If SW is 0 (reset), signal is 0. If State is Start (00), signal is 0. Otherwise 1.

    // --- WIRES ---
    wire [9:0] x, y;
    wire active_pixels;
    wire [9:0] player_x_pos;
    wire [9:0] obstacle_x_pos, obstacle_y_pos, obstacle_width_wire, obstacle_height_wire;
    wire [9:0] player_current_height;
    wire box_dropped;
    wire [7:0] bank_level;
    wire [9:0] rand_y_amplitude;
    wire [7:0] vga_r_c, vga_g_c, vga_b_c;

    // --- MODULES ---

    game_clock_generator game_clk(
        .clk(clk), 
        .rst(SW[0]), // Clock gen always runs on hard reset
        .game_en(global_game_en)
    );

    vga_driver the_vga(
        .clk(clk),
        .rst(SW[0]), // VGA always runs on hard reset
        .vga_clk(VGA_CLK),
        .hsync(VGA_HS),
        .vsync(VGA_VS),
        .active_pixels(active_pixels),
        .xPixel(x),
        .yPixel(y),
        .VGA_BLANK_N(VGA_BLANK_N),
        .VGA_SYNC_N(VGA_SYNC_N)
    );

    // For game logic modules, we use 'module_reset_signal' and 'active_game_en'
    
    player_control #(.BOX_WIDTH(PLAYER_WIDTH), .MOVE_STEP(MOVE_STEP)) the_controller(
        .clk(clk), 
        .rst(module_reset_signal), // Resets when in Start Menu
        .game_en(active_game_en),  // Pauses when not Playing
        .buttons(KEY[1:0]), 		
        .box_x(player_x_pos)
    );

    player_height_manager #(.BASE_HEIGHT(PLAYER_BASE_HEIGHT)) the_health_manager (
        .clk(clk),
        .rst(module_reset_signal),
        .game_en(active_game_en),
        .collision(obsticle_collision),
        .box_dropped_in(box_dropped),
        .current_height(player_current_height)
    );

    bank_control #(.PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT), .BANK_X_START(BANK_X_START), .BANK_WIDTH(BANK_WIDTH)) the_bank_control (
        .clk(clk),
        .rst(module_reset_signal),
        .game_en(active_game_en),
        .key_2_in(KEY[2]), 
        .player_x_pos(player_x_pos),
        .player_current_height(player_current_height),
        .box_dropped(box_dropped),
        .bank_level(bank_level)
    );

    random_generator the_rng(
        .clk(clk),
        .rst(SW[0]), // RNG can keep running to ensure randomness
        .game_en(global_game_en),
        .random_out(rand_y_amplitude)
    );

    obstacle_control #(.OBSTACLE_WIDTH(OBSTACLE_WIDTH), .OBSTACLE_HEIGHT(OBSTACLE_HEIGHT), .OBSTACLE_X_SPEED(OBSTACLE_X_SPEED), .Y_INITIAL_OFFSET(Y_INITIAL_OFFSET)) the_obstacle_control (
        .clk(clk),
        .rst(module_reset_signal), // Resets in Start Menu
        .game_en(active_game_en),  // Pauses when not Playing
        .collision(obsticle_collision), 
        .y_amplitude_in(rand_y_amplitude), 
        .obstacle_x_pos(obstacle_x_pos),
        .obstacle_y_pos(obstacle_y_pos),
        .obstacle_width(obstacle_width_wire),
        .obstacle_height(obstacle_height_wire)
    );
	
    collision_detector #(.PLAYER_WIDTH(PLAYER_WIDTH), .PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT), .PLAYER_Y(PLAYER_Y_START)) obsticle_collision_detector(
        .player_x(player_x_pos),
        .player_height(player_current_height),
        .obstacle_x(obstacle_x_pos),
        .obstacle_y(obstacle_y_pos),
        .obstacle_width(obstacle_width_wire),
        .obstacle_height(obstacle_height_wire),
        .collision_detected(obsticle_collision)
    );

    // Renderer now gets the GAME STATE
    vga_driver_memory #(.BOX_WIDTH(PLAYER_WIDTH), .BOX_BASE_HEIGHT(PLAYER_BASE_HEIGHT), .BOX_Y_START(PLAYER_Y_START), .BANK_X_START(BANK_X_START), .BANK_WIDTH(BANK_WIDTH)) the_renderer ( 
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
        .game_state(current_game_state), // NEW INPUT
        .VGA_R(vga_r_c),
        .VGA_G(vga_g_c),
        .VGA_B(vga_b_c)
    );

    always @(posedge clk) begin
        VGA_R <= vga_r_c;
        VGA_G <= vga_g_c;
        VGA_B <= vga_b_c;
    end

endmodule
