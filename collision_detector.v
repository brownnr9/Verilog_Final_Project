module collision_detector #(
    // Player's Fixed Dimensions (Parameters from Top Module)
    parameter PLAYER_WIDTH 	    = 10'd30,
    parameter PLAYER_BASE_HEIGHT= 10'd30,
    parameter PLAYER_Y 		    = 10'd315
) (
    // Player Position Input (Changes dynamically)
    input [9:0] player_x, 
    input [9:0] player_height, // New: dynamic height input

    // Obstacle Position and Dimensions (Inputs, changes dynamically)
    input [9:0] obstacle_x,
    input [9:0] obstacle_y,
    input [9:0] obstacle_width,
    input [9:0] obstacle_height,

    // Output
    output wire collision_detected
);

    // --- Horizontal Overlap Check ---
    // 1. Player's left edge (player_x) is to the left of the obstacle's right edge (obstacle_x + obstacle_width)
    wire horiz_overlap_A = (player_x < obstacle_x + obstacle_width);
    // 2. Player's right edge (player_x + PLAYER_WIDTH) is to the right of the obstacle's left edge (obstacle_x)
    wire horiz_overlap_B = (player_x + PLAYER_WIDTH > obstacle_x);
    
    wire horizontal_overlap = horiz_overlap_A && horiz_overlap_B;


    // --- Vertical Overlap Check (using dynamic player height) ---
    // Player Top Edge: PLAYER_Y - player_height (since PLAYER_Y is the bottom edge)
    
    // 3. Player's top edge is above the obstacle's bottom edge (obstacle_y + obstacle_height)
    wire vert_overlap_A = (PLAYER_Y - player_height < obstacle_y + obstacle_height);
    // 4. Player's bottom edge (PLAYER_Y) is below the obstacle's top edge (obstacle_y)
    wire vert_overlap_B = (PLAYER_Y > obstacle_y); 

    wire vertical_overlap = vert_overlap_A && vert_overlap_B;


    // --- Final Collision Detection ---
    // Collision requires both horizontal and vertical overlap
    assign collision_detected = horizontal_overlap && vertical_overlap;

endmodule