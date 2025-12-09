module player_control #(
    parameter BOX_WIDTH = 10'd30,
    parameter BASE_HEIGHT = 10'd30 // Needed to calculate box count
) (
	input 					clk, 		
	input 					rst, 		
    input 					game_en,
	input [1:0]				buttons,	// [0]=Right, [1]=Left
    input [9:0]             current_height, // NEW: Used for speed penalty

	output reg [9:0] 		box_x
);
    // --- Speed Settings ---
    localparam SPEED_FAST   = 10'd6; // 0 Boxes
    localparam SPEED_NORMAL = 10'd4; // 1 Box
    localparam SPEED_SLOW   = 10'd2; // 2 Boxes

    reg [9:0] current_move_step;

    // Determine Speed based on Height/Box Count
    always @(*) begin
        if (current_height <= BASE_HEIGHT) 
            current_move_step = SPEED_FAST;
        else if (current_height <= BASE_HEIGHT + BASE_HEIGHT)
            current_move_step = SPEED_NORMAL;
        else 
            current_move_step = SPEED_SLOW;
    end

    // --- FSM State Definitions ---
	parameter START 	= 2'b00; 
	parameter CHECK_IN  = 2'b01; 
	parameter MOVE_L 	= 2'b10;
	parameter MOVE_R 	= 2'b11;
	
	reg [1:0] S; 
	reg [1:0] NS;

	parameter MAX_X 		= 10'd639;
	parameter RIGHT_WALL_THRESHOLD = MAX_X - BOX_WIDTH + 10'd1;
	parameter LEFT_WALL_THRESHOLD  = 10'd0; 
	
	wire btn_right = ~buttons[0];
	wire btn_left  = ~buttons[1]; 

	always @(posedge clk or negedge rst)
	begin
		if (rst == 1'b0) S <= START;
		else if (game_en) S <= NS;
	end

	always @(*) 
		case (S)
			START: NS = CHECK_IN;
			CHECK_IN: 
				if (btn_right && !btn_left) NS = MOVE_R;
				else if (btn_left && !btn_right) NS = MOVE_L;
				else NS = CHECK_IN; 
			MOVE_R: NS = CHECK_IN;
			MOVE_L: NS = CHECK_IN;
			default: NS = START;
		endcase
	
	always @(posedge clk or negedge rst)
	begin 
		if (rst == 1'b0) 
			box_x <= 10'd50;
		else if (game_en) begin
				case (S) 
					MOVE_R: 
                        // Use current_move_step here
						if (box_x <= (RIGHT_WALL_THRESHOLD - current_move_step)) 
							box_x <= box_x + current_move_step;
					MOVE_L: 
                        // Use current_move_step here
						if (box_x >= (LEFT_WALL_THRESHOLD + current_move_step)) 
							box_x <= box_x - current_move_step;
					default: 
						box_x <= box_x; 
				endcase
		end
	end

endmodule