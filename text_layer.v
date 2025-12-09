module text_layer (
    input [9:0] x,
    input [9:0] y,
    
    // Title Screen
    output start_text_on,
    output howto_title_on,
    
    // Game HUD
    output score_text_on,
    output hp_text_on,

    // Instruction Lines
    output instr_line1_on,
    output instr_line2_on, output instr_green_on,
    output instr_line3_on,
    output instr_line4_on,
    output instr_line5_on,
    output instr_line6_on, output instr_red_on,

    // NEW: Game Over Screen
    output gameover_text_on,
    output final_score_text_on
);

    // --- Font Definition (5x5 Bitmap) ---
    function is_pixel_on;
        input [5:0] char_code; 
        input [2:0] col;
        input [2:0] row;
        reg [24:0] bitmap;
        begin
            if (col > 3'd4 || row > 3'd4) begin
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
                    6'd26: bitmap = 25'b00000_00100_00000_00100_00000; // : (Colon)
                    default: bitmap = 25'b00000_00000_00000_00000_00000;
                endcase
                is_pixel_on = bitmap[24 - (row * 5 + col)];
            end
        end
    endfunction

    // --- Configuration ---
    parameter CHAR_W = 10'd5;
    parameter CHAR_H = 10'd5;
    parameter SPACING = 10'd2;
    parameter SCALE_LG = 10'd4; 
    parameter SCALE_MD = 10'd2; 

    // =========================================================================
    // 1. TITLE SCREEN
    // =========================================================================
    
    // "START"
    wire [9:0] x_s = (x >= 250) ? (x - 250)/SCALE_LG : 0;
    wire [9:0] y_s = (y >= 200) ? (y - 200)/SCALE_LG : 0;
    wire [9:0] idx_s = x_s / (CHAR_W + SPACING);
    wire in_start = (x >= 250 && x < 250 + 5*7*4 && y >= 200 && y < 200 + 5*4);
    assign start_text_on = in_start && is_pixel_on((idx_s==0?9: idx_s==1?2: idx_s==2?3: idx_s==3?4: idx_s==4?2: 0), x_s%(7), y_s);

    // "HOW TO PLAY"
    wire [9:0] x_h = (x >= 180) ? (x - 180)/SCALE_LG : 0;
    wire [9:0] y_h = (y >= 260) ? (y - 260)/SCALE_LG : 0;
    wire [9:0] idx_h = x_h / (7);
    wire in_how = (x >= 180 && x < 180 + 11*7*4 && y >= 260 && y < 260 + 5*4);
    
    reg [5:0] c_how;
    always @(*) case(idx_h)
        0: c_how=5; 1: c_how=1; 2: c_how=12; // HOW
        4: c_how=2; 5: c_how=1;              // TO
        7: c_how=6; 8: c_how=7; 9: c_how=3; 10: c_how=8; // PLAY
        default: c_how=0;
    endcase
    assign howto_title_on = in_how && is_pixel_on(c_how, x_h%7, y_h);

    // =========================================================================
    // 2. HUD
    // =========================================================================
    
    // "SCORE" (Top Left)
    wire [9:0] x_sc = (x >= 10) ? (x - 10)/SCALE_MD : 0;
    wire [9:0] y_sc = (y >= 10) ? (y - 10)/SCALE_MD : 0;
    wire [9:0] idx_sc = x_sc / 7;
    wire in_score = (x >= 10 && x < 10 + 5*7*2 && y >= 10 && y < 20);
    assign score_text_on = in_score && is_pixel_on((idx_sc==0?9:idx_sc==1?10:idx_sc==2?1:idx_sc==3?4:11), x_sc%7, y_sc);

    // "HP" (Top Left)
    wire [9:0] x_hp = (x >= 10) ? (x - 10)/SCALE_MD : 0;
    wire [9:0] y_hp = (y >= 40) ? (y - 40)/SCALE_MD : 0;
    wire in_hp = (x >= 10 && x < 10 + 2*7*2 && y >= 40 && y < 50);
    assign hp_text_on = in_hp && is_pixel_on((x_hp/7==0?5:6), x_hp%7, y_hp);

    // =========================================================================
    // 3. GAME OVER SCREEN (NEW)
    // =========================================================================
    
    // "GAME OVER!" - Centered ~ Y=200
    // Width approx 10 chars * 7 * 4 = 280px. X Start = (640-280)/2 = 180.
    wire [9:0] x_go = (x >= 180) ? (x - 180)/SCALE_LG : 0;
    wire [9:0] y_go = (y >= 200) ? (y - 200)/SCALE_LG : 0;
    wire [9:0] idx_go = x_go / 7;
    wire in_go = (x >= 180 && x < 180 + 10*7*4 && y >= 200 && y < 200 + 5*4);
    
    // G=16, A=3, M=20, E=11, O=1, V=23, E=11, R=4, !=24
    reg [5:0] c_go;
    always @(*) case(idx_go)
        0: c_go=16; 1: c_go=3; 2: c_go=20; 3: c_go=11; // GAME
        5: c_go=1; 6: c_go=23; 7: c_go=11; 8: c_go=4; 9: c_go=24; // OVER!
        default: c_go=0;
    endcase
    assign gameover_text_on = in_go && is_pixel_on(c_go, x_go%7, y_go);

    // "SCORE: " - Centered below ~ Y=260
    // Width approx 7 chars * 7 * 4 = 196px. X Start = (640-196)/2 = 222.
    wire [9:0] x_fsc = (x >= 222) ? (x - 222)/SCALE_LG : 0;
    wire [9:0] y_fsc = (y >= 260) ? (y - 260)/SCALE_LG : 0;
    wire [9:0] idx_fsc = x_fsc / 7;
    wire in_fsc = (x >= 222 && x < 222 + 7*7*4 && y >= 260 && y < 260 + 5*4);
    
    // S=9, C=10, O=1, R=4, E=11, :=26
    reg [5:0] c_fsc;
    always @(*) case(idx_fsc)
        0: c_fsc=9; 1: c_fsc=10; 2: c_fsc=1; 3: c_fsc=4; 4: c_fsc=11; 5: c_fsc=26; // SCORE:
        default: c_fsc=0;
    endcase
    assign final_score_text_on = in_fsc && is_pixel_on(c_fsc, x_fsc%7, y_fsc);

    // =========================================================================
    // 4. INSTRUCTIONS
    // =========================================================================
    parameter INST_X = 10'd50;
    parameter INST_Y_START = 10'd100;
    parameter LINE_H = 10'd40;
    wire [9:0] rel_x_inst = (x >= INST_X) ? (x - INST_X)/SCALE_MD : 0;
    wire [9:0] col_inst   = rel_x_inst % 7;
    wire [9:0] char_idx_inst = rel_x_inst / 7;

    // Line 1 "CATCH THE"
    wire in_l1 = (x >= INST_X && y >= INST_Y_START && y < INST_Y_START + 10 && rel_x_inst < 70); 
    reg [5:0] c_l1;
    always @(*) case(char_idx_inst) 0:c_l1=10; 1:c_l1=3; 2:c_l1=2; 3:c_l1=10; 4:c_l1=5; 6:c_l1=2; 7:c_l1=5; 8:c_l1=11; default:c_l1=0; endcase
    assign instr_line1_on = in_l1 && is_pixel_on(c_l1, col_inst, (y-INST_Y_START)/SCALE_MD);

    // Line 2 "GREEN OBJECTS"
    wire in_l2 = (x >= INST_X && y >= INST_Y_START+LINE_H && y < INST_Y_START+LINE_H + 10);
    reg [5:0] c_l2;
    always @(*) case(char_idx_inst) 0:c_l2=16; 1:c_l2=4; 2:c_l2=11; 3:c_l2=11; 4:c_l2=21; 6:c_l2=1; 7:c_l2=13; 8:c_l2=18; 9:c_l2=11; 10:c_l2=10; 11:c_l2=2; 12:c_l2=9; default:c_l2=0; endcase
    wire pixel_l2 = in_l2 && is_pixel_on(c_l2, col_inst, (y-(INST_Y_START+LINE_H))/SCALE_MD);
    assign instr_green_on = pixel_l2 && (char_idx_inst < 6); 
    assign instr_line2_on = pixel_l2 && (char_idx_inst >= 6); 

    // Line 3 "AND PLACE THEM"
    wire in_l3 = (x >= INST_X && y >= INST_Y_START+LINE_H*2 && y < INST_Y_START+LINE_H*2 + 10);
    reg [5:0] c_l3;
    always @(*) case(char_idx_inst) 0:c_l3=3; 1:c_l3=21; 2:c_l3=14; 4:c_l3=6; 5:c_l3=7; 6:c_l3=3; 7:c_l3=10; 8:c_l3=11; 10:c_l3=2; 11:c_l3=5; 12:c_l3=11; 13:c_l3=20; default:c_l3=0; endcase
    assign instr_line3_on = in_l3 && is_pixel_on(c_l3, col_inst, (y-(INST_Y_START+LINE_H*2))/SCALE_MD);

    // Line 4 "TO THE LEFT."
    wire in_l4 = (x >= INST_X && y >= INST_Y_START+LINE_H*3 && y < INST_Y_START+LINE_H*3 + 10);
    reg [5:0] c_l4;
    always @(*) case(char_idx_inst) 0:c_l4=2; 1:c_l4=1; 3:c_l4=2; 4:c_l4=5; 5:c_l4=11; 7:c_l4=7; 8:c_l4=11; 9:c_l4=15; 10:c_l4=2; 11:c_l4=25; default:c_l4=0; endcase
    assign instr_line4_on = in_l4 && is_pixel_on(c_l4, col_inst, (y-(INST_Y_START+LINE_H*3))/SCALE_MD);

    // Line 5 "AVOID THE"
    wire in_l5 = (x >= INST_X && y >= INST_Y_START+LINE_H*4 && y < INST_Y_START+LINE_H*4 + 10);
    reg [5:0] c_l5;
    always @(*) case(char_idx_inst) 0:c_l5=3; 1:c_l5=23; 2:c_l5=1; 3:c_l5=17; 4:c_l5=14; 6:c_l5=2; 7:c_l5=5; 8:c_l5=11; default:c_l5=0; endcase
    assign instr_line5_on = in_l5 && is_pixel_on(c_l5, col_inst, (y-(INST_Y_START+LINE_H*4))/SCALE_MD);

    // Line 6 "RED OBSTACLES!"
    wire in_l6 = (x >= INST_X && y >= INST_Y_START+LINE_H*5 && y < INST_Y_START+LINE_H*5 + 10);
    reg [5:0] c_l6;
    always @(*) case(char_idx_inst) 0:c_l6=4; 1:c_l6=11; 2:c_l6=14; 4:c_l6=1; 5:c_l6=13; 6:c_l6=9; 7:c_l6=2; 8:c_l6=3; 9:c_l6=10; 10:c_l6=7; 11:c_l6=11; 12:c_l6=9; 13:c_l6=24; default:c_l6=0; endcase
    wire pixel_l6 = in_l6 && is_pixel_on(c_l6, col_inst, (y-(INST_Y_START+LINE_H*5))/SCALE_MD);
    assign instr_red_on = pixel_l6 && (char_idx_inst < 4); 
    assign instr_line6_on = pixel_l6 && (char_idx_inst >= 4);

endmodule