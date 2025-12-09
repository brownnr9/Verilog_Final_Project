module top(
    // Global Clock/Reset Inputs
    input CLOCK_50,
    input [3:0] KEY,      // KEY[0]=Right, KEY[1]=Left, KEY[2]=Select/Drop, KEY[3]=Back
    input [9:0] SW,       // SW[0] for Hard Reset

    // VGA Outputs (Main Interface)
    output VGA_BLANK_N,
    output reg [7:0] VGA_B,
    output VGA_CLK,
    output reg [7:0] VGA_G,
    output VGA_HS,
    output reg [7:0] VGA_R,
    output VGA_SYNC_N,
    output VGA_VS
);

    // =========================================================================
    // 1. GLOBAL PARAMETERS
    //    (These define the physical sizes and initial states of game elements)
    // =========================================================================

    // Player/Box Parameters
    parameter PLAYER_WIDTH      = 10'd30;
    parameter PLAYER_BASE_HEIGHT= 10'd30;
    parameter PLAYER_Y_START    = 10'd315; // Bottom edge of the player sprite (Ground Y is ~480)

    // Obstacle / Collectible Parameters (Now using updated/optimized values)
    parameter OBSTACLE_WIDTH    = 10'd30;
    parameter OBSTACLE_HEIGHT   = 10'd30;
    parameter OBSTACLE_X_SPEED  = 10'd5;
    parameter Y_INITIAL_OFFSET  = 10'd50; // Increased offset for higher flight path

    // Bank Parameters
    parameter BANK_X_START      = 10'd50;
    parameter BANK_WIDTH        = 10'd60;


    // =========================================================================
    // 2. PRIMARY CLOCK & RESET SIGNALS
    // =========================================================================

    wire clk = CLOCK_50;
    wire hard_rst = SW[0];

    // Core Game Clock Enable (~12 Hz for movement/updates)
    wire global_game_en;
    // Active game_en, only active if the FSM is in the S_PLAYING state (2'b01)
    wire active_game_en = (current_game_state == 2'b01) ? global_game_en : 1'b0;
    // Reset for game modules: active if hard_rst is high AND we are NOT in the START menu
    wire game_modules_rst = (hard_rst == 1'b1) && (current_game_state != 2'b00);


    // =========================================================================
    // 3. FSM & GAME STATE WIRES
    // =========================================================================

    wire [1:0] current_game_state; // Current state: Start, Playing, Instructions, Game Over
    wire menu_sel;                 // Menu selection (e.g., Start Game/Instructions)

    wire [1:0] current_hp;         // Player's remaining lives (0 to 3)
    wire obsticle_collision;       // High for one cycle if player hit an obstacle
    wire box_caught;               // High for one cycle if player caught a green box
    wire box_dropped;              // High for one cycle when a box is deposited

    // =========================================================================
    // 4. MODULE POSITION & SIZE WIRES
    // =========================================================================

    // Player Wires
    wire [9:0] player_x_pos;         // Player's X position (left edge)
    wire [9:0] player_current_height;// Player's current height (BASE + collected boxes)
    wire is_holding_max = (player_current_height >= PLAYER_BASE_HEIGHT + 10'd60); // Max boxes (2) check

    // Obstacle Wires
    wire [9:0] obstacle_x_pos, obstacle_y_pos;
    wire [9:0] obst_w, obst_h;

    // Collectible Wires
    wire [9:0] green_x_pos, green_y_pos;
    wire [9:0] green_w, green_h;
    wire green_active; // Is a collectible currently flying on screen?

    // Bank Wires
    wire [7:0] bank_level; // Current score/bank level

    // Random Number Wires
    wire [9:0] rand_y_amplitude; // Random amplitude for arc flight

    // VGA Wires
    wire [9:0] x, y;             // Current pixel coordinates
    wire active_pixels;          // High if (x,y) is within the 640x480 active area
    wire [7:0] vga_r_color, vga_g_color, vga_b_color; // Color output from the renderer


    // =========================================================================
    // 5. MODULE INSTANTIATIONS
    // =========================================================================

    // Clock Generator (50MHz -> ~12Hz game clock)
    game_clock_generator game_clk(
        .clk(clk),
        .rst(hard_rst),
        .game_en(global_game_en)
    );

    // VGA Driver (Timing, Counters)
    vga_driver the_vga(
        .clk(clk), .rst(hard_rst),
        .vga_clk(VGA_CLK), .hsync(VGA_HS), .vsync(VGA_VS),
        .active_pixels(active_pixels),
        .xPixel(x), .yPixel(y),
        .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N)
    );

    // Game State Machine (FSM for overall game flow and life tracking)
    game_state_machine fsm (
        .clk(clk), .rst(hard_rst),
        .key_right(KEY[0]), .key_left(KEY[1]), .key_select(KEY[2]), .key_back(KEY[3]),
        .collision(obsticle_collision),
        .state(current_game_state),
        .menu_selection(menu_sel),
        .current_hp(current_hp) // Output: Current lives (0-3)
    );

    // Player Controller (Horizontal movement)
    player_control #(.BOX_WIDTH(PLAYER_WIDTH), .BASE_HEIGHT(PLAYER_BASE_HEIGHT))
    the_controller (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .buttons(KEY[1:0]),
        .current_height(player_current_height),
        .box_x(player_x_pos)
    );

    // Player Height Manager (Vertical inventory/box stack)
    player_height_manager #(.BASE_HEIGHT(PLAYER_BASE_HEIGHT))
    the_height_manager (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .box_caught(box_caught),
        .box_dropped_in(box_dropped),
        .current_height(player_current_height) // Output: Player's total height
    );

    // Bank Controller (Score and box dropping logic)
    bank_control #(.PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT), .BANK_X_START(BANK_X_START), .BANK_WIDTH(BANK_WIDTH))
    the_bank_control (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .key_2_in(KEY[2]),
        .player_x_pos(player_x_pos),
        .player_current_height(player_current_height),
        .box_dropped(box_dropped), // Output: Pulse for box drop
        .bank_level(bank_level)    // Output: Total score
    );

    // Random Number Generator (for obstacle/collectible vertical amplitude)
    // NOTE: This uses the global_game_en for random changes outside of active play.
    random_generator the_rng(
        .clk(clk), .rst(hard_rst), .game_en(global_game_en),
        .random_out(rand_y_amplitude)
    );

    // Obstacle Controller (Red blocks, uses shared Y_INITIAL_OFFSET)
    obstacle_control #(.OBSTACLE_WIDTH(OBSTACLE_WIDTH), .OBSTACLE_HEIGHT(OBSTACLE_HEIGHT), .OBSTACLE_X_SPEED(OBSTACLE_X_SPEED), .Y_INITIAL_OFFSET(Y_INITIAL_OFFSET))
    the_obstacle_control (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .collision(obsticle_collision),
        .y_amplitude_in(rand_y_amplitude),
        .obstacle_x_pos(obstacle_x_pos), .obstacle_y_pos(obstacle_y_pos),
        .obstacle_width(obst_w), .obstacle_height(obst_h)
    );

    // Collectible Controller (Green boxes, uses shared Y_INITIAL_OFFSET)
    collectible_control #(.BOX_WIDTH(PLAYER_WIDTH), .BOX_HEIGHT(PLAYER_BASE_HEIGHT), .BOX_SPEED(10'd6), .Y_INITIAL_OFFSET(Y_INITIAL_OFFSET))
    the_green_box_control (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .box_caught(box_caught),
        .y_amplitude_in(rand_y_amplitude),
        .player_is_holding_box(is_holding_max),
        .box_x_pos(green_x_pos), .box_y_pos(green_y_pos),
        .box_width(green_w), .box_height(green_h),
        .active(green_active)
    );

    // Master Collision Detector
    collision_detector #(.PLAYER_WIDTH(PLAYER_WIDTH), .PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT), .PLAYER_Y(PLAYER_Y_START))
    master_collision_detector (
        .player_x(player_x_pos), .player_height(player_current_height),
        .obstacle_x(obstacle_x_pos), .obstacle_y(obstacle_y_pos),
        .obstacle_width(obst_w), .obstacle_height(obst_h),
        .green_x(green_x_pos), .green_y(green_y_pos),
        .green_width(green_w), .green_height(green_h),
        .green_active(green_active),
        .collision_detected(obsticle_collision), // Output: Collision pulse (for FSM)
        .box_caught(box_caught)                  // Output: Box catch pulse (for FSM/Height Manager)
    );

    // VGA Renderer (Combines all position data into an RGB color for the current pixel)
    vga_driver_memory #(.BOX_WIDTH(PLAYER_WIDTH), .BOX_BASE_HEIGHT(PLAYER_BASE_HEIGHT),
                        .BOX_Y_START(PLAYER_Y_START), .BANK_X_START(BANK_X_START), .BANK_WIDTH(BANK_WIDTH))
    the_renderer (
        .player_x(player_x_pos), .player_height(player_current_height),
        .obstacle_x(obstacle_x_pos), .obstacle_y(obstacle_y_pos), .obstacle_width(obst_w), .obstacle_height(obst_h),
        .green_x(green_x_pos), .green_y(green_y_pos), .green_width(green_w), .green_height(green_h), .green_active(green_active),
        .x(x), .y(y),
        .bank_level(bank_level),
        .current_hp(current_hp), // Input: Lives count for heart display
        .active_pixels(active_pixels), .game_state(current_game_state), .menu_selection(menu_sel),
        .VGA_R(vga_r_color), .VGA_G(vga_g_color), .VGA_B(vga_b_color)
    );


    // =========================================================================
    // 6. VGA OUTPUT ASSIGNMENT
    // =========================================================================

    // Register assignments to ensure stable output to the VGA connector
    always @(posedge clk) begin
        VGA_R <= vga_r_color;
        VGA_G <= vga_g_color;
        VGA_B <= vga_b_color;
    end

endmodule