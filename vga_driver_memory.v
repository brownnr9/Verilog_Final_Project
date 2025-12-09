module vga_driver_memory #(
    parameter BOX_WIDTH 	= 10'd30,
    parameter BOX_BASE_HEIGHT = 10'd30,
    parameter BOX_Y_START 	= 10'd315,
    parameter BANK_X_START 	= 10'd50,
    parameter BANK_WIDTH 	= 10'd60
) (
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

    input [9:0] x,
    input [9:0] y,
    input [7:0] bank_level, 
    input active_pixels,
    input [1:0] game_state,
    input       menu_selection, 

    output reg [7:0] VGA_R,
    output reg [7:0] VGA_G,
    output reg [7:0] VGA_B
);
    // --- State Parameters ---
    parameter S_START        = 2'b00;
    parameter S_PLAYING      = 2'b01;
    parameter S_INSTRUCTIONS = 2'b10;
    parameter S_GAME_OVER    = 2'b11;

    // --- Colors ---
    parameter C_BLACK = 8'h00; 
    parameter C_WHITE = 8'hFF;
    parameter C_BLUE  = 8'hFF; 
    parameter C_RED   = 8'hFF;
    parameter C_GREEN = 8'hFF;
    parameter C_DIM   = 8'h55; 
    parameter C_GRAY  = 8'd128; // NEW: Gray Color

    // --- Text Layer Wires ---
    wire t_start, t_howto, t_score, t_hp;
    wire t_gameover, t_final_score; 
    wire i_l1, i_l2, i_grn, i_l3, i_l4, i_l5, i_l6, i_red;

    text_layer my_text (
        .x(x), .y(y),
        .start_text_on(t_start),
        .howto_title_on(t_howto),
        .score_text_on(t_score),
        .hp_text_on(t_hp),
        .instr_line1_on(i_l1),
        .instr_line2_on(i_l2), .instr_green_on(i_grn),
        .instr_line3_on(i_l3),
        .instr_line4_on(i_l4),
        .instr_line5_on(i_l5),
        .instr_line6_on(i_l6), .instr_red_on(i_red),
        .gameover_text_on(t_gameover),
        .final_score_text_on(t_final_score)
    );

    // --- Game Object Logic ---
    wire [9:0] player_y_top = BOX_Y_START - player_height + 1;
    wire is_player_rect = (x >= player_x) && (x < player_x + BOX_WIDTH) && (y >= player_y_top) && (y <= BOX_Y_START);
    
    wire is_player_holding = (player_height > BOX_BASE_HEIGHT);
    wire is_held_box_pixel = is_player_rect && (y < (BOX_Y_START - BOX_BASE_HEIGHT + 1));

    wire is_obstacle = (x >= obstacle_x) && (x < obstacle_x + obstacle_width) && (y >= obstacle_y) && (y < obstacle_y + obstacle_height);
    
    wire is_green_box = green_active && (x >= green_x) && (x < green_x + green_width) && (y >= green_y) && (y < green_y + green_height);
    
    wire is_bank = (x >= BANK_X_START) && (x < BANK_X_START + BANK_WIDTH) && (y >= (BOX_Y_START - BOX_BASE_HEIGHT + 1)) && (y <= BOX_Y_START);

    // NEW: Floor Logic (Pixels below the baseline)
    wire is_floor = (y > BOX_Y_START);

    always @(*) begin
        if (active_pixels) begin
            case (game_state)
                S_START: begin
                    if (t_start) begin
                        if (menu_selection == 1'b0) begin VGA_R=C_WHITE; VGA_G=C_WHITE; VGA_B=C_WHITE; end 
                        else begin VGA_R=C_DIM; VGA_G=C_DIM; VGA_B=C_DIM; end
                    end else if (t_howto) begin
                        if (menu_selection == 1'b1) begin VGA_R=C_WHITE; VGA_G=C_WHITE; VGA_B=C_WHITE; end 
                        else begin VGA_R=C_DIM; VGA_G=C_DIM; VGA_B=C_DIM; end
                    end else begin
                        VGA_R=8'd0; VGA_G=8'd0; VGA_B=8'd128; // Deep Blue
                    end
                end

                S_INSTRUCTIONS: begin
                    if (i_grn) begin VGA_R=C_BLACK; VGA_G=C_GREEN; VGA_B=C_BLACK; end 
                    else if (i_red) begin VGA_R=C_RED; VGA_G=C_BLACK; VGA_B=C_BLACK; end 
                    else if (i_l1 || i_l2 || i_l3 || i_l4 || i_l5 || i_l6) begin VGA_R=C_WHITE; VGA_G=C_WHITE; VGA_B=C_WHITE; end 
                    else begin VGA_R=C_BLACK; VGA_G=C_BLACK; VGA_B=C_BLACK; end
                end

                S_GAME_OVER: begin
                    if (t_gameover || t_final_score) begin
                        VGA_R = C_WHITE; VGA_G = C_WHITE; VGA_B = C_WHITE;
                    end else begin
                        VGA_R = C_RED; VGA_G = C_BLACK; VGA_B = C_BLACK;
                    end
                end

                S_PLAYING: begin
                    if (t_score || t_hp) begin 
                        VGA_R=C_BLACK; VGA_G=C_BLACK; VGA_B=C_BLACK; 
                    end else if (is_obstacle) begin 
                        VGA_R=C_RED; VGA_G=C_BLACK; VGA_B=C_BLACK; 
                    end else if (is_green_box) begin
                        VGA_R=C_BLACK; VGA_G=C_GREEN; VGA_B=C_BLACK;
                    end else if (is_player_rect) begin 
                        if (is_held_box_pixel) begin
                            VGA_R=C_BLACK; VGA_G=C_GREEN; VGA_B=C_BLACK;
                        end else begin
                            VGA_R=C_BLACK; VGA_G=C_BLACK; VGA_B=C_BLUE; 
                        end
                    end else if (is_bank) begin 
                        VGA_R=C_BLACK; VGA_G=C_GREEN; VGA_B=C_BLACK; 
                    end else if (is_floor) begin
                        VGA_R=C_GRAY; VGA_G=C_GRAY; VGA_B=C_GRAY;
                    end else begin 
                        VGA_R=C_WHITE; VGA_G=C_WHITE; VGA_B=C_WHITE; 
                    end
                end
                
                default: begin VGA_R=C_BLACK; VGA_G=C_BLACK; VGA_B=C_BLACK; end
            endcase
        end else begin
            VGA_R=C_BLACK; VGA_G=C_BLACK; VGA_B=C_BLACK;
        end
    end
endmodule