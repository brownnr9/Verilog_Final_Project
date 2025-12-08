module game_state_machine(
    input clk,
    input rst,
    input key_action,       // e.g., KEY[0] - Start / Restart
    input key_instr,        // e.g., KEY[1] - View Instructions
    input collision,        // From collision detector
    output reg [1:0] state
);

    // --- State Encoding ---
    parameter S_START        = 2'b00;
    parameter S_PLAYING      = 2'b01;
    parameter S_INSTRUCTIONS = 2'b10;
    parameter S_GAME_OVER    = 2'b11;

    // --- Button Edge Detection (Debouncing handled by user speed usually, but edge is needed) ---
    reg key_action_prev, key_instr_prev;
    wire action_pressed = !key_action && key_action_prev; // Falling edge (Active Low)
    wire instr_pressed  = !key_instr && key_instr_prev;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            key_action_prev <= 1'b1;
            key_instr_prev  <= 1'b1;
            state <= S_START;
        end else begin
            key_action_prev <= key_action;
            key_instr_prev  <= key_instr;

            case (state)
                S_START: begin
                    if (action_pressed) 
                        state <= S_PLAYING;
                    else if (instr_pressed) 
                        state <= S_INSTRUCTIONS;
                end

                S_INSTRUCTIONS: begin
                    // Pressing action button goes back to start
                    if (action_pressed) 
                        state <= S_START;
                end

                S_PLAYING: begin
                    if (collision) 
                        state <= S_GAME_OVER;
                end

                S_GAME_OVER: begin
                    // Press action to return to menu
                    if (action_pressed) 
                        state <= S_START;
                end
            endcase
        end
    end
endmodule
