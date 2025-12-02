module collision_detector #(
    // Player's Fixed Dimensions (Parameters from Top Module)
    // NOTE: PLAYER_Y is the fixed vertical start position of the player box
    parameter PLAYER_WIDTH 	= 10'd30,
    parameter PLAYER_HEIGHT = 10'd30,
    parameter PLAYER_Y 		= 10'd315
) (
    // Player Position Input (Changes dynamically)
    input [9:0] player_x, 

    // Obstacle Position and Dimensions (Inputs, changes dynamically)
    input [9:0] obstacle_x,
    input [9:0] obstacle_y,
    input [9:0] obstacle_width,
    input [9:0] obstacle_height,

    // Output
    output wire collision_detected
);

    // --- Horizontal Overlap Check ---
    // 1. Player's left edge is to the left of the obstacle's right edge
    wire horiz_overlap_A = (player_x < obstacle_x + obstacle_width);
    // 2. Player's right edge is to the right of the obstacle's left edge
    wire horiz_overlap_B = (player_x + PLAYER_WIDTH > obstacle_x);
    
    wire horizontal_overlap = horiz_overlap_A && horiz_overlap_B;


    // --- Vertical Overlap Check ---
    // 3. Player's top edge is above the obstacle's bottom edge
    wire vert_overlap_A = (PLAYER_Y < obstacle_y + obstacle_height);
    // 4. Player's bottom edge is below the obstacle's top edge
    wire vert_overlap_B = (PLAYER_Y + PLAYER_HEIGHT > obstacle_y);

    wire vertical_overlap = vert_overlap_A && vert_overlap_B;


    // --- Final Collision Detection ---
    // Collision requires both horizontal and vertical overlap
    assign collision_detected = horizontal_overlap && vertical_overlap;

endmodule