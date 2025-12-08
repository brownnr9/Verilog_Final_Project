module obstacle_control #(
    // Parameters for Obstacle Size and Speed
    parameter OBSTACLE_WIDTH 	= 10'd30,
    parameter OBSTACLE_HEIGHT 	= 10'd30,
    parameter OBSTACLE_X_SPEED 	= 10'd5,    // Horizontal speed (moving left)
    parameter Y_INITIAL_OFFSET  = 10'd50,   // Initial height for the obstacle
    
    // WAIT TIME PARAMETER: Approximately 1 second wait time
    // Game clock (game_en) is typically 12Hz, so 12 cycles is about 1 second.
    parameter WAIT_CYCLES       = 8'd12     
) (
    input 					clk, 		// 50 MHz clock
    input 					rst, 		// Reset signal (active high)
    input 					game_en,	// Slow clock enable from game_clock_generator
	input						collision,  // Input from collision detector
	
    // DYNAMIC INPUT: Amplitude from the Random Generator
    input [9:0]             y_amplitude_in, 
	
    // Outputs for the renderer and collision detector
    output reg [9:0] 		obstacle_x_pos, 
    output reg [9:0] 		obstacle_y_pos,
    
    // Outputs for collision detector (constant for this module, but exposed)
    output wire [9:0] 		obstacle_width,
    output wire [9:0] 		obstacle_height
);

    // --- FSM State Definitions ---
    parameter S_WAIT   = 2'b00; // Waiting for respawn timer
    parameter S_SPAWN  = 2'b01; // Moving into active screen
    parameter S_FLYING = 2'b10; // Active movement (Horizontal and Vertical Arc)
    
    reg [1:0] state;   // Current State Register 
	reg [1:0] next_state; // Next State Wire

    // --- Arc Sub-State Definitions ---
    reg  [1:0] arc_state;       // 2'b01=PUSH/ASCEND, 2'b10=FALL/DESCEND
    
    // *** MISSING DECLARATION ADDED HERE ***
    // Tracks the vertical displacement (offset) from the baseline.
    reg [9:0] y_offset; 

    // --- Wait Timer Register ---
    reg [7:0] wait_counter;
    wire wait_complete = (wait_counter == WAIT_CYCLES);

    // --- Local Constants ---
    parameter MAX_X             = 10'd639; // Rightmost pixel
    parameter X_START_POS       = MAX_X + 10'd1; // Off-screen right position for spawn
    parameter X_RESET_THRESHOLD = 10'd0; // Reset when completely off screen left
    parameter Y_BASELINE 	    = 10'd315; // The fixed Y baseline (from top.v player Y start)
    parameter Y_MIN_START       = Y_BASELINE - OBSTACLE_HEIGHT; // Top edge of the obstacle at baseline
    localparam Y_STEP_SIZE      = OBSTACLE_X_SPEED; // Vertical step size (matches X speed for smoother arc)

    // Assign width/height for external use
    assign obstacle_width       = OBSTACLE_WIDTH;
    assign obstacle_height      = OBSTACLE_HEIGHT;

    // The maximum displacement must be calculated dynamically since y_amplitude_in is a wire, not a parameter.
    wire [9:0] y_max_displacement = Y_INITIAL_OFFSET + y_amplitude_in;
    
    // --- State Register Update (Sequential) ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            state <= S_WAIT; // Start in the waiting state
        end else if (game_en) begin // Only update state on game clock pulse
            state <= next_state;
        end
    end

    // --- Next State Logic (Combinational) ---
    always @(*) begin
        next_state = state; // Default to staying in the current state
        
        case (state)
            S_WAIT: begin
                // Transition to SPAWN when the wait timer is complete
                if (wait_complete) begin
                    next_state = S_SPAWN;
                end
            end
            
            S_SPAWN: begin
                // Transition to FLYING once the obstacle is fully on-screen
                if (obstacle_x_pos < MAX_X) begin
                    next_state = S_FLYING;
                end
                // If it collides during spawn (unlikely), reset to WAIT
                else if (collision) begin
                    next_state = S_WAIT;
                end
            end
            
            S_FLYING: begin
                // Conditions to return to WAIT state:
                // 1. Collision occurred
                // 2. Obstacle moves completely off-screen left (X_RESET_THRESHOLD)
                // 3. Arc is complete (falling phase and hit the baseline)
                if (collision || obstacle_x_pos <= X_RESET_THRESHOLD || 
                    ((arc_state == 2'b10) && (y_offset <= Y_STEP_SIZE))) begin 
                    
                    next_state = S_WAIT;
                end
            end
            
            default: next_state = S_WAIT;
        endcase
    end


    // --- Output and Action Logic (Sequential) ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            obstacle_x_pos <= X_START_POS; 
            obstacle_y_pos <= Y_MIN_START - Y_INITIAL_OFFSET;
            y_offset       <= Y_INITIAL_OFFSET; 
            arc_state      <= 2'b01; // Default arc state to PUSH
            wait_counter   <= 8'd0;  // Reset counter
            
        end else if (game_en) begin
            // Default: retain position if not in a movement state
            obstacle_x_pos <= obstacle_x_pos; 
            obstacle_y_pos <= obstacle_y_pos; 
            
            case (state)
                S_WAIT: begin
                    // 1. Position: Keep off-screen and static
                    obstacle_x_pos <= X_START_POS; 
                    
                    // 2. Timer: Count up until wait_complete is true
                    if (!wait_complete) begin
                        wait_counter <= wait_counter + 8'd1;
                    end
                    
                    // 3. Reset Arc Logic for the next spawn
                    y_offset <= Y_INITIAL_OFFSET; 
                    arc_state <= 2'b01; 
                end
                
                S_SPAWN: begin
                    // 1. Movement: Move left (just like flying)
                    obstacle_x_pos <= obstacle_x_pos - OBSTACLE_X_SPEED;
                    
                    // 2. Timer: Reset timer immediately
                    wait_counter <= 8'd0;
                    
                    // 3. Y Position: Calculate using the arc logic, but without changing arc_state/y_offset yet
                    obstacle_y_pos <= Y_MIN_START - y_offset; 
                end
                
                S_FLYING: begin
                    // 1. Horizontal Movement (Moving Left)
                    obstacle_x_pos <= obstacle_x_pos - OBSTACLE_X_SPEED;
                    
                    // 2. Vertical Arc Movement (Arc Sub-State Machine)
                    case (arc_state)
                        2'b01: begin // PUSH / Ascending
                            if (y_offset < y_max_displacement) begin
                                y_offset <= y_offset + Y_STEP_SIZE; 
                            end else begin
                                arc_state <= 2'b10; // Reached peak, switch to FALL
                            end
                        end
                        2'b10: begin // FALL / Descending
                            y_offset <= y_offset - Y_STEP_SIZE;
                        end
                        default: arc_state <= 2'b10; // Failsafe
                    endcase
                    
                    // 3. Final Y Position Calculation
                    // The obstacle's top edge (Y_MIN_START) is offset UP by subtracting y_offset.
                    obstacle_y_pos <= Y_MIN_START - y_offset; 
                end
                
                default: begin
                    // Failsafe
                    obstacle_x_pos <= X_START_POS; 
                    wait_counter <= 8'd0;
                end
            endcase
        end
    end

endmodule