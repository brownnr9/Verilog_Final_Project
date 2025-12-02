module game_clock_generator (
	input 					clk, 		// 50 MHz input clock
	input 					rst, 		// Reset signal (active high)

	output wire 			game_en 	// Output: Slow clock enable signal (~12 Hz)
);

	// --- Rate Limiter (Game Clock) ---
	// 50MHz / 2^20 = ~___ updates per second
	reg [19:0] move_counter = 20'd0;
	parameter MOVE_SPEED_DIV = 20'd1048576; 
	
	// Game clock enable signal
	assign game_en = (move_counter == (MOVE_SPEED_DIV - 1'b1));

	// Rate Limiter Logic (Always Running)
	always @(posedge clk or negedge rst) begin
		if (rst == 1'b0) begin
			move_counter <= 20'd0;
		end else begin
			move_counter <= move_counter + 1'b1;
			if (game_en) begin
				move_counter <= 20'd0; // Reset counter when movement is enabled
			end
		end
	end

endmodule