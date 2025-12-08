module text_layer (
    input [9:0] x,
    input [9:0] y,
    
    // Title Screen
    output start_text_on,
    output howto_title_on, // "HOW TO PLAY" title
    
    // Game HUD
    output score_text_on,
    output hp_text_on,

    // Instruction Lines
    output instr_line1_on, // "CATCH THE"
    output instr_line2_on, // "OBJECTS" (part of line 2)
    output instr_green_on, // "GREEN" (colored part of line 2)
    output instr_line3_on, // "AND PLACE THEM"
    output instr_line4_on, // "TO THE LEFT." (MODIFIED)
    output instr_line5_on, // "AVOID THE"
    output instr_line6_on, // "OBSTACLES!"
    output instr_red_on     // "RED" (colored part of line 6)
);

    // --- Configuration ---
    parameter CHAR_W = 10'd5;
    parameter CHAR_H = 10'd5;
    parameter SPACING = 10'd2;
    parameter CHAR_SLOT_W = CHAR_W + SPACING; // New derived parameter: 7
    parameter SCALE_LG = 10'd4; // For Titles
    parameter SCALE_MD = 10'd2; // For Instructions/HUD

    // --- Font Definition (5x5 Bitmap) ---
    function is_pixel_on;
        input [5:0] char_code; 
        input [2:0] col; // Pixel column within the 7-wide slot (0-6)
        input [2:0] row; // Pixel row (0-4)
        reg [24:0] bitmap;
        begin
            // If col >= CHAR_W (i.e., col 5 or 6), it's the spacing area.
            if (col >= CHAR_W || row >= CHAR_H) begin
                is_pixel_on = 1'b0;
            end else begin
                case (char_code)
                    6'd1:  bitmap = 25'b01110_10001_10001_10001_01110; // O
                    6'd2:  bitmap = 25'b11111_00100_00100_00100_00100; // T
                    6'd3:  bitmap = 25'b00100_01010_11111_10001_10001; // A
                    6'd4:  bitmap = 25'b11110_10001_11110_10010_10001; // R
                    6'd5:  bitmap = 25'b10001_10001_11111_10001_10001; // H
                    6'd6:  bitmap = 25'b11110_10001_11110_10000_10000; // P
                    6'd7:  bitmap = 25'b10000_10000_10000_10000_11111; // L
                    6'd8:  bitmap = 25'b10001_10001_01010_00100_00100; // Y
                    6'd9:  bitmap = 25'b01110_10000_01110_00001_11110; // S
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
                    6'd24: bitmap = 25'b00100_00100_00100_00000_00100; // !
                    6'd25: bitmap = 25'b00000_00000_00000_00000_00100; // .
                    default: bitmap = 25'b00000_00000_00000_00000_00000;
                endcase
                // Map the 1D bitmap to the 2D col/row (Row 0 is top)
                is_pixel_on = bitmap[24 - (row * CHAR_W + col)];
            end
        end
    endfunction

    // =========================================================================
    // TEXT REGION LOGIC (Using CHAR_SLOT_W everywhere)
    // =========================================================================
    
    // --- 1. START (Title Screen) ---
    // "START" - 5 chars
    wire [9:0] x_s = (x >= 250) ? (x - 250)/SCALE_LG : 0;
    wire [9:0] y_s = (y >= 200) ? (y - 200)/SCALE_LG : 0;
    wire [9:0] idx_s = x_s / CHAR_SLOT_W;
    wire in_start = (x >= 250 && x < 250 + 5*CHAR_SLOT_W*SCALE_LG && y >= 200 && y < 200 + CHAR_H*SCALE_LG);
    
    assign start_text_on = in_start && is_pixel_on((idx_s==0?9: idx_s==1?2: idx_s==2?3: idx_s==3?4: idx_s==4?2: 0), x_s % CHAR_SLOT_W, y_s);

    // --- 2. HOW TO PLAY (Title Screen) ---
    // "HOW TO PLAY" - 11 chars
    wire [9:0] x_h = (x >= 180) ? (x - 180)/SCALE_LG : 0;
    wire [9:0] y_h = (y >= 260) ? (y - 260)/SCALE_LG : 0;
    wire [9:0] idx_h = x_h / CHAR_SLOT_W;
    wire in_how = (x >= 180 && x < 180 + 11*CHAR_SLOT_W*SCALE_LG && y >= 260 && y < 260 + CHAR_H*SCALE_LG);
    
    // H=5,O=1,W=12, T=2,O=1, P=6,L=7,A=3,Y=8
    reg [5:0] c_how;
    always @(*) case(idx_h)
        0: c_how=5; 1: c_how=1; 2: c_how=12; // HOW (Space at 3)
        4: c_how=2; 5: c_how=1;              // TO (Space at 6)
        7: c_how=6; 8: c_how=7; 9: c_how=3; 10: c_how=8; // PLAY
        default: c_how=0;
    endcase
    assign howto_title_on = in_how && is_pixel_on(c_how, x_h % CHAR_SLOT_W, y_h);

    // =========================================================================
    // INSTRUCTION SCREEN TEXT
    // =========================================================================
    parameter INST_X = 10'd50;
    parameter INST_Y_START = 10'd100;
    parameter LINE_H = 10'd40;
    
    wire [9:0] rel_x_inst = (x >= INST_X) ? (x - INST_X)/SCALE_MD : 0;
    wire [9:0] col_inst    = rel_x_inst % CHAR_SLOT_W; // Parameterized
    wire [9:0] char_idx_inst = rel_x_inst / CHAR_SLOT_W; // Parameterized

    // --- Line 1: "CATCH THE" ---
    wire in_l1 = (x >= INST_X && y >= INST_Y_START && y < INST_Y_START + CHAR_H*SCALE_MD && rel_x_inst < 9*CHAR_SLOT_W); 
    reg [5:0] c_l1;
    always @(*) case(char_idx_inst)
        0:c_l1=10; 1:c_l1=3; 2:c_l1=2; 3:c_l1=10; 4:c_l1=5; // CATCH (Space at 5)
        6:c_l1=2;  7:c_l1=5; 8:c_l1=11;                      // THE
        default: c_l1=0;
    endcase
    assign instr_line1_on = in_l1 && is_pixel_on(c_l1, col_inst, (y-INST_Y_START)/SCALE_MD);

    // --- Line 2: "GREEN OBJECTS" ---
    wire in_l2 = (x >= INST_X && y >= INST_Y_START+LINE_H && y < INST_Y_START+LINE_H + CHAR_H*SCALE_MD);
    reg [5:0] c_l2;
    always @(*) case(char_idx_inst)
        0:c_l2=16; 1:c_l2=4; 2:c_l2=11; 3:c_l2=11; 4:c_l2=21; // GREEN (Space at 5)
        6:c_l2=1; 7:c_l2=13; 8:c_l2=18; 9:c_l2=11; 10:c_l2=10; 11:c_l2=2; 12:c_l2=9; // OBJECTS
        default: c_l2=0;
    endcase
    wire pixel_l2 = in_l2 && is_pixel_on(c_l2, col_inst, (y-(INST_Y_START+LINE_H))/SCALE_MD);
    assign instr_green_on = pixel_l2 && (char_idx_inst < 6); 
    assign instr_line2_on = pixel_l2 && (char_idx_inst >= 6); 

    // --- Line 3: "AND PLACE THEM" ---
    wire in_l3 = (x >= INST_X && y >= INST_Y_START+LINE_H*2 && y < INST_Y_START+LINE_H*2 + CHAR_H*SCALE_MD);
    reg [5:0] c_l3;
    always @(*) case(char_idx_inst)
        0:c_l3=3; 1:c_l3=21; 2:c_l3=14; // AND (Space at 3)
        4:c_l3=6; 5:c_l3=7; 6:c_l3=3; 7:c_l3=10; 8:c_l3=11; // PLACE (Space at 9)
        10:c_l3=2; 11:c_l3=5; 12:c_l3=11; 13:c_l3=20; // THEM
        default: c_l3=0;
    endcase
    assign instr_line3_on = in_l3 && is_pixel_on(c_l3, col_inst, (y-(INST_Y_START+LINE_H*2))/SCALE_MD);

    // --- Line 4: "TO THE LEFT." (MODIFIED, now parameterized) ---
    wire in_l4 = (x >= INST_X && y >= INST_Y_START+LINE_H*3 && y < INST_Y_START+LINE_H*3 + CHAR_H*SCALE_MD);
    reg [5:0] c_l4;
    always @(*) case(char_idx_inst)
        0:c_l4=2; 1:c_l4=1; // T O (Space at 2)
        3:c_l4=2; 4:c_l4=5; 5:c_l4=11; // T H E (Space at 6)
        7:c_l4=7; 8:c_l4=11; 9:c_l4=15; 10:c_l4=2; 11:c_l4=25; // L E F T .
        default: c_l4=0;
    endcase
    assign instr_line4_on = in_l4 && is_pixel_on(c_l4, col_inst, (y-(INST_Y_START+LINE_H*3))/SCALE_MD);

    // --- Line 5: "AVOID THE" ---
    wire in_l5 = (x >= INST_X && y >= INST_Y_START+LINE_H*4 && y < INST_Y_START+LINE_H*4 + CHAR_H*SCALE_MD);
    reg [5:0] c_l5;
    always @(*) case(char_idx_inst)
        0:c_l5=3; 1:c_l5=23; 2:c_l5=1; 3:c_l5=17; 4:c_l5=14; // AVOID (Space at 5)
        6:c_l5=2; 7:c_l5=5; 8:c_l5=11; // THE
        default: c_l5=0;
    endcase
    assign instr_line5_on = in_l5 && is_pixel_on(c_l5, col_inst, (y-(INST_Y_START+LINE_H*4))/SCALE_MD);

    // --- Line 6: "RED OBSTACLES!" ---
    wire in_l6 = (x >= INST_X && y >= INST_Y_START+LINE_H*5 && y < INST_Y_START+LINE_H*5 + CHAR_H*SCALE_MD);
    reg [5:0] c_l6;
    always @(*) case(char_idx_inst)
        0:c_l6=4; 1:c_l6=11; 2:c_l6=14; // RED (Space at 3)
        4:c_l6=1; 5:c_l6=13; 6:c_l6=9; 7:c_l6=2; 8:c_l6=3; 9:c_l6=10; 10:c_l6=7; 11:c_l6=11; 12:c_l6=9; 13:c_l6=24; // OBSTACLES!
        default: c_l6=0;
    endcase
    
    wire pixel_l6 = in_l6 && is_pixel_on(c_l6, col_inst, (y-(INST_Y_START+LINE_H*5))/SCALE_MD);
    assign instr_red_on = pixel_l6 && (char_idx_inst < 4); 
    assign instr_line6_on = pixel_l6 && (char_idx_inst >= 4);

    // --- HUD: SCORE ---
    wire [9:0] x_sc = (x >= 10) ? (x - 10)/SCALE_MD : 0;
    wire [9:0] y_sc = (y >= 10) ? (y - 10)/SCALE_MD : 0;
    wire [9:0] idx_sc = x_sc / CHAR_SLOT_W;
    wire in_score = (x >= 10 && x < 10 + 5*CHAR_SLOT_W*SCALE_MD && y >= 10 && y < 10 + CHAR_H*SCALE_MD);
    assign score_text_on = in_score && is_pixel_on((idx_sc==0?9:idx_sc==1?10:idx_sc==2?1:idx_sc==3?4:11), x_sc % CHAR_SLOT_W, y_sc);

    // --- HUD: HP ---
    wire [9:0] x_hp = (x >= 10) ? (x - 10)/SCALE_MD : 0;
    wire [9:0] y_hp = (y >= 40) ? (y - 40)/SCALE_MD : 0;
    wire in_hp = (x >= 10 && x < 10 + 2*CHAR_SLOT_W*SCALE_MD && y >= 40 && y < 40 + CHAR_H*SCALE_MD);
    assign hp_text_on = in_hp && is_pixel_on((x_hp/CHAR_SLOT_W==0?5:6), x_hp % CHAR_SLOT_W, y_hp);

endmodule