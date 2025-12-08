module text_layer (
    input [9:0] x,
    input [9:0] y,
    
    output start_text_on,    // High if pixel is part of "START"
    output howto_text_on,    // High if pixel is part of "HOW TO PLAY"
    output score_text_on,    // High if pixel is part of "SCORE"
    output hp_text_on        // High if pixel is part of "HP"
);

    // --- Helper Function: 5x5 Font Bitmaps ---
    // Returns 1 if the pixel at (col, row) is on for the given character
    function is_pixel_on;
        input [4:0] char_code; // A=1, B=2, etc... 
        input [2:0] col;       // 0-4
        input [2:0] row;       // 0-4
        reg [24:0] bitmap;     // 5x5 = 25 bits
        begin
            case (char_code)
                // S (Code 1)
                5'd1: bitmap = 25'b01110_10000_01110_00001_11110;
                // T (Code 2)
                5'd2: bitmap = 25'b11111_00100_00100_00100_00100;
                // A (Code 3)
                5'd3: bitmap = 25'b00100_01010_11111_10001_10001;
                // R (Code 4)
                5'd4: bitmap = 25'b11110_10001_11110_10010_10001;
                // H (Code 5)
                5'd5: bitmap = 25'b10001_10001_11111_10001_10001;
                // O (Code 6)
                5'd6: bitmap = 25'b01110_10001_10001_10001_01110;
                // W (Code 7)
                5'd7: bitmap = 25'b10001_10001_10101_10101_01010;
                // P (Code 8)
                5'd8: bitmap = 25'b11110_10001_11110_10000_10000;
                // L (Code 9)
                5'd9: bitmap = 25'b10000_10000_10000_10000_11111;
                // Y (Code 10)
                5'd10: bitmap = 25'b10001_10001_01010_00100_00100;
                // C (Code 11)
                5'd11: bitmap = 25'b01110_10000_10000_10000_01110;
                // E (Code 12)
                5'd12: bitmap = 25'b11111_10000_11110_10000_11111;
                default: bitmap = 25'b00000_00000_00000_00000_00000;
            endcase
            // Map the 1D bitmap to the 2D col/row (Row 0 is top)
            is_pixel_on = bitmap[24 - (row * 5 + col)];
        end
    endfunction

    // --- Configuration ---
    parameter SCALE = 10'd4;      // Size multiplier
    parameter CHAR_W = 10'd5;     // Base width
    parameter CHAR_H = 10'd5;     // Base height
    parameter SPACING = 10'd2;    // Space between letters

    // --- Logic for "START" ---
    // Position: Center (~250, 200)
    parameter START_X = 10'd250;
    parameter START_Y = 10'd200;
    
    wire [9:0] rel_x_s = (x >= START_X) ? (x - START_X) / SCALE : 10'd0;
    wire [9:0] rel_y_s = (y >= START_Y) ? (y - START_Y) / SCALE : 10'd0;
    
    // Determine which letter index (0 to 4) we are in
    wire [9:0] letter_idx_s = rel_x_s / (CHAR_W + SPACING);
    wire [9:0] col_in_char_s = rel_x_s % (CHAR_W + SPACING);
    
    // Bounds check
    wire in_start_box = (x >= START_X) && (rel_x_s < 5 * (CHAR_W + SPACING)) && (y >= START_Y) && (rel_y_s < CHAR_H) && (col_in_char_s < CHAR_W);
    
    reg [4:0] char_code_start;
    always @(*) begin
        case(letter_idx_s)
            0: char_code_start = 5'd1; // S
            1: char_code_start = 5'd2; // T
            2: char_code_start = 5'd3; // A
            3: char_code_start = 5'd4; // R
            4: char_code_start = 5'd2; // T
            default: char_code_start = 5'd0;
        endcase
    end
    assign start_text_on = in_start_box && is_pixel_on(char_code_start, col_in_char_s[2:0], rel_y_s[2:0]);

    // --- Logic for "HOW TO PLAY" ---
    // Position: Below Start (~210, 260)
    parameter HOW_X = 10'd180;
    parameter HOW_Y = 10'd260;
    
    wire [9:0] rel_x_h = (x >= HOW_X) ? (x - HOW_X) / SCALE : 10'd0;
    wire [9:0] rel_y_h = (y >= HOW_Y) ? (y - HOW_Y) / SCALE : 10'd0;
    wire [9:0] letter_idx_h = rel_x_h / (CHAR_W + SPACING);
    wire [9:0] col_in_char_h = rel_x_h % (CHAR_W + SPACING);
    
    // 11 Characters (H O W _ T O _ P L A Y)
    wire in_how_box = (x >= HOW_X) && (rel_x_h < 11 * (CHAR_W + SPACING)) && (y >= HOW_Y) && (rel_y_h < CHAR_H) && (col_in_char_h < CHAR_W);

    reg [4:0] char_code_how;
    always @(*) begin
        case(letter_idx_h)
            0: char_code_how = 5'd5; // H
            1: char_code_how = 5'd6; // O
            2: char_code_how = 5'd7; // W
            3: char_code_how = 5'd0; // Space
            4: char_code_how = 5'd2; // T
            5: char_code_how = 5'd6; // O
            6: char_code_how = 5'd0; // Space
            7: char_code_how = 5'd8; // P
            8: char_code_how = 5'd9; // L
            9: char_code_how = 5'd3; // A
            10: char_code_how= 5'd10; // Y
            default: char_code_how = 5'd0;
        endcase
    end
    assign howto_text_on = in_how_box && is_pixel_on(char_code_how, col_in_char_h[2:0], rel_y_h[2:0]);

    // --- Logic for "SCORE" (Top Left) ---
    parameter HUD_SCALE = 10'd2;
    parameter SCORE_X = 10'd10;
    parameter SCORE_Y = 10'd10;
    
    wire [9:0] rel_x_sc = (x >= SCORE_X) ? (x - SCORE_X) / HUD_SCALE : 10'd0;
    wire [9:0] rel_y_sc = (y >= SCORE_Y) ? (y - SCORE_Y) / HUD_SCALE : 10'd0;
    wire [9:0] letter_idx_sc = rel_x_sc / (CHAR_W + SPACING);
    wire [9:0] col_in_char_sc = rel_x_sc % (CHAR_W + SPACING);
    wire in_score_box = (x >= SCORE_X) && (rel_x_sc < 5 * (CHAR_W + SPACING)) && (y >= SCORE_Y) && (rel_y_sc < CHAR_H) && (col_in_char_sc < CHAR_W);

    reg [4:0] char_code_score;
    always @(*) begin
        case(letter_idx_sc)
            0: char_code_score = 5'd1;  // S
            1: char_code_score = 5'd11; // C
            2: char_code_score = 5'd6;  // O
            3: char_code_score = 5'd4;  // R
            4: char_code_score = 5'd12; // E
            default: char_code_score = 5'd0;
        endcase
    end
    assign score_text_on = in_score_box && is_pixel_on(char_code_score, col_in_char_sc[2:0], rel_y_sc[2:0]);

    // --- Logic for "HP" (Below Score) ---
    parameter HP_X = 10'd10;
    parameter HP_Y = 10'd40;
    
    wire [9:0] rel_x_hp = (x >= HP_X) ? (x - HP_X) / HUD_SCALE : 10'd0;
    wire [9:0] rel_y_hp = (y >= HP_Y) ? (y - HP_Y) / HUD_SCALE : 10'd0;
    wire [9:0] letter_idx_hp = rel_x_hp / (CHAR_W + SPACING);
    wire [9:0] col_in_char_hp = rel_x_hp % (CHAR_W + SPACING);
    wire in_hp_box = (x >= HP_X) && (rel_x_hp < 2 * (CHAR_W + SPACING)) && (y >= HP_Y) && (rel_y_hp < CHAR_H) && (col_in_char_hp < CHAR_W);

    reg [4:0] char_code_hp;
    always @(*) begin
        case(letter_idx_hp)
            0: char_code_hp = 5'd5; // H
            1: char_code_hp = 5'd8; // P
            default: char_code_hp = 5'd0;
        endcase
    end
    assign hp_text_on = in_hp_box && is_pixel_on(char_code_hp, col_in_char_hp[2:0], rel_y_hp[2:0]);

endmodule
