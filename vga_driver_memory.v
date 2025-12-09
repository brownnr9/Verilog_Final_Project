module vga_driver_memory #(
    // =========================================================================
    // 1. MODULE PARAMETERS (Sizes and Positions)
    // =========================================================================
    parameter BOX_WIDTH         = 10'd30,
    parameter BOX_BASE_HEIGHT   = 10'd30,
    parameter BOX_Y_START       = 10'd315, // The bottom Y-coordinate of the player/floor surface
    parameter BANK_X_START      = 10'd50,
    parameter BANK_WIDTH        = 10'd60
) (
    // =========================================================================
    // 2. INPUTS
    // =========================================================================
    // Object Positions and Sizes
    input [9:0] player_x, 
    input [9:0] player_height,
    input [9:0] obstacle_x, 
    input [9:0] obstacle_y, 
    input [9:0] obstacle_width, 
    input [9:0] obstacle_height,
    input [9:0] green_x, 
    input [9:0] green_y, 
    input [9:0] green_width, 
    input [9:0] green_height, 
    input       green_active,

    // VGA Pixel Coordinates and Status
    input [9:0] x, 
    input [9:0] y,
    input       active_pixels, // High when inside 640x480 active display area
    
    // Game State Inputs
    input [7:0] bank_level,     // Current score for display
    input [1:0] current_hp,     // Current lives for heart display
    input [1:0] game_state,     // Game FSM state
    input       menu_selection, // Menu highlight select (0 or 1)
    
    // =========================================================================
    // 3. OUTPUTS
    // =========================================================================
    output reg [7:0] VGA_R, 
    output reg [7:0] VGA_G, 
    output reg [7:0] VGA_B
);

    // =========================================================================
    // 4. LOCAL PARAMETERS
    // =========================================================================
    // FSM State Definitions
    parameter S_START        = 2'b00; 
    parameter S_PLAYING      = 2'b01; 
    parameter S_INSTRUCTIONS = 2'b10; 
    parameter S_GAME_OVER    = 2'b11;
    
    // 8-bit Color Definitions (R=8'hFF, G=8'hFF, B=8'hFF)
    parameter C_BLACK = 8'h00;  // 0, 0, 0
    parameter C_WHITE = 8'hFF;  // 255, 255, 255
    parameter C_BLUE  = 8'hFF;  // 0, 0, 255 (used for the base player sprite)
    parameter C_RED   = 8'hFF;  // 255, 0, 0 (used for obstacles)
    parameter C_GREEN = 8'hFF;  // 0, 255, 0 (used for collectibles/bank)
    parameter C_DIM   = 8'h55;  // (~85) for unselected menu items
    parameter C_GRAY  = 8'd128; // (~128) for the floor

    // =========================================================================
    // 5. TEXT LAYER Wires (Inputs from text_layer module)
    // =========================================================================
    // Menu/Game Over Text
    wire t_start, t_howto, t_gameover, t_final_score;
    
    // In-Game HUD Text & Numbers
    wire t_score, t_hp, t_score_num, t_hearts;
    
    // Instructions Text & Highlighted Boxes
    wire i_l1, i_l2, i_grn, i_l3, i_l4, i_l5, i_l6, i_red;
    
    // Game Over Score
    wire t_final_score_num; // Final score number display

    // Instantiate Text Layer Module
    text_layer my_text (
        .x(x), .y(y),
        .score_val(bank_level), .lives(current_hp),
        .start_text_on(t_start), .howto_title_on(t_howto),
        .score_text_on(t_score), .score_num_on(t_score_num),
        .hp_text_on(t_hp), .hearts_on(t_hearts),
        .instr_line1_on(i_l1), .instr_line2_on(i_l2), .instr_green_on(i_grn),
        .instr_line3_on(i_l3), .instr_line4_on(i_l4), .instr_line5_on(i_l5),
        .instr_line6_on(i_l6), .instr_red_on(i_red),
        .gameover_text_on(t_gameover),
        .final_score_text_on(t_final_score),
        .final_score_num_on(t_final_score_num)
    );

    // =========================================================================
    // 6. GEOMETRY CHECKS (Combinational Logic)
    // =========================================================================
    
    // Player Geometry
    wire [9:0] player_y_top = BOX_Y_START - player_height + 1; // Top Y-coord of the player stack
    wire is_player_rect = (x >= player_x) && (x < player_x + BOX_WIDTH) && 
                          (y >= player_y_top) && (y <= BOX_Y_START);
    // Held box pixels are any pixels in the player rectangle above the base height
    wire is_held_box_pixel = is_player_rect && (y < (BOX_Y_START - BOX_BASE_HEIGHT + 1)); 

    // Obstacle Geometry
    wire is_obstacle = (x >= obstacle_x) && (x < obstacle_x + obstacle_width) && 
                       (y >= obstacle_y) && (y < obstacle_y + obstacle_height);

    // Green Box (Collectible) Geometry
    wire is_green_box = green_active && 
                        (x >= green_x) && (x < green_x + green_width) && 
                        (y >= green_y) && (y < green_y + green_height);

    // Bank (Deposit Zone) Geometry
    wire is_bank = (x >= BANK_X_START) && (x < BANK_X_START + BANK_WIDTH) && 
                   (y >= (BOX_Y_START - BOX_BASE_HEIGHT + 1)) && (y <= BOX_Y_START);

    // Floor Geometry (everything below the base line of the player)
    wire is_floor = (y > BOX_Y_START);


    // =========================================================================
    // 7. RENDERING LOGIC (Color Prioritization)
    // =========================================================================

    // This block determines the pixel color based on the current game state
    // and which object/text occupies the pixel (x, y).
    always @(*) begin
        // Default color for outside active VGA area
        if (!active_pixels) begin
            {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_BLACK, C_BLACK};
        end else begin
            case (game_state)
                S_START: begin
                    // Priority: Selection highlight over background
                    if (t_start) begin 
                        if (!menu_selection) 
                            {VGA_R, VGA_G, VGA_B} = {C_WHITE, C_WHITE, C_WHITE}; // Highlighted: Start Game
                        else 
                            {VGA_R, VGA_G, VGA_B} = {C_DIM, C_DIM, C_DIM};     // Unselected: Instructions
                    end
                    else if (t_howto) begin 
                        if (menu_selection) 
                            {VGA_R, VGA_G, VGA_B} = {C_WHITE, C_WHITE, C_WHITE}; // Highlighted: Instructions
                        else 
                            {VGA_R, VGA_G, VGA_B} = {C_DIM, C_DIM, C_DIM};     // Unselected: Start Game
                    end
                    // Default Background: Dark Blue
                    else {VGA_R, VGA_G, VGA_B} = {8'd0, 8'd0, 8'd128};
                end

                S_INSTRUCTIONS: begin
                    // Priority: Special instruction colors over general text
                    if (i_grn) 
                        {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_GREEN, C_BLACK}; // Green Box mention
                    else if (i_red) 
                        {VGA_R, VGA_G, VGA_B} = {C_RED, C_BLACK, C_BLACK};   // Red Obstacle mention
                    else if (i_l1||i_l2||i_l3||i_l4||i_l5||i_l6) 
                        {VGA_R, VGA_G, VGA_B} = {C_WHITE, C_WHITE, C_WHITE}; // General white text
                    // Default Background: Black
                    else {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_BLACK, C_BLACK};
                end

                S_GAME_OVER: begin
                    // Priority: Text over background
                    if (t_gameover || t_final_score || t_final_score_num) 
                        {VGA_R, VGA_G, VGA_B} = {C_WHITE, C_WHITE, C_WHITE}; // White Text/Score
                    // Default Background: Solid Red
                    else {VGA_R, VGA_G, VGA_B} = {C_RED, C_BLACK, C_BLACK};
                end

                S_PLAYING: begin
                    // Rendering Priority (Highest to Lowest):
                    
                    // 1. Text/HUD (Hearts, Score text, Score number, HP text)
                    if (t_hearts) 
                        {VGA_R, VGA_G, VGA_B} = {C_RED, C_BLACK, C_BLACK};           // Red Hearts
                    else if (t_score || t_hp || t_score_num) 
                        {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_BLACK, C_BLACK};         // Black Text/Numbers (for contrast)

                    // 2. Obstacles (Red)
                    else if (is_obstacle) 
                        {VGA_R, VGA_G, VGA_B} = {C_RED, C_BLACK, C_BLACK};

                    // 3. Green Box Collectibles
                    else if (is_green_box) 
                        {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_GREEN, C_BLACK};

                    // 4. Player (Held boxes are green, base player is blue)
                    else if (is_player_rect) begin
                        if (is_held_box_pixel) 
                            {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_GREEN, C_BLACK};     // Green Held Box
                        else 
                            {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_BLACK, C_BLUE};      // Blue Base Player
                    end

                    // 5. Bank/Deposit Zone (Aligned with player base)
                    else if (is_bank) 
                        {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_GREEN, C_BLACK};

                    // 6. Floor
                    else if (is_floor) 
                        {VGA_R, VGA_G, VGA_B} = {C_GRAY, C_GRAY, C_GRAY};

                    // 7. Sky/Background
                    else 
                        {VGA_R, VGA_G, VGA_B} = {C_WHITE, C_WHITE, C_WHITE};
                end

                // Default Failsafe Background
                default: {VGA_R, VGA_G, VGA_B} = {C_BLACK, C_BLACK, C_BLACK};
            endcase
        end
    end
endmodule