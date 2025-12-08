module vga_driver_memory #(
    parameter BOX_WIDTH 	= 10'd30,
    parameter BOX_BASE_HEIGHT = 10'd30,
    parameter BOX_Y_START 	= 10'd345,
    parameter BANK_X_START 	= 10'd50,
    parameter BANK_WIDTH 	= 10'd60
) (
    // Inputs from Control Modules
    input [9:0] player_x,
    input [9:0] player_height, 
    input [9:0] obstacle_x,
    input [9:0] obstacle_y,
    input [9:0] obstacle_width,
    input [9:0] obstacle_height,
    
    // Inputs from VGA Timing Module
    input [9:0] x,
    input [9:0] y,
    input [7:0] bank_level, 
    input active_pixels,
    
    // Game State Input
    input [1:0] game_state,

    // Outputs
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
    parameter C_YELLOW= 8'hFF;

    // --- TEXT LAYER INSTANTIATION ---
    wire txt_start, txt_howto, txt_score, txt_hp;
    
    text_layer my_text (
        .x(x),
        .y(y),
        .start_text_on(txt_start),
        .howto_text_on(txt_howto),
        .score_text_on(txt_score),
        .hp_text_on(txt_hp)
    );

    // --- Game Object Logic ---
    wire [9:0] player_y_top = BOX_Y_START - player_height + 1;
    wire is_player = (x >= player_x) && (x < player_x + BOX_WIDTH) && (y >= player_y_top) && (y <= BOX_Y_START); 
    wire is_obstacle = (x >= obstacle_x) && (x < obstacle_x + obstacle_width) && (y >= obstacle_y) && (y < obstacle_y + obstacle_height);
    wire is_bank = (x >= BANK_X_START) && (x < BANK_X_START + BANK_WIDTH) && (y >= (BOX_Y_START - BOX_BASE_HEIGHT + 1)) && (y <= BOX_Y_START);
    
    // Visual Helper: Instructions Lines (still used for the Instruction state)
    wire is_instr_line = (x > 200 && x < 440) && ((y % 40) > 35);
    // Visual Helper: Game Over X
    wire is_dead_x = (x == y + 80) || (x == 640 - y + 80);

    always @(*) begin
        if (active_pixels) begin
            case (game_state)
                S_START: begin
                    // Priority 1: Text
                    if (txt_start || txt_howto) begin
                        VGA_R = C_WHITE; VGA_G = C_WHITE; VGA_B = C_WHITE;
                    end else begin
                        // Background: Deep Blue
                        VGA_R = 8'd0; VGA_G = 8'd0; VGA_B = 8'd128;
                    end
                end

                S_INSTRUCTIONS: begin
                    if (is_instr_line) begin
                        VGA_R = C_WHITE; VGA_G = C_WHITE; VGA_B = C_WHITE;
                    end else begin
                        VGA_R = C_BLACK; VGA_G = C_GREEN; VGA_B = C_BLACK;
                    end
                end

                S_GAME_OVER: begin
                    if (is_dead_x) begin
                        VGA_R = C_BLACK; VGA_G = C_BLACK; VGA_B = C_BLACK;
                    end else begin
                        VGA_R = C_RED; VGA_G = C_BLACK; VGA_B = C_BLACK;
                    end
                end

                S_PLAYING: begin
                    // Priority 1: HUD Text
                    if (txt_score || txt_hp) begin
                         VGA_R = C_BLACK; VGA_G = C_BLACK; VGA_B = C_BLACK; // Text Color
                    end
                    // Priority 2: Obstacles
                    else if (is_obstacle) begin
                        VGA_R = C_RED; VGA_G = C_BLACK; VGA_B = C_BLACK;
                    end 
                    // Priority 3: Player
                    else if (is_player) begin
                        VGA_R = C_BLACK; VGA_G = C_BLACK; VGA_B = C_BLUE; 
                    end 
                    // Priority 4: Bank
                    else if (is_bank) begin
                        VGA_R = C_BLACK; VGA_G = C_GREEN; VGA_B = C_BLACK;
                    end 
                    // Background
                    else begin
                        VGA_R = C_WHITE; VGA_G = C_WHITE; VGA_B = C_WHITE;
                    end
                end
                
                default: begin 
                    VGA_R = C_BLACK; VGA_G = C_BLACK; VGA_B = C_BLACK;
                end
            endcase
        end else begin
            VGA_R = C_BLACK; VGA_G = C_BLACK; VGA_B = C_BLACK;
        end
    end

endmodule
