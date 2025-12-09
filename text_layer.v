module text_layer (
    // =========================================================================
    // 1. INPUTS
    // =========================================================================
    input [9:0] x,
    input [9:0] y,
    input [7:0] score_val,
    input [1:0] lives, // Input from FSM (0-3)
    
    // =========================================================================
    // 2. OUTPUTS
    // =========================================================================
    // Menu & Game Over Text
    output start_text_on,
    output howto_title_on,
    output gameover_text_on, 
    output final_score_text_on, 
    output final_score_num_on,

    // In-Game HUD
    output score_text_on,
    output score_num_on,
    output hp_text_on,
    output hearts_on,        // Output for Heart Graphic

    // Instructions Screen Text (Line/Highlight)
    output instr_line1_on, 
    output instr_line2_on, 
    output instr_green_on,
    output instr_line3_on, 
    output instr_line4_on, 
    output instr_line5_on,
    output instr_line6_on, 
    output instr_red_on
);

    // =========================================================================
    // 3. CONFIGURATION PARAMETERS
    // =========================================================================
    parameter SCALE_LG    = 10'd4; // Large text scale (e.g., 5x5 font -> 20x20 pixels)
    parameter SCALE_MD    = 10'd2; // Medium text scale (e.g., 5x5 font -> 10x10 pixels)
    parameter CHAR_W      = 10'd5; // Font width (5 pixels)
    parameter SPACING     = 10'd2; // Spacing between characters (2 pixels)
    parameter CHAR_SLOT   = CHAR_W + SPACING; // Total pixels per character slot (7 pixels)

    // Instruction Screen Layout
    parameter INST_X        = 10'd50;
    parameter INST_Y_START  = 10'd100;
    parameter LINE_H        = 10'd40; // Vertical spacing between instruction lines
    parameter CHAR_SLOT_LG  = 10'd7; // Total width for a large character slot (5*4 + 2*4) is 28, but the division uses CHAR_SLOT=7. (7*4=28)


    // =========================================================================
    // 4. FONT BITMAP FUNCTION (5x5 Font)
    // =========================================================================
    function is_pixel_on;
        input [5:0] char_code;  // Character code mapping
        input [2:0] col;        // Column within the 7-pixel slot (0-6)
        input [2:0] row;        // Row within the scaled character height (0-4)
        reg [24:0] bitmap;
        begin
            // Check if the current pixel is within the 5x5 font area
            if (col > 3'd4 || row > 3'd4) is_pixel_on = 1'b0;
            else begin
                case (char_code)
                    // Letters (1-23)
                    6'd1: bitmap = 25'b01110_10001_10001_10001_01110; // O
                    6'd2: bitmap = 25'b11111_00100_00100_00100_00100; // T
                    6'd3: bitmap = 25'b00100_01010_11111_10001_10001; // A
                    6'd4: bitmap = 25'b11110_10001_11110_10010_10001; // R
                    6'd5: bitmap = 25'b10001_10001_11111_10001_10001; // H
                    6'd6: bitmap = 25'b11110_10001_11110_10000_10000; // P
                    6'd7: bitmap = 25'b10000_10000_10000_10000_11111; // L
                    6'd8: bitmap = 25'b10001_10001_01010_00100_00100; // Y
                    6'd9: bitmap = 25'b01110_10000_01110_00001_11110; // S
                    6'd10: bitmap = 25'b01110_10000_10000_10000_01110; // C
                    6'd11: bitmap = 25'b11111_10000_11110_10000_11111; // E
                    6'd12: bitmap = 25'b10001_10001_10101_10101_01010; // W
                    6'd13: bitmap = 25'b11110_10001_11110_10001_11110; // B
                    6'd14: bitmap = 25'b11110_10001_10001_10001_11110; // D
                    6'd15: bitmap = 25'b11111_10000_11100_10000_10000; // F
                    6'd16: bitmap = 25'b01111_10000_10111_10001_01110; // G
                    6'd17: bitmap = 25'b01110_00100_00100_00100_01110; // I
                    6'd18: bitmap = 25'b00111_00010_00010_10010_01100; // J
                    6'd19: bitmap = 25'b10001_10010_11100_10010_10001; // K
                    6'd20: bitmap = 25'b10001_11011_10101_10001_10001; // M
                    6'd21: bitmap = 25'b10001_11001_10101_10011_10001; // N
                    6'd22: bitmap = 25'b10001_10001_10001_10001_01110; // U
                    6'd23: bitmap = 25'b10001_10001_10001_01010_00100; // V
                    
                    // Symbols (24-26)
                    6'd24: bitmap = 25'b00100_00100_00100_00000_00100; // !
                    6'd25: bitmap = 25'b00000_00000_00000_00000_00100; // .
                    6'd26: bitmap = 25'b00000_00100_00000_00100_00000; // :
                    
                    // Numbers (30-39)
                    6'd30: bitmap = 25'b01110_10001_10001_10001_01110; // 0
                    6'd31: bitmap = 25'b00100_01100_00100_00100_01110; // 1
                    6'd32: bitmap = 25'b01110_10001_00010_00100_11111; // 2
                    6'd33: bitmap = 25'b01110_10001_00110_10001_01110; // 3
                    6'd34: bitmap = 25'b10001_10001_11111_00010_00010; // 4
                    6'd35: bitmap = 25'b11111_10000_11110_00001_11110; // 5
                    6'd36: bitmap = 25'b01110_10000_11110_10001_01110; // 6
                    6'd37: bitmap = 25'b11111_00010_00010_00100_00100; // 7
                    6'd38: bitmap = 25'b01110_10001_01110_10001_01110; // 8
                    6'd39: bitmap = 25'b01110_10001_01111_00001_01110; // 9
                    
                    default: bitmap = 25'b00000_00000_00000_00000_00000; // Blank/Space
                endcase
                // Map the 5x5 bitmap to the current pixel (row major: row*5 + col)
                is_pixel_on = bitmap[24 - (row * 5 + col)];
            end
        end
    endfunction

    // =========================================================================
    // 5. HUD: LIVES (HP & HEARTS) - Scale_MD (2x)
    // =========================================================================
    
    // "HP" Text (Starts at X=10, Y=40)
    wire [9:0] x_hp = (x >= 10) ? (x - 10)/SCALE_MD : 0;
    wire [9:0] y_hp = (y >= 40) ? (y - 40)/SCALE_MD : 0;
    wire [9:0] idx_hp = x_hp / CHAR_SLOT;
    wire in_hp = (x >= 10 && x < 10 + 2*CHAR_SLOT*SCALE_MD && y >= 40 && y < 40 + CHAR_W*SCALE_MD);
    
    // Characters: 'H' (5), 'P' (6)
    reg [5:0] c_hp;
    always @(*) case(idx_hp) 0: c_hp=5; 1: c_hp=6; default: c_hp=0; endcase
    assign hp_text_on = in_hp && is_pixel_on(c_hp, x_hp%CHAR_SLOT, y_hp);

    // Heart Graphics (Starts at X=50, Y=40)
    wire [9:0] x_hrt = (x >= 50) ? (x - 50)/SCALE_MD : 0;
    wire [9:0] y_hrt = (y >= 40) ? (y - 40)/SCALE_MD : 0;
    wire [9:0] idx_hrt = x_hrt / CHAR_SLOT;
    wire in_hrt = (x >= 50 && x < 50 + 3*CHAR_SLOT*SCALE_MD && y >= 40 && y < 40 + CHAR_W*SCALE_MD);
    
    // Heart Bitmap: 01010_11111_11111_01110_00100 (Hardcoded)
    reg heart_pixel;
    reg [24:0] heart_bmp;
    always @(*) begin
        heart_bmp = 25'b01010_11111_11111_01110_00100;
        // Check bounds (0-4 for col/row) and calculate pixel
        if (x_hrt%CHAR_SLOT < CHAR_W && y_hrt < CHAR_W)
            heart_pixel = heart_bmp[24 - (y_hrt * 5 + (x_hrt%CHAR_SLOT))];
        else
            heart_pixel = 1'b0;
    end

    // The heart pixel is drawn if it's within bounds AND the heart index is less than current_hp
    assign hearts_on = in_hrt && (idx_hrt < lives) && heart_pixel;

    // =========================================================================
    // 6. HUD: SCORE (Top Left) - Scale_MD (2x)
    // =========================================================================
    
    // Score Value Breakdown
    wire [3:0] hundreds = score_val / 100;
    wire [3:0] tens     = (score_val % 100) / 10;
    wire [3:0] ones     = score_val % 10;

    // "SCORE" Text (Starts at X=10, Y=10)
    wire [9:0] x_sc = (x >= 10) ? (x - 10)/SCALE_MD : 0;
    wire [9:0] y_sc = (y >= 10) ? (y - 10)/SCALE_MD : 0;
    wire [9:0] idx_sc = x_sc / CHAR_SLOT;
    wire in_score = (x >= 10 && x < 10 + 6*CHAR_SLOT*SCALE_MD && y >= 10 && y < 10 + CHAR_W*SCALE_MD);
    
    // Characters: 'S' (9), 'C' (10), 'O' (1), 'R' (4), 'E' (11), ':' (26)
    reg [5:0] c_sc;
    always @(*) case(idx_sc) 
        0:c_sc=9; 1:c_sc=10; 2:c_sc=1; 3:c_sc=4; 4:c_sc=11; 5:c_sc=26; 
        default:c_sc=0; 
    endcase
    assign score_text_on = in_score && is_pixel_on(c_sc, x_sc%CHAR_SLOT, y_sc);

    // Score Number (3 digits, Starts at X=90, Y=10)
    wire [9:0] x_num = (x >= 90) ? (x - 90)/SCALE_MD : 0;
    wire [9:0] idx_num = x_num / CHAR_SLOT;
    wire in_num = (x >= 90 && x < 90 + 3*CHAR_SLOT*SCALE_MD && y >= 10 && y < 20);
    
    reg [5:0] c_num;
    always @(*) case(idx_num) 
        0:c_num=30+hundreds; 1:c_num=30+tens; 2:c_num=30+ones; 
        default:c_num=0; 
    endcase
    assign score_num_on = in_num && is_pixel_on(c_num, x_num%CHAR_SLOT, y_sc);


    // =========================================================================
    // 7. GAME STATE TEXTS - Scale_LG (4x)
    // =========================================================================
    
    // Game Over Text: "GAME OVER!" (Starts at X=180, Y=200)
    wire [9:0] x_go = (x >= 180) ? (x - 180)/SCALE_LG : 0; 
    wire [9:0] y_go = (y >= 200) ? (y - 200)/SCALE_LG : 0; 
    wire [9:0] idx_go = x_go / CHAR_SLOT; 
    // Boundary check for 10 characters * CHAR_SLOT * SCALE_LG (10*7*4 = 280 pixels width)
    wire in_go = (x >= 180 && x < 180 + 10*CHAR_SLOT*SCALE_LG && y >= 200 && y < 200 + CHAR_W*SCALE_LG); 
    
    reg [5:0] c_go; 
    always @(*) case(idx_go) 
        0: c_go=16; 1: c_go=3; 2: c_go=20; 3: c_go=11; // G A M E
        5: c_go=1; 6: c_go=23; 7: c_go=11; 8: c_go=4; // O V E R
        9: c_go=24; // !
        default: c_go=0; 
    endcase 
    assign gameover_text_on = in_go && is_pixel_on(c_go, x_go%CHAR_SLOT, y_go);

    // Final Score Text: "SCORE: " (Starts at X=180, Y=260)
    wire [9:0] x_fsc = (x >= 180) ? (x - 180)/SCALE_LG : 0;
    wire [9:0] y_fsc = (y >= 260) ? (y - 260)/SCALE_LG : 0;
    wire [9:0] idx_fsc = x_fsc / CHAR_SLOT;
    // Boundary check for 7 characters * CHAR_SLOT * SCALE_LG (7*7*4 = 196 pixels width)
    wire in_fsc = (x >= 180 && x < 180 + 7*CHAR_SLOT*SCALE_LG && y >= 260 && y < 260 + CHAR_W*SCALE_LG);
    
    reg [5:0] c_fsc;
    always @(*) case(idx_fsc) 
        0:c_fsc=9; 1:c_fsc=10; 2:c_fsc=1; 3:c_fsc=4; 4:c_fsc=11; // S C O R E
        5:c_fsc=26; // :
        default:c_fsc=0; 
    endcase
    assign final_score_text_on = in_fsc && is_pixel_on(c_fsc, x_fsc%CHAR_SLOT, y_fsc);

    // Final Score Number (3 digits, Starts at X=376, Y=260)
    wire [9:0] x_fnum = (x >= 376) ? (x - 376)/SCALE_LG : 0;
    wire [9:0] idx_fnum = x_fnum / CHAR_SLOT;
    // Boundary check for 3 characters * CHAR_SLOT * SCALE_LG (3*7*4 = 84 pixels width)
    wire in_fnum = (x >= 376 && x < 376 + 3*CHAR_SLOT*SCALE_LG && y >= 260 && y < 260 + CHAR_W*SCALE_LG);
    
    reg [5:0] c_fnum;
    always @(*) case(idx_fnum) 
        0:c_fnum=30+hundreds; 1:c_fnum=30+tens; 2:c_fnum=30+ones; 
        default:c_fnum=0; 
    endcase
    assign final_score_num_on = in_fnum && is_pixel_on(c_fnum, x_fnum%CHAR_SLOT, y_fsc);

    // =========================================================================
    // 8. START MENU TEXTS - Scale_LG (4x)
    // =========================================================================

    // "START" Text (Selection 1) (Starts at X=250, Y=200)
    wire [9:0] x_s = (x >= 250) ? (x - 250)/SCALE_LG : 0; 
    wire [9:0] y_s = (y >= 200) ? (y - 200)/SCALE_LG : 0; 
    wire [9:0] idx_s = x_s / CHAR_SLOT; 
    // Boundary check for 5 characters * CHAR_SLOT * SCALE_LG (5*7*4 = 140 pixels width)
    wire in_start = (x >= 250 && x < 250 + 5*CHAR_SLOT*SCALE_LG && y >= 200 && y < 220); 
    
    reg [5:0] c_s;
    always @(*) case(idx_s)
        0:c_s=9; 1:c_s=2; 2:c_s=3; 3:c_s=4; 4:c_s=2; // S T A R T
        default: c_s=0;
    endcase
    assign start_text_on = in_start && is_pixel_on(c_s, x_s%CHAR_SLOT, y_s);

    // "HOW TO PLAY" Text (Selection 2) (Starts at X=180, Y=260)
    wire [9:0] x_h = (x >= 180) ? (x - 180)/SCALE_LG : 0; 
    wire [9:0] y_h = (y >= 260) ? (y - 260)/SCALE_LG : 0; 
    wire [9:0] idx_h = x_h / CHAR_SLOT; 
    // Boundary check for 11 characters + 2 spaces * CHAR_SLOT * SCALE_LG (11*7*4 = 308 pixels width)
    wire in_how = (x >= 180 && x < 180 + 12*CHAR_SLOT*SCALE_LG && y >= 260 && y < 280); 
    
    reg [5:0] c_how; 
    always @(*) case(idx_h) 
        0: c_how=5; 1: c_how=1; 2: c_how=12; // H O W
        4: c_how=2; 5: c_how=1; // T O
        7: c_how=6; 8: c_how=7; 9: c_how=3; 10: c_how=8; // P L A Y
        default: c_how=0; 
    endcase 
    assign howto_title_on = in_how && is_pixel_on(c_how, x_h%CHAR_SLOT, y_h);


    // =========================================================================
    // 9. INSTRUCTIONS TEXTS - Scale_MD (2x)
    // =========================================================================
    
    // Relative coordinates for instruction block (Scale_MD)
    wire [9:0] rel_x_inst = (x >= INST_X) ? (x - INST_X)/SCALE_MD : 0; 
    wire [9:0] col_inst = rel_x_inst % CHAR_SLOT; 
    wire [9:0] char_idx_inst = rel_x_inst / CHAR_SLOT;
    
    // --- Line 1: CATCH (X=50, Y=100)
    // Text: "CATCH THE BOXES"
    wire in_l1 = (x >= INST_X && y >= INST_Y_START && y < INST_Y_START + CHAR_W*SCALE_MD && rel_x_inst < 15*CHAR_SLOT); 
    reg [5:0] c_l1; 
    always @(*) case(char_idx_inst) 
        0:c_l1=10; 1:c_l1=3; 2:c_l1=2; 3:c_l1=10; 4:c_l1=5; // C A T C H
        6:c_l1=2; 7:c_l1=5; 8:c_l1=11; // T H E
        10:c_l1=13; 11:c_l1=1; 12:c_l1=8; 13:c_l1=11; 14:c_l1=9; // B O X E S
        default:c_l1=0; 
    endcase 
    assign instr_line1_on = in_l1 && is_pixel_on(c_l1, col_inst, (y-INST_Y_START)/SCALE_MD);
    
    // --- Line 2: GREEN BOXES (X=50, Y=140)
    // Text: "GREEN BOXES SAVE YOUR LIFE." (GREEN highlight for first word)
    wire Y_L2 = INST_Y_START+LINE_H;
    wire in_l2 = (x >= INST_X && y >= Y_L2 && y < Y_L2 + CHAR_W*SCALE_MD && rel_x_inst < 26*CHAR_SLOT); 
    reg [5:0] c_l2; 
    always @(*) case(char_idx_inst) 
        0:c_l2=16; 1:c_l2=4; 2:c_l2=11; 3:c_l2=11; 4:c_l2=21; // G R E E N (Green)
        6:c_l2=13; 7:c_l2=1; 8:c_l2=8; 9:c_l2=11; 10:c_l2=9; // B O X E S
        12:c_l2=9; 13:c_l2=3; 14:c_l2=23; 15:c_l2=11; // S A V E
        17:c_l2=8; 18:c_l2=1; 19:c_l2=22; 20:c_l2=4; // Y O U R
        22:c_l2=7; 23:c_l2=17; 24:c_l2=15; 25:c_l2=11; 26:c_l2=25; // L I F E .
        default:c_l2=0; 
    endcase 
    wire pixel_l2 = in_l2 && is_pixel_on(c_l2, col_inst, (y-Y_L2)/SCALE_MD); 
    assign instr_green_on = pixel_l2 && (char_idx_inst < 5); // GREEN is indices 0-4
    assign instr_line2_on = pixel_l2 && (char_idx_inst >= 5);
    
    // --- Line 3: ADD PLAYER HEIGHT (X=50, Y=180)
    // Text: "AND ADD THEM TO YOUR PLAYER HEIGHT"
    wire Y_L3 = INST_Y_START+LINE_H*2;
    wire in_l3 = (x >= INST_X && y >= Y_L3 && y < Y_L3 + CHAR_W*SCALE_MD && rel_x_inst < 35*CHAR_SLOT); 
    reg [5:0] c_l3; 
    always @(*) case(char_idx_inst) 
        0:c_l3=3; 1:c_l3=21; 2:c_l3=14; // A N D
        4:c_l3=3; 5:c_l3=14; 6:c_l3=14; // A D D
        8:c_l3=2; 9:c_l3=5; 10:c_l3=11; 11:c_l3=20; // T H E M
        13:c_l3=2; 14:c_l3=1; // T O
        16:c_l3=8; 17:c_l3=1; 18:c_l3=22; 19:c_l3=4; // Y O U R
        21:c_l3=6; 22:c_l3=7; 23:c_l3=3; 24:c_l3=8; 25:c_l3=11; 26:c_l3=4; // P L A Y E R
        28:c_l3=5; 29:c_l3=11; 30:c_l3=17; 31:c_l3=16; 32:c_l3=5; 33:c_l3=2; // H E I G H T
        default:c_l3=0; 
    endcase 
    assign instr_line3_on = in_l3 && is_pixel_on(c_l3, col_inst, (y-Y_L3)/SCALE_MD);
    
    // --- Line 4: BANK (X=50, Y=220)
    // Text: "TO BANK USE KEY 2."
    wire Y_L4 = INST_Y_START+LINE_H*3;
    wire in_l4 = (x >= INST_X && y >= Y_L4 && y < Y_L4 + CHAR_W*SCALE_MD && rel_x_inst < 19*CHAR_SLOT); 
    reg [5:0] c_l4; 
    always @(*) case(char_idx_inst) 
        0:c_l4=2; 1:c_l4=1; // T O
        3:c_l4=13; 4:c_l4=3; 5:c_l4=21; 6:c_l4=19; // B A N K
        8:c_l4=22; 9:c_l4=9; 10:c_l4=11; // U S E
        12:c_l4=19; 13:c_l4=11; 14:c_l4=8; // K E Y
        16:c_l4=32; // 2
        17:c_l4=25; // .
        default:c_l4=0; 
    endcase 
    assign instr_line4_on = in_l4 && is_pixel_on(c_l4, col_inst, (y-Y_L4)/SCALE_MD);
    
    // --- Line 5: AVOID OBSTACLES (X=50, Y=260)
    // Text: "AVOID THE RED OBSTACLES"
    wire Y_L5 = INST_Y_START+LINE_H*4;
    wire in_l5 = (x >= INST_X && y >= Y_L5 && y < Y_L5 + CHAR_W*SCALE_MD && rel_x_inst < 24*CHAR_SLOT); 
    reg [5:0] c_l5; 
    always @(*) case(char_idx_inst) 
        0:c_l5=3; 1:c_l5=23; 2:c_l5=1; 3:c_l5=17; 4:c_l5=14; // A V O I D
        6:c_l5=2; 7:c_l5=5; 8:c_l5=11; // T H E
        10:c_l5=4; 11:c_l5=11; 12:c_l5=14; // R E D
        14:c_l5=1; 15:c_l5=13; 16:c_l5=9; 17:c_l5=2; 18:c_l5=3; 19:c_l5=10; 20:c_l5=7; 21:c_l5=11; 22:c_l5=9; // O B S T A C L E S
        default:c_l5=0; 
    endcase 
    assign instr_line5_on = in_l5 && is_pixel_on(c_l5, col_inst, (y-Y_L5)/SCALE_MD);
    
    // --- Line 6: REDUCE HP (X=50, Y=300)
    // Text: "RED OBSTACLES REDUCE HP!" (RED highlight for first word)
    wire Y_L6 = INST_Y_START+LINE_H*5;
    wire in_l6 = (x >= INST_X && y >= Y_L6 && y < Y_L6 + CHAR_W*SCALE_MD && rel_x_inst < 24*CHAR_SLOT); 
    reg [5:0] c_l6; 
    always @(*) case(char_idx_inst) 
        0:c_l6=4; 1:c_l6=11; 2:c_l6=14; // R E D (Red)
        4:c_l6=1; 5:c_l6=13; 6:c_l6=9; 7:c_l6=2; 8:c_l6=3; 9:c_l6=10; 10:c_l6=7; 11:c_l6=11; 12:c_l6=9; // O B S T A C L E S
        14:c_l6=4; 15:c_l6=11; 16:c_l6=14; 17:c_l6=22; 18:c_l6=10; 19:c_l6=11; // R E D U C E
        21:c_l6=5; 22:c_l6=6; // H P
        23:c_l6=24; // !
        default:c_l6=0; 
    endcase 
    wire pixel_l6 = in_l6 && is_pixel_on(c_l6, col_inst, (y-Y_L6)/SCALE_MD); 
    assign instr_red_on = pixel_l6 && (char_idx_inst < 3); // RED is indices 0-2
    assign instr_line6_on = pixel_l6 && (char_idx_inst >= 3);

endmodule