module top(
    input CLOCK_50,
    input [3:0] KEY,
    input [9:0] SW,
    output VGA_BLANK_N,
    output reg [7:0] VGA_B,
    output VGA_CLK,
    output reg [7:0] VGA_G,
    output VGA_HS,
    output reg [7:0] VGA_R,
    output VGA_SYNC_N,
    output VGA_VS
);

    // --- GLOBAL PARAMETERS ---
    parameter PLAYER_WIDTH    = 10'd30;
    parameter PLAYER_BASE_HEIGHT= 10'd30;
    parameter PLAYER_Y_START    = 10'd315;
    
    // Obstacle / Box Parameters
    parameter OBSTACLE_WIDTH    = 10'd30;
    parameter OBSTACLE_HEIGHT   = 10'd30;
    parameter OBSTACLE_X_SPEED  = 10'd5;
    parameter Y_INITIAL_OFFSET  = 10'd50;
    
    parameter BANK_X_START      = 10'd50;
    parameter BANK_WIDTH        = 10'd60;

    wire clk;
    wire hard_rst;
    assign clk = CLOCK_50;
    assign hard_rst = SW[0];

    // --- FSM & STATE LOGIC ---
    wire [1:0] current_game_state;
    wire obsticle_collision; 
    wire box_caught;        
    wire menu_sel;

    game_state_machine fsm (
        .clk(clk),
        .rst(hard_rst),
        .key_right(KEY[0]),
        .key_left(KEY[1]), 
        .key_select(KEY[2]),
        .key_back(KEY[3]),
        .collision(obsticle_collision), 
        .state(current_game_state),
        .menu_selection(menu_sel)
    );

    wire global_game_en;
    wire active_game_en = (current_game_state == 2'b01) ? global_game_en : 1'b0;
    wire game_modules_rst = (hard_rst == 1'b1) && (current_game_state != 2'b00);

    // --- Wires ---
    wire [9:0] x, y;
    wire active_pixels;
    
    wire [9:0] player_x_pos;
    wire [9:0] player_current_height;
    
    // Obstacle Wires
    wire [9:0] obstacle_x_pos, obstacle_y_pos, obst_w, obst_h;
    
    // Green Box Wires
    wire [9:0] green_x_pos, green_y_pos, green_w, green_h;
    wire green_active;
    
    wire box_dropped;
    wire [7:0] bank_level;
    wire [9:0] rand_y_amplitude;
    wire [7:0] vga_r_color, vga_g_color, vga_b_color;

    // --- 1. Game Clock ---
    game_clock_generator game_clk(
        .clk(clk), .rst(hard_rst), .game_en(global_game_en)
    );

    // --- 2. VGA Driver ---
    vga_driver the_vga(
        .clk(clk), .rst(hard_rst), 
        .vga_clk(VGA_CLK), .hsync(VGA_HS), .vsync(VGA_VS),
        .active_pixels(active_pixels), .xPixel(x), .yPixel(y),
        .VGA_BLANK_N(VGA_BLANK_N), .VGA_SYNC_N(VGA_SYNC_N)
    );

    // --- 3. Player Control (UPDATED) ---
    player_control #(.BOX_WIDTH(PLAYER_WIDTH), .BASE_HEIGHT(PLAYER_BASE_HEIGHT)) the_controller(
        .clk(clk), 
        .rst(game_modules_rst), 
        .game_en(active_game_en),
        .buttons(KEY[1:0]), 
        .current_height(player_current_height), // NEW: Input for variable speed
        .box_x(player_x_pos)
    );

    // --- 3b. Player Height Manager (UPDATED) ---
    player_height_manager #(.BASE_HEIGHT(PLAYER_BASE_HEIGHT)) the_health_manager (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .box_caught(box_caught),       
        .box_dropped_in(box_dropped), 
        .current_height(player_current_height)
    );

    // --- 3c. Bank Control ---
    bank_control #(.PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT),
                   .BANK_X_START(BANK_X_START), .BANK_WIDTH(BANK_WIDTH)) the_bank_control (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .key_2_in(KEY[2]),
        .player_x_pos(player_x_pos),
        .player_current_height(player_current_height),
        .box_dropped(box_dropped),
        .bank_level(bank_level)
    );

    // --- 3d. Random Generator ---
    random_generator the_rng(
        .clk(clk), .rst(hard_rst), .game_en(global_game_en),
        .random_out(rand_y_amplitude)
    );

    // --- 4. Obstacle Control (RED) ---
    obstacle_control #(.OBSTACLE_WIDTH(OBSTACLE_WIDTH), .OBSTACLE_HEIGHT(OBSTACLE_HEIGHT),
                       .OBSTACLE_X_SPEED(OBSTACLE_X_SPEED), .Y_INITIAL_OFFSET(Y_INITIAL_OFFSET))
    the_obstacle_control (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .collision(obsticle_collision),
        .y_amplitude_in(rand_y_amplitude),
        .obstacle_x_pos(obstacle_x_pos), .obstacle_y_pos(obstacle_y_pos),
        .obstacle_width(obst_w), .obstacle_height(obst_h)
    );
    
    // --- 5. Collectible Control (GREEN) ---
    // UPDATED: is_holding_max is now true only if holding 2 boxes (Base + 60)
    wire is_holding_max = (player_current_height >= PLAYER_BASE_HEIGHT + 10'd60);

    collectible_control #(.BOX_WIDTH(PLAYER_WIDTH), .BOX_HEIGHT(PLAYER_BASE_HEIGHT),
                          .BOX_SPEED(10'd6), .Y_INITIAL_OFFSET(Y_INITIAL_OFFSET))
    the_green_box_control (
        .clk(clk), .rst(game_modules_rst), .game_en(active_game_en),
        .box_caught(box_caught),
        .y_amplitude_in(rand_y_amplitude), 
        .player_is_holding_box(is_holding_max), // Only stop spawning if FULL (2 boxes)
        .box_x_pos(green_x_pos), .box_y_pos(green_y_pos),
        .box_width(green_w), .box_height(green_h),
        .active(green_active)
    );

    // --- 6. Collision Detector ---
    collision_detector #(.PLAYER_WIDTH(PLAYER_WIDTH), .PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT), .PLAYER_Y(PLAYER_Y_START)) 
    master_collision_detector (
        .player_x(player_x_pos), .player_height(player_current_height),
        .obstacle_x(obstacle_x_pos), .obstacle_y(obstacle_y_pos),
        .obstacle_width(obst_w), .obstacle_height(obst_h),
        .green_x(green_x_pos), .green_y(green_y_pos),
        .green_width(green_w), .green_height(green_h),
        .green_active(green_active),
        .collision_detected(obsticle_collision), 
        .box_caught(box_caught)                  
    );

    // --- 7. Renderer ---
    vga_driver_memory #(.BOX_WIDTH(PLAYER_WIDTH), .BOX_BASE_HEIGHT(PLAYER_BASE_HEIGHT),
                        .BOX_Y_START(PLAYER_Y_START), .BANK_X_START(BANK_X_START), .BANK_WIDTH(BANK_WIDTH)) 
    the_renderer (
        .player_x(player_x_pos), .player_height(player_current_height),
        .obstacle_x(obstacle_x_pos), .obstacle_y(obstacle_y_pos),
        .obstacle_width(obst_w), .obstacle_height(obst_h),
        .green_x(green_x_pos), .green_y(green_y_pos),
        .green_width(green_w), .green_height(green_h),
        .green_active(green_active),
        .x(x), .y(y), .bank_level(bank_level),
        .active_pixels(active_pixels),
        .game_state(current_game_state),
        .menu_selection(menu_sel),
        .VGA_R(vga_r_color), .VGA_G(vga_g_color), .VGA_B(vga_b_color)
    );

    always @(posedge clk) begin
        VGA_R <= vga_r_color;
        VGA_G <= vga_g_color;
        VGA_B <= vga_b_color;
    end

endmodule