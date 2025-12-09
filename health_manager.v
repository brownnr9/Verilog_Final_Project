module health_manager (
    input clk,
    input rst,
    input game_en,
    input collision,
    
    output reg [1:0] lives,
    output wire is_dead
);

    parameter MAX_LIVES = 2'd3;
    // Cooldown duration: e.g., 20 game_en ticks (approx 1.5 seconds)
    parameter DAMAGE_COOLDOWN = 8'd20; 

    reg [7:0] cooldown_timer;
    wire in_cooldown = (cooldown_timer > 0);

    assign is_dead = (lives == 2'd0);

    always @(posedge clk or negedge rst) begin
        if (rst == 1'b0) begin
            lives <= MAX_LIVES;
            cooldown_timer <= 8'd0;
        end else if (game_en) begin
            
            // If cooldown is active, decrement it
            if (in_cooldown) begin
                cooldown_timer <= cooldown_timer - 8'd1;
            end
            
            // If collision detected AND not in cooldown AND still alive
            else if (collision && !in_cooldown && lives > 0) begin
                lives <= lives - 2'd1;
                cooldown_timer <= DAMAGE_COOLDOWN; // Start invulnerability
            end
        end
    end

endmodule