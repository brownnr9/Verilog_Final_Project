module collision_detector #(
    parameter PLAYER_WIDTH 	    = 10'd30,
    parameter PLAYER_BASE_HEIGHT= 10'd30,
    parameter PLAYER_Y 		    = 10'd315
) (
    input [9:0] player_x, 
    input [9:0] player_height,

    // Obstacle (Red) Inputs
    input [9:0] obstacle_x,
    input [9:0] obstacle_y,
    input [9:0] obstacle_width,
    input [9:0] obstacle_height,

    // Green Box Inputs (NEW)
    input [9:0] green_x,
    input [9:0] green_y,
    input [9:0] green_width,
    input [9:0] green_height,
    input       green_active, // Only collide if it's actually flying

    output wire collision_detected, // Game Over (Red)
    output wire box_caught          // Score/Catch (Green)
);

    // --- Helper Function for Rect Overlap ---
    function check_overlap;
        input [9:0] r1_x, r1_w, r1_y_top, r1_y_bot; // Player
        input [9:0] r2_x, r2_w, r2_y_top, r2_y_bot; // Object
        begin
            check_overlap = (r1_x < r2_x + r2_w) && (r1_x + r1_w > r2_x) &&
                            (r1_y_top < r2_y_bot) && (r1_y_bot > r2_y_top);
        end
    endfunction

    // Player Calculations
    wire [9:0] p_top = PLAYER_Y - player_height;
    wire [9:0] p_bot = PLAYER_Y;

    // 1. Red Obstacle Collision
    assign collision_detected = check_overlap(
        player_x, PLAYER_WIDTH, p_top, p_bot,
        obstacle_x, obstacle_width, obstacle_y, obstacle_y + obstacle_height
    );

    // 2. Green Box Catch
    assign box_caught = green_active && check_overlap(
        player_x, PLAYER_WIDTH, p_top, p_bot,
        green_x, green_width, green_y, green_y + green_height
    );

endmodule