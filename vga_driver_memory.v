module vga_driver_memory #(
    parameter BOX_WIDTH 	= 10'd30,
    parameter BOX_BASE_HEIGHT = 10'd30,
    parameter BOX_Y_START 	= 10'd315,
    parameter BANK_X_START 	= 10'd50,
    parameter BANK_WIDTH 	= 10'd60
) (
    input [9:0] player_x, input [9:0] player_height,
    input [9:0] obstacle_x, input [9:0] obstacle_y, input [9:0] obstacle_width, input [9:0] obstacle_height,
    input [9:0] green_x, input [9:0] green_y, input [9:0] green_width, input [9:0] green_height, input green_active,
    input [9:0] x, input [9:0] y,
    input [7:0] bank_level, 
    input [1:0] current_hp, 
    input active_pixels, input [1:0] game_state, input menu_selection, 

    output reg [7:0] VGA_R, output reg [7:0] VGA_G, output reg [7:0] VGA_B
);
    parameter S_START = 2'b00; parameter S_PLAYING = 2'b01; parameter S_INSTRUCTIONS = 2'b10; parameter S_GAME_OVER = 2'b11;
    
    // 8-bit Colors
    parameter C_BLACK = 8'h00; 
    parameter C_WHITE = 8'hFF; 
    parameter C_BLUE  = 8'hFF; 
    parameter C_RED   = 8'hFF; 
    parameter C_GREEN = 8'hFF; 
    parameter C_DIM   = 8'h55; 
    parameter C_GRAY  = 8'd128;

    wire t_start, t_howto, t_score, t_hp, t_gameover, t_final_score; 
    wire i_l1, i_l2, i_grn, i_l3, i_l4, i_l5, i_l6, i_red;
    wire t_score_num, t_hearts, t_final_score_num; // ADDED t_final_score_num

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
        .final_score_num_on(t_final_score_num) // CONNECTED
    );

    // Objects
    wire [9:0] player_y_top = BOX_Y_START - player_height + 1;
    wire is_player_rect = (x >= player_x) && (x < player_x + BOX_WIDTH) && (y >= player_y_top) && (y <= BOX_Y_START);
    wire is_held_box_pixel = is_player_rect && (y < (BOX_Y_START - BOX_BASE_HEIGHT + 1));
    wire is_obstacle = (x >= obstacle_x) && (x < obstacle_x + obstacle_width) && (y >= obstacle_y) && (y < obstacle_y + obstacle_height);
    wire is_green_box = green_active && (x >= green_x) && (x < green_x + green_width) && (y >= green_y) && (y < green_y + green_height);
    wire is_bank = (x >= BANK_X_START) && (x < BANK_X_START + BANK_WIDTH) && (y >= (BOX_Y_START - BOX_BASE_HEIGHT + 1)) && (y <= BOX_Y_START);
    wire is_floor = (y > BOX_Y_START);

    always @(*) begin
        if (active_pixels) begin
            case (game_state)
                S_START: begin
                   if (t_start) begin if (!menu_selection) {VGA_R,VGA_G,VGA_B}={C_WHITE,C_WHITE,C_WHITE}; else {VGA_R,VGA_G,VGA_B}={C_DIM,C_DIM,C_DIM}; end
                   else if (t_howto) begin if (menu_selection) {VGA_R,VGA_G,VGA_B}={C_WHITE,C_WHITE,C_WHITE}; else {VGA_R,VGA_G,VGA_B}={C_DIM,C_DIM,C_DIM}; end
                   else {VGA_R,VGA_G,VGA_B}={8'd0,8'd0,8'd128};
                end
                S_INSTRUCTIONS: begin
                    if (i_grn) {VGA_R,VGA_G,VGA_B}={C_BLACK,C_GREEN,C_BLACK};
                    else if (i_red) {VGA_R,VGA_G,VGA_B}={C_RED,C_BLACK,C_BLACK};
                    else if (i_l1||i_l2||i_l3||i_l4||i_l5||i_l6) {VGA_R,VGA_G,VGA_B}={C_WHITE,C_WHITE,C_WHITE};
                    else {VGA_R,VGA_G,VGA_B}={C_BLACK,C_BLACK,C_BLACK};
                end
                S_GAME_OVER: begin
                    // Text and Score Number are White
                    if (t_gameover || t_final_score || t_final_score_num) {VGA_R,VGA_G,VGA_B}={C_WHITE,C_WHITE,C_WHITE};
                    else {VGA_R,VGA_G,VGA_B}={C_RED,C_BLACK,C_BLACK};
                end
                S_PLAYING: begin
                    if (t_hearts) {VGA_R,VGA_G,VGA_B}={C_RED,C_BLACK,C_BLACK}; 
                    else if (t_score || t_hp || t_score_num) {VGA_R,VGA_G,VGA_B}={C_BLACK,C_BLACK,C_BLACK}; 
                    else if (is_obstacle) {VGA_R,VGA_G,VGA_B}={C_RED,C_BLACK,C_BLACK}; 
                    else if (is_green_box) {VGA_R,VGA_G,VGA_B}={C_BLACK,C_GREEN,C_BLACK};
                    else if (is_player_rect) begin 
                        if (is_held_box_pixel) {VGA_R,VGA_G,VGA_B}={C_BLACK,C_GREEN,C_BLACK};
                        else {VGA_R,VGA_G,VGA_B}={C_BLACK,C_BLACK,C_BLUE}; 
                    end
                    else if (is_bank) {VGA_R,VGA_G,VGA_B}={C_BLACK,C_GREEN,C_BLACK}; 
                    else if (is_floor) {VGA_R,VGA_G,VGA_B}={C_GRAY,C_GRAY,C_GRAY};
                    else {VGA_R,VGA_G,VGA_B}={C_WHITE,C_WHITE,C_WHITE}; 
                end
                default: {VGA_R,VGA_G,VGA_B}={C_BLACK,C_BLACK,C_BLACK};
            endcase
        end else {VGA_R,VGA_G,VGA_B}={C_BLACK,C_BLACK,C_BLACK};
    end
endmodule