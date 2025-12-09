module game_state_machine(
    input clk,
    input rst,          
    input key_left,     
    input key_right,    
    input key_select,   
    input key_back,     
    input collision,    
    
    output reg [1:0] state,
    output reg       menu_selection,
    output reg [1:0] current_hp 
);
    parameter S_START        = 2'b00;
    parameter S_PLAYING      = 2'b01;
    parameter S_INSTRUCTIONS = 2'b10;
    parameter S_GAME_OVER    = 2'b11;

    reg k_l_q, k_r_q, k_s_q, k_b_q;
    reg col_q; 

    wire press_left   = k_l_q && !key_left;
    wire press_right  = k_r_q && !key_right;
    wire press_select = k_s_q && !key_select;
    wire press_back   = k_b_q && !key_back;
    wire collision_edge = collision && !col_q;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= S_START;
            menu_selection <= 1'b0;
            current_hp <= 2'd3; 
            k_l_q <= 1'b1; k_r_q <= 1'b1; k_s_q <= 1'b1; k_b_q <= 1'b1;
            col_q <= 1'b0;
        end else begin
            k_l_q <= key_left;
            k_r_q <= key_right;
            k_s_q <= key_select;
            k_b_q <= key_back;
            col_q <= collision;

            case (state)
                S_START: begin
                    current_hp <= 2'd3; // FORCE HP to 3 while in menu
                    if (press_right || press_left) menu_selection <= ~menu_selection; 
                    if (press_select) begin
                        if (menu_selection == 1'b0) state <= S_PLAYING;
                        else state <= S_INSTRUCTIONS;
                    end
                end

                S_INSTRUCTIONS: begin
                    if (press_back) state <= S_START;
                end

                S_PLAYING: begin
                    if (collision_edge) begin
                        if (current_hp > 2'd1) begin
                            current_hp <= current_hp - 2'd1;
                        end else begin
                            current_hp <= 2'd0;
                            state <= S_GAME_OVER;
                        end
                    end
                end

                S_GAME_OVER: begin
                    if (press_select || press_back) begin
                        state <= S_START;
                        menu_selection <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule