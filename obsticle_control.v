module obstacle_control #(
    // Parameters for Obstacle Size and Speed
    parameter OBSTACLE_WIDTH 	= 10'd30,
    parameter OBSTACLE_HEIGHT 	= 10'd30,
    parameter OBSTACLE_X_SPEED 	= 10'd5,    // Horizontal speed (moving left)
    // Removed Y_AMPLITUDE parameter
    parameter Y_INITIAL_OFFSET  = 10'd50    // Initial height for the obstacle
) (
    input 					clk, 		// 50 MHz clock
    input 					rst, 		// Reset signal (active high)
    input 					game_en,	// Slow clock enable from game_clock_generator
	input						collision,  // Input from collision detector
	
    // NEW DYNAMIC INPUT: Amplitude from the Random Generator
    input [9:0]             y_amplitude_in, 
	
    // Outputs for the renderer and collision detector
    output reg [9:0] 		obstacle_x_pos, 
    output reg [9:0] 		obstacle_y_pos,
    
    // Outputs for collision detector (constant for this module, but exposed)
    output wire [9:0] 		obstacle_width,
    output wire [9:0] 		obstacle_height
);

    // --- Local Constants ---
    parameter MAX_X             = 10'd639; // Rightmost pixel
    parameter X_START_POS       = MAX_X + 10'd1; // Off-screen right position for spawn
    parameter X_RESET_THRESHOLD = 10'd0 ; // Reset when completely off screen left
    parameter Y_BASELINE 	    = 10'd315; // The fixed Y baseline (from top.v player Y start)
    parameter Y_MIN_START       = Y_BASELINE - OBSTACLE_HEIGHT; // Top edge of the obstacle at baseline
    localparam Y_STEP_SIZE      = 10'd3; // Vertical step size

    // --- Arc Control Registers ---
    reg  [9:0] y_offset;        // Current vertical displacement from the baseline (Total height)
    // 2-bit state machine for the arc: 2'b01=PUSH/ASCEND, 2'b10=FALL/DESCEND
    reg  [1:0] arc_state;       
    
    // Assign width/height for external use
    assign obstacle_width       = OBSTACLE_WIDTH;
    assign obstacle_height      = OBSTACLE_HEIGHT;


    // --- Obstacle Movement Logic (Sequential) ---
    always @(posedge clk or negedge rst) begin
        // The maximum displacement must be calculated dynamically since y_amplitude_in is a wire, not a parameter.
        reg [9:0] y_max_displacement; 
        y_max_displacement = Y_INITIAL_OFFSET + y_amplitude_in;
        
        if (rst == 1'b0) begin
            // Initialization: Start off-screen right
            obstacle_x_pos <= X_START_POS; 
            
            // Start high up and ready for the push phase
            y_offset       <= Y_INITIAL_OFFSET; 
            arc_state      <= 2'b01; // Start in the PUSH/Ascending phase
            
            // Initial Y position calculation
            obstacle_y_pos <= Y_MIN_START - Y_INITIAL_OFFSET; 
            
        end else if (game_en) begin
            
            // The arc is complete when we are falling (2'b10) and hit the baseline (y_offset <= step size).
            
            // B. If Collision OR Hit Left Side OR Arc is Complete (Reset Condition)
            if (collision || obstacle_x_pos <= X_RESET_THRESHOLD || 
                ((arc_state == 2'b10) && (y_offset <= Y_STEP_SIZE))) begin 
                
                // Reset X position off-screen right
                obstacle_x_pos <= X_START_POS; 
                
                // Reset arc parameters for next spawn (start fresh, PUSH phase)
                y_offset <= Y_INITIAL_OFFSET; 
                arc_state <= 2'b01; 
                
                // Y position is calculated dynamically below
            
            // C. Flying State (Horizontal and Vertical movement)
            end else begin 
                
                // 1. Horizontal Movement (Moving Left)
                obstacle_x_pos <= obstacle_x_pos - OBSTACLE_X_SPEED;
                
                // 2. Vertical Arc Movement (State Machine)
                case (arc_state)
                    2'b01: begin // PUSH / Ascending
                        // Use the dynamically calculated maximum displacement
                        if (y_offset < y_max_displacement) begin
                            y_offset <= y_offset + Y_STEP_SIZE; 
                        end else begin
                            arc_state <= 2'b10; // Reached peak, switch to FALL
                        end
                    end
                    2'b10: begin // FALL / Descending
                        // Move down until the ARC_COMPLETE condition triggers the main reset logic
                        y_offset <= y_offset - Y_STEP_SIZE;
                    end
                    default: arc_state <= 2'b10; // Failsafe: force falling
                endcase
                
                // 3. Final Y Position Calculation
                // The obstacle's top edge (Y_MIN_START) is offset UP by subtracting y_offset.
                obstacle_y_pos <= Y_MIN_START - y_offset; 
                
            end
        end
    end

endmodule