module vga_driver_memory #(
    parameter BOX_WIDTH 	= 10'd30,
    parameter BOX_BASE_HEIGHT = 10'd30,
    parameter BOX_Y_START 	= 10'd315
) (
    // Inputs from Control Modules
    input [9:0] player_x,
    input [9:0] player_height, // New: dynamic height input
    input [9:0] obstacle_x,
    input [9:0] obstacle_y,
    input [9:0] obstacle_width,
    input [9:0] obstacle_height,
    
    // Inputs from VGA Timing Module
    input [9:0] x,
    input [9:0] y,
    input active_pixels,

    // Outputs (Color for the current pixel)
    output reg [7:0] VGA_R,
    output reg [7:0] VGA_G,
    output reg [7:0] VGA_B
);

    // --- Color Definitions ---
    parameter C_BLACK   = 8'h00;
    parameter C_WHITE   = 8'hFF;
    parameter C_BLUE    = 8'hFF; // Full blue component (8'hFF)
    parameter C_RED     = 8'hFF;

    // --- Player Box Dimensions based on dynamic height ---
    // Player's top edge (Y coordinate, closer to 0)
    // The player box bottom is fixed at BOX_Y_START, so the top moves up with height accumulation.
    wire [9:0] player_y_top = BOX_Y_START - player_height + 1; 

    // --- Player Visibility Check ---
    wire is_player_x = (x >= player_x) && (x < player_x + BOX_WIDTH);
    // The player's vertical range is from the dynamic top edge to the fixed bottom edge
    wire is_player_y = (y >= player_y_top) && (y <= BOX_Y_START); 
    
    wire is_player = is_player_x && is_player_y;

    // --- Obstacle Visibility Check ---
    wire is_obstacle_x = (x >= obstacle_x) && (x < obstacle_x + obstacle_width);
    wire is_obstacle_y = (y >= obstacle_y) && (y < obstacle_y + obstacle_height);

    wire is_obstacle = is_obstacle_x && is_obstacle_y;

    // --- Rendering Logic ---
    always @(*) begin
        if (active_pixels) begin
            // Priority: Draw Obstacle (Red)
            if (is_obstacle) begin
                VGA_R = C_RED;
                VGA_G = C_BLACK;
                VGA_B = C_BLACK;
            // Next Priority: Draw Player (Blue)
            end else if (is_player) begin
                VGA_R = C_BLACK;
                VGA_G = C_BLACK;
                VGA_B = C_BLUE; // Draw the player blue
            // Background: White
            end else begin
                VGA_R = C_WHITE;
                VGA_G = C_WHITE;
                VGA_B = C_WHITE;
            end
        end else begin
            // Outside of active display area (blanking)
            VGA_R = C_BLACK;
            VGA_G = C_BLACK;
            VGA_B = C_BLACK;
        end
    end

endmodule