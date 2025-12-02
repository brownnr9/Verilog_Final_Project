module obstacle_control #(
    // Parameters for Obstacle Size and Speed
    parameter OBSTACLE_WIDTH 	= 10'd30,
    parameter OBSTACLE_HEIGHT 	= 10'd30,
    parameter OBSTACLE_Y_SPEED 	= 10'd8 // How many pixels to move per game clock cycle
) (
    input 					clk, 		// 50 MHz clock
    input 					rst, 		// Reset signal (active high)
    input 					game_en,	// Slow clock enable from game_clock_generator

    // Outputs for the renderer and collision detector
    output reg [9:0] 		obstacle_x_pos, 
    output reg [9:0] 		obstacle_y_pos,
    
    // Outputs for collision detector (constant for this module, but exposed)
    output wire [9:0] 		obstacle_width,
    output wire [9:0] 		obstacle_height
);

    // --- Local Constants ---
    parameter MAX_Y 	= 10'd479; // Bottom of the screen
    parameter MIN_Y 	= 10'd0;   // Top of the screen
    parameter MAX_X 	= 10'd639; // Rightmost pixel 

    // Define the threshold for resetting the obstacle
    parameter RESET_THRESHOLD = MAX_Y - OBSTACLE_HEIGHT + 1'b1;

    // Assign width/height for external use
    assign obstacle_width  = OBSTACLE_WIDTH;
    assign obstacle_height = OBSTACLE_HEIGHT;

    // --- Obstacle Movement Logic (Sequential) ---
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            // Initial position:
            obstacle_x_pos <= 10'd300; 
            obstacle_y_pos <= MIN_Y;
        end else if (game_en) begin
            // Check for collision with the bottom of the screen
            if (obstacle_y_pos >= RESET_THRESHOLD) begin
                // Reset to top (start slightly off screen)
                obstacle_y_pos <= MIN_Y; 
                // For simplicity, reset X position to a new location (fixed for now)
                obstacle_x_pos <= 10'd300; 
            end else begin
                // Move down the screen
                obstacle_y_pos <= obstacle_y_pos + OBSTACLE_Y_SPEED;
            end
        end
    end

endmodule