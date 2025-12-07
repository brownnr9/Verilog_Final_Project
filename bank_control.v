module bank_control #(
    // Parameters needed for inventory check and bank location
    parameter PLAYER_BASE_HEIGHT= 10'd30,
    parameter BANK_X_START      = 10'd50,
    parameter BANK_WIDTH        = 10'd60
) (
    input 					clk, 		// 50 MHz clock
    input 					rst, 		// Reset signal (active high)
    input 					game_en,	// Slow clock enable from game_clock_generator
    input 					key_2_in, 	// Raw KEY[2] input (active low)
    
    input 		[9:0]		player_x_pos, 			// Player's current X position (left edge)
    input 		[9:0]		player_current_height,	// Player's current height
    
    output reg 				box_dropped,			// Single-cycle pulse to reduce player height
    output reg 	[7:0]		bank_level				// Total count of banked boxes
);

    // --- Debouncer Registers ---
    reg key_2_q1, key_2_q2; // Two-stage shift register for debouncing
    wire key_2_debounced_pulse; // Single-cycle pulse output

    // --- 1. Button Debouncing and Edge Detection ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            key_2_q1 <= 1'b0;
            key_2_q2 <= 1'b0;
        end else if (game_en) begin
            // Shift register on the slow game clock
            key_2_q1 <= ~key_2_in; // KEY is active low, invert to active high
            key_2_q2 <= key_2_q1;
        end
    end
    
    // key_2_debounced_pulse generates a '1' only on the rising edge of the debounced signal
    // (i.e., when key_2_q1 is high and key_2_q2 was low, indicating a fresh press)
    assign key_2_debounced_pulse = key_2_q1 && !key_2_q2;
    
    // --- 2. Bank Collision Check (Combinational) ---
    // Check if the player's left edge (player_x_pos) is within the bank's X range [BANK_X_START, BANK_X_START + BANK_WIDTH)
    wire touching_bank = (player_x_pos >= BANK_X_START) && (player_x_pos < BANK_X_START + BANK_WIDTH);

    // --- 3. Inventory Check (Combinational) ---
    // Player must have more than the base height (i.e., at least one extra segment)
    wire has_box_to_drop = (player_current_height > PLAYER_BASE_HEIGHT);

    // --- 4. Banking Logic (Sequential) ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            box_dropped <= 1'b0;
            bank_level <= 8'd0;
        end else if (game_en) begin
            
            // Default: box_dropped is a single-cycle pulse
            box_dropped <= 1'b0; 
            
            if (key_2_debounced_pulse) begin
                if (touching_bank && has_box_to_drop) begin
                    // Success! Drop the box and increase bank level
                    box_dropped <= 1'b1; // Pulse high for 1 game_en cycle
                    bank_level <= bank_level + 8'd1;
                end
            end
        end
    end

endmodule