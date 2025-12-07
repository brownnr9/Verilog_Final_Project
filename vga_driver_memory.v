module vga_driver_memory #(
    parameter BOX_WIDTH 	= 10'd30,
    parameter BOX_BASE_HEIGHT = 10'd30,
    parameter BOX_Y_START 	= 10'd345,
    parameter BANK_X_START 	= 10'd50,   // Updated to left side
    parameter BANK_WIDTH 	= 10'd60
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
    input [7:0] bank_level, 
    input active_pixels,

    // Outputs (Color for the current pixel)
    output reg [7:0] VGA_R,
    output reg [7:0] VGA_G,
    output reg [7:0] VGA_B
);

    // --- Color Definitions ---
    parameter C_BLACK   = 8'h00;
    parameter C_WHITE   = 8'hFF;
    parameter C_BLUE    = 8'hFF;
    parameter C_RED     = 8'hFF;
    parameter C_GREEN   = 8'hFF; // Green for the bank

    // --- Player Box Dimensions based on dynamic height ---
    wire [9:0] player_y_top = BOX_Y_START - player_height + 1; 

    // --- Player Visibility Check ---
    wire is_player_x = (x >= player_x) && (x < player_x + BOX_WIDTH);
    wire is_player_y = (y >= player_y_top) && (y <= BOX_Y_START); 
    wire is_player = is_player_x && is_player_y;

    // --- Obstacle Visibility Check ---
    wire is_obstacle_x = (x >= obstacle_x) && (x < obstacle_x + obstacle_width);
    wire is_obstacle_y = (y >= obstacle_y) && (y < obstacle_y + obstacle_height);
    wire is_obstacle = is_obstacle_x && is_obstacle_y;
    
    // --- Bank Visibility Check (NEW) ---
    // The bank is a 1-segment high box at the baseline
    wire is_bank_x = (x >= BANK_X_START) && (x < BANK_X_START + BANK_WIDTH);
    // Bank Y is from the baseline up one box height
    wire is_bank_y = (y >= (BOX_Y_START - BOX_BASE_HEIGHT + 1)) && (y <= BOX_Y_START); 
    wire is_bank = is_bank_x && is_bank_y;

    // --- Rendering Logic ---
    always @(*) begin
        if (active_pixels) begin
            // Priority 1: Draw Obstacle (Red)
            if (is_obstacle) begin
                VGA_R = C_RED;
                VGA_G = C_BLACK;
                VGA_B = C_BLACK;
            // Priority 2: Draw Player (Blue)
            end else if (is_player) begin
                VGA_R = C_BLACK;
                VGA_G = C_BLACK;
                VGA_B = C_BLUE; 
            // Priority 3: Draw Bank (Green) - Should be drawn behind player/obstacle
            end else if (is_bank) begin
                VGA_R = C_BLACK;
                VGA_G = C_GREEN;
                VGA_B = C_BLACK;
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