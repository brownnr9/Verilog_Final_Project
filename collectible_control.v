module collectible_control #(
    parameter BOX_WIDTH 	    = 10'd30,
    parameter BOX_HEIGHT 	    = 10'd30,
    parameter BOX_SPEED 	    = 10'd6,
    parameter Y_INITIAL_OFFSET  = 10'd50,
    parameter WAIT_CYCLES       = 8'd20     
) (
    input 					clk,
    input 					rst,
    input 					game_en,
    input                   box_caught, 
    input [9:0]             y_amplitude_in, 
    input                   player_is_holding_box, 
    
    output reg [9:0] 		box_x_pos, 
    output reg [9:0] 		box_y_pos,
    output wire [9:0] 		box_width,
    output wire [9:0] 		box_height,
    output reg              active 
);

    parameter S_WAIT   = 2'b00;
    parameter S_SPAWN  = 2'b01;
    parameter S_FLYING = 2'b10;
    
    reg [1:0] state;
    reg [1:0] next_state;

    // Movement Logic
    reg [1:0] arc_state; // 01=Up, 10=Down
    reg [9:0] y_offset; 
    reg [7:0] wait_counter;
    wire wait_complete = (wait_counter == WAIT_CYCLES);

    // Constants
    parameter MAX_X             = 10'd639;
    parameter X_START_POS       = MAX_X + 10'd1;
    parameter X_RESET_THRESHOLD = 10'd0;
    parameter Y_BASELINE 	    = 10'd315;
    parameter Y_MIN_START       = Y_BASELINE - BOX_HEIGHT;
    localparam Y_STEP_SIZE      = 10'd3;

    assign box_width       = BOX_WIDTH;
    assign box_height      = BOX_HEIGHT;
    wire [9:0] y_max_displacement = Y_INITIAL_OFFSET + y_amplitude_in;
    
    // --- State Update ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) state <= S_WAIT;
        else if (game_en) state <= next_state;
    end

    // --- Next State Logic ---
    always @(*) begin
        next_state = state;
        case (state)
            S_WAIT: begin
                if (wait_complete) next_state = S_SPAWN;
            end
            S_SPAWN: begin
                if (box_x_pos < MAX_X) next_state = S_FLYING;
            end
            S_FLYING: begin
                // Despawn conditions:
                // 1. Caught by player
                // 2. Moved off screen left
                // 3. Hit the floor (Arc logic checks this via y_offset)
                if (box_caught || box_x_pos <= X_RESET_THRESHOLD) 
                    next_state = S_WAIT;
                // NEW: If falling (2'b10) and near floor (y_offset <= step), disappear
                else if ((arc_state == 2'b10) && (y_offset <= Y_STEP_SIZE))
                    next_state = S_WAIT;
            end
            default: next_state = S_WAIT;
        endcase
    end

    // --- Output Logic ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            box_x_pos <= X_START_POS;
            box_y_pos <= Y_MIN_START - Y_INITIAL_OFFSET;
            y_offset       <= Y_INITIAL_OFFSET;
            arc_state      <= 2'b01;
            wait_counter   <= 8'd0;
            active         <= 1'b0;
        end else if (game_en) begin
            case (state)
                S_WAIT: begin
                    box_x_pos <= X_START_POS;
                    active <= 1'b0;
                    if (!wait_complete) wait_counter <= wait_counter + 8'd1;
                    
                    y_offset <= Y_INITIAL_OFFSET;
                    arc_state <= 2'b01; 
                end
                
                S_SPAWN: begin
                    active <= 1'b1;
                    box_x_pos <= box_x_pos - BOX_SPEED;
                    wait_counter <= 8'd0;
                    box_y_pos <= Y_MIN_START - y_offset;
                end
                
                S_FLYING: begin
                    active <= 1'b1;
                    box_x_pos <= box_x_pos - BOX_SPEED;

                    // Arc Physics
                    case (arc_state)
                        2'b01: begin // Up
                            if (y_offset < y_max_displacement) 
                                y_offset <= y_offset + Y_STEP_SIZE;
                            else 
                                arc_state <= 2'b10;
                        end
                        2'b10: begin // Down
                            // Normal physics, state machine handles despawn when this gets low
                            if (y_offset > Y_STEP_SIZE) 
                                y_offset <= y_offset - Y_STEP_SIZE;
                        end
                    endcase
                    box_y_pos <= Y_MIN_START - y_offset; 
                end
            endcase
        end
    end
endmodule