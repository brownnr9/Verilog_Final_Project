module player_height_manager #(
    parameter BASE_HEIGHT = 10'd30 
) (
    input 					clk, 		
    input 					rst, 		
    input 					game_en,	
	input						box_caught,     // Caught a green box
	input						box_dropped_in, // Dropped at bank
	
    output reg [9:0] 		current_height 
);
    
    // Max height = Base + 2 Boxes
    parameter MAX_HEIGHT = BASE_HEIGHT + (10'd2 * BASE_HEIGHT);

    reg caught_flag_q; 

    // Edge detection for catching
    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            caught_flag_q <= 1'b0;
        end else if (game_en) begin
            caught_flag_q <= box_caught;
        end
    end

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            current_height <= BASE_HEIGHT;
        end else if (game_en) begin
            
            // 1. CATCH: If caught something AND not already full (Max 2 boxes)
            if (box_caught && !caught_flag_q && current_height < MAX_HEIGHT) begin
                current_height <= current_height + BASE_HEIGHT;
            end 
            // 2. DROP: If dropping at bank AND has at least 1 box
            else if (box_dropped_in && current_height > BASE_HEIGHT) begin 
                current_height <= current_height - BASE_HEIGHT;
            end
        end
    end

endmodule