module top(
input CLOCK_50,

// KEY Inputs (Active Low)
// KEY[0] = Right / Next Option
// KEY[1] = Left / Prev Option
// KEY[2] = Select / Drop Box
// KEY[3] = Back (Instructions only)
input [3:0] KEY,

// SW[0] = Hard Reset (Active High logic on board, treated as Active Low in modules)
input [9:0] SW,

// VGA Outputs
output VGA_BLANK_N,
output reg [7:0] VGA_B,
output VGA_CLK,
output reg [7:0] VGA_G,
output VGA_HS,
output reg [7:0] VGA_R,
output VGA_SYNC_N,
output VGA_VS
);

 // --- GLOBAL GAME PARAMETERS [cite: 51] ---
// Player/Box Dimensions
parameter PLAYER_WIDTH    = 10'd30;
parameter PLAYER_BASE_HEIGHT= 10'd30;
parameter PLAYER_Y_START    = 10'd315;

// Movement Speed
parameter MOVE_STEP    = 10'd4;

    // Obstacle Parameters
    parameter OBSTACLE_WIDTH    = 10'd30;
    parameter OBSTACLE_HEIGHT   = 10'd30;
    parameter OBSTACLE_X_SPEED  = 10'd5;
    parameter Y_INITIAL_OFFSET  = 10'd50;
   
    // Bank Parameters
    parameter BANK_X_START      = 10'd50;
parameter BANK_Y_START      = 10'd315;
parameter BANK_WIDTH        = 10'd60;

// --- System Clock and Hard Reset ---
wire clk;
wire hard_rst;

assign clk = CLOCK_50;
assign hard_rst = SW[0];  // Active Low Reset for modules [cite: 61]

// --- FSM & STATE LOGIC ---
wire [1:0] current_game_state;
wire obsticle_collision; // From collision detector
wire menu_sel;           // 0=Start, 1=HowTo
   
    // Instantiate State Machine
    game_state_machine fsm (
        .clk(clk),
        .rst(hard_rst),
        .key_right(KEY[0]),  // Navigate Right
        .key_left(KEY[1]),   // Navigate Left
        .key_select(KEY[2]), // Select Option
        .key_back(KEY[3]),   // Back (from Instructions)
        .collision(obsticle_collision),
        .state(current_game_state),
        .menu_selection(menu_sel)
    );

// --- PAUSE & SOFT RESET LOGIC ---

// 1. Global Game Clock (Always runs to keep timing consistent)
wire global_game_en;

// 2. Active Game Enable: Only passes the clock pulse if state is PLAYING (2'b01)
wire active_game_en;
assign active_game_en = (current_game_state == 2'b01) ? global_game_en : 1'b0;

// 3. Module Reset Signal (Soft Reset)
// We need to reset the Player and Obstacles if:
// A. The User presses the Hard Reset Switch (SW[0] == 0)
// B. The Game is in the START MENU (current_game_state == 00).
//    This ensures that when you crash and go back to menu, the entities reset.
wire game_modules_rst;
assign game_modules_rst = (hard_rst == 1'b1) && (current_game_state != 2'b00);

// --- Internal Communication Wires ---

// VGA Timing Wires
wire [9:0] x;
wire [9:0] y;
wire active_pixels;

// Game Entity Wires
wire [9:0] player_x_pos;
    wire [9:0] obstacle_x_pos;
    wire [9:0] obstacle_y_pos;
    wire [9:0] obstacle_width_wire;
    wire [9:0] obstacle_height_wire;
wire [9:0] player_current_height;
    wire box_dropped;
    wire [7:0] bank_level;
    wire [9:0] rand_y_amplitude;

// Color Wires
wire [7:0] vga_r_color;
wire [7:0] vga_g_color;
wire [7:0] vga_b_color;


// --- 1. Game Clock Generator Instantiation ---
game_clock_generator game_clk(
.clk(clk),
.rst(hard_rst), // Timer resets on hard reset
.game_en(global_game_en)
);

// --- 2. VGA Driver Instantiation (Timing Generator) ---
vga_driver the_vga(
.clk(clk),
.rst(hard_rst), // VGA always active unless hard reset
.vga_clk(VGA_CLK),
.hsync(VGA_HS),
.vsync(VGA_VS),
.active_pixels(active_pixels),
.xPixel(x),
.yPixel(y),
.VGA_BLANK_N(VGA_BLANK_N),
.VGA_SYNC_N(VGA_SYNC_N)
);

// --- 3. Instantiate Player Control Module ---
// Uses game_modules_rst to reset position when in Menu
// Uses active_game_en to pause movement when in Menu/Instructions
player_control#(.BOX_WIDTH(PLAYER_WIDTH), .MOVE_STEP(MOVE_STEP)) the_controller(
.clk(clk),
.rst(game_modules_rst),
.game_en(active_game_en),
.buttons(KEY[1:0]), // KEY[0]=Right, KEY[1]=Left
.box_x(player_x_pos)
);

    // --- 3b. Instantiate Player Height Manager ---
    player_height_manager #(.BASE_HEIGHT(PLAYER_BASE_HEIGHT)) the_health_manager (
        .clk(clk),
        .rst(game_modules_rst),
        .game_en(active_game_en),
        .collision(obsticle_collision),
        .box_dropped_in(box_dropped),
        .current_height(player_current_height)
    );

    // --- 3c. Instantiate Bank Control Module ---
    // Uses KEY[2] for dropping boxes
    bank_control #(.PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT),
                   .BANK_X_START(BANK_X_START),
                   .BANK_WIDTH(BANK_WIDTH)) the_bank_control (
        .clk(clk),
        .rst(game_modules_rst),
        .game_en(active_game_en),
        .key_2_in(KEY[2]),
        .player_x_pos(player_x_pos),
        .player_current_height(player_current_height),
        .box_dropped(box_dropped),
        .bank_level(bank_level)
    );

    // --- 3d. Instantiate Random Generator ---
    // Uses hard_rst and global_game_en so randomness "shuffles" even while in the menu
    random_generator the_rng(
        .clk(clk),
        .rst(hard_rst),
        .game_en(global_game_en),
        .random_out(rand_y_amplitude)
    );

    // --- 4. Instantiate Obstacle Control Module ---
    obstacle_control #(.OBSTACLE_WIDTH(OBSTACLE_WIDTH),
                         .OBSTACLE_HEIGHT(OBSTACLE_HEIGHT),
                         .OBSTACLE_X_SPEED(OBSTACLE_X_SPEED),
                         .Y_INITIAL_OFFSET(Y_INITIAL_OFFSET))
    the_obstacle_control (
        .clk(clk),
        .rst(game_modules_rst), // Reset position when in Menu
        .game_en(active_game_en), // Freeze when in Menu
.collision(obsticle_collision),
        .y_amplitude_in(rand_y_amplitude),
        .obstacle_x_pos(obstacle_x_pos),
        .obstacle_y_pos(obstacle_y_pos),
        .obstacle_width(obstacle_width_wire),
        .obstacle_height(obstacle_height_wire)
    );

// --- 4b. Instantiate Collision Detector Module ---
collision_detector#(.PLAYER_WIDTH(PLAYER_WIDTH),
.PLAYER_BASE_HEIGHT(PLAYER_BASE_HEIGHT),
.PLAYER_Y(PLAYER_Y_START)) obsticle_collision_detector(
.player_x(player_x_pos),
.player_height(player_current_height),
.obstacle_x(obstacle_x_pos),
        .obstacle_y(obstacle_y_pos),
        .obstacle_width(obstacle_width_wire),
        .obstacle_height(obstacle_height_wire),
.collision_detected(obsticle_collision));

// --- 5. VGA Display Renderer Instantiation ---
// NOW includes game_state and menu_selection for text rendering
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
       
        // NEW PORTS
        .game_state(current_game_state),
        .menu_selection(menu_sel),

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