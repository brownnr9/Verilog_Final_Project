module player_control #(
	// Declared parameters with defaults, overridden by top module
    parameter BOX_WIDTH = 10'd30,
    parameter MOVE_STEP = 10'd4
) (
	input 					clk, 		
	input 					rst, 		
    input 					game_en,	//Slow clock enable from game_clock_generator
	input [1:0]				buttons,	//buttons[0]=KEY[0]=Right, buttons[1]=KEY[1]=Left

	output reg [9:0] 		box_x 		// Output: Player's current X position
);

	// --- FSM State Definitions ---
	parameter START 	= 2'b00; 
	parameter CHECK_IN = 2'b01; 
	parameter MOVE_L 	= 2'b10;
	parameter MOVE_R 	= 2'b11;
	
	reg [1:0] S;   // Current State Register 
	reg [1:0] NS;          // Next State Wire

	// --- Global Constants ---
	parameter MAX_X 		= 10'd639; // Rightmost pixel 
	
	// Define Wall Boundaries for Collision Check
	parameter RIGHT_WALL_THRESHOLD = MAX_X - BOX_WIDTH + 10'd1; 
	parameter LEFT_WALL_THRESHOLD  = 10'd0; 
	
	//Invert the inputs because the KEY inputs are  Active-Low
	wire btn_right = ~buttons[0]; 
	wire btn_left  = ~buttons[1]; 

	
	always @(posedge clk or negedge rst)
	begin
		if (rst == 1'b0) 
			S <= START; // Initialize state to START
		else if (game_en) // Only update FSM state on game clock pulse
			S <= NS;
	end
			

	always @(*) 
		case (S)
			START: 
				NS = CHECK_IN;
			
			CHECK_IN: 
				// This is the decision gate
				if (btn_right && !btn_left) 
					NS = MOVE_R;
				else if (btn_left && !btn_right) 
					NS = MOVE_L;
				else 
					NS = CHECK_IN; 
			
			MOVE_R: 
				NS = CHECK_IN;

			MOVE_L: 
				NS = CHECK_IN;
			
			default: NS = START;
		endcase
	
	
	always @(posedge clk or negedge rst)
	begin 
		if (rst == 1'b0) 
			box_x <= 10'd50; // Initial position
		else if (game_en) begin
				case (S) // Use S (current state) here
					MOVE_R: 
						// Check right collision before moving
						if (box_x <= (RIGHT_WALL_THRESHOLD - MOVE_STEP)) 
							box_x <= box_x + MOVE_STEP;
						
					MOVE_L: 
						// Check left collision before moving
						if (box_x >= (LEFT_WALL_THRESHOLD + MOVE_STEP)) 
							box_x <= box_x - MOVE_STEP;
						
					// In START and CHECK_IN, box_x retains its value.
					default: 
						box_x <= box_x; 
					
				endcase
		end
	end

endmodule