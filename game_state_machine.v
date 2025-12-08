module game_state_machine(
    input clk,
    input rst,          // System Reset (Active Low based on your other modules)
    input key_left,     // KEY[1] - Navigate Left
    input key_right,    // KEY[0] - Navigate Right
    input key_select,   // KEY[2] - Select Option
    input key_back,     // KEY[3] - Go Back
    input collision,    // From collision detector
    
    output reg [1:0] state,
    output reg       menu_selection // 0 = START, 1 = HOW TO PLAY
);

    // --- State Encoding ---
    parameter S_START        = 2'b00;
    parameter S_PLAYING      = 2'b01;
    parameter S_INSTRUCTIONS = 2'b10;
    parameter S_GAME_OVER    = 2'b11;

    // --- Edge Detection Registers ---
    // DE1-SoC Keys are Active Low (0 when pressed, 1 when released)
    // We want to trigger on the "Press" (Falling Edge)
    reg k_l_q, k_r_q, k_s_q, k_b_q;
    
    wire press_left   = k_l_q && !key_left;
    wire press_right  = k_r_q && !key_right;
    wire press_select = k_s_q && !key_select;
    wire press_back   = k_b_q && !key_back;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S_START;
            menu_selection <= 1'b0; // Default to "START"
            // Reset edge detectors to 1 (unpressed state)
            k_l_q <= 1'b1; k_r_q <= 1'b1; k_s_q <= 1'b1; k_b_q <= 1'b1;
        end else begin
            // Register inputs for edge detection
            k_l_q <= key_left;
            k_r_q <= key_right;
            k_s_q <= key_select;
            k_b_q <= key_back;

            case (state)
                S_START: begin
                    // Left/Right toggles selection
                    if (press_right || press_left) begin
                        menu_selection <= ~menu_selection; 
                    end
                    
                    // Select confirms choice
                    if (press_select) begin
                        if (menu_selection == 1'b0)
                            state <= S_PLAYING;
                        else
                            state <= S_INSTRUCTIONS;
                    end
                end

                S_INSTRUCTIONS: begin
                    // Back button returns to menu
                    if (press_back) begin
                        state <= S_START;
                    end
                end

                S_PLAYING: begin
                    // Only collision changes state here (Back button disabled during play)
                    if (collision) 
                        state <= S_GAME_OVER;
                end

                S_GAME_OVER: begin
                    // Select or Back returns to menu
                    if (press_select || press_back) begin
                        state <= S_START;
                        menu_selection <= 1'b0; // Reset to Start
                    end
                end
            endcase
        end
    end
endmodule