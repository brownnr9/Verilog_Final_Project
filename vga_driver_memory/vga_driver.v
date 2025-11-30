module vga_driver(

input clk, // 50 MHz input clock
input rst, // Reset signal (active high)

output reg vga_clk, // 25 MHz pixel clock (50MHz / 2)

output reg hsync, // horizontal sync (VGA_HS)
output reg vsync, // vertical sync (VGA_VS)

output reg active_pixels, // high when drawing in the 640x480 region

output reg [9:0]xPixel, // current x counter
output reg [9:0]yPixel, // current y counter

output reg VGA_BLANK_N,	// VGA BLANK (Active Low)
output reg VGA_SYNC_N	// VGA SYNC (Active Low, not typically used in standard mode)
);

// Timings for 640x480 @ 60Hz
// Horizontal Timings
parameter HA_END = 10'd639; // End of active pixels (640 total)
parameter HS_STA = HA_END + 16; // Start of HSYNC after front porch
parameter HS_END = HS_STA + 96; // End of HSYNC
parameter WIDTH	= 10'd799; // Total line width (800 total clocks)

// Vertical Timings
parameter VA_END = 10'd479; // End of active pixels (480 total lines)
parameter VS_STA = VA_END + 10; // Start of VSYNC after front porch
parameter VS_END = VS_STA + 2; // End of VSYNC
parameter HEIGHT = 10'd524; // Total frame height (525 total lines)


// --- Combinational Logic for Sync and Active Area ---
always @(*)
begin	
	// HSYNC is active low during the HSYNC pulse
	hsync = ~((xPixel >= HS_STA) && (xPixel < HS_END));
	
	// VSYNC is active low during the VSYNC pulse
	vsync = ~((yPixel >= VS_STA) && (yPixel < VS_END));
	
	// active_pixels is high only when inside the 640x480 box
	active_pixels = (xPixel <= HA_END && yPixel <= VA_END);	
	
	// VGA_BLANK_N is active high when active_pixels is high
	VGA_BLANK_N = active_pixels;
	
	// VGA_SYNC_N is typically held high for standard timing
	VGA_SYNC_N = 1'b1; 
end


// --- Sequential Logic for Pixel Counters and Clock Divider ---
always @(posedge clk or negedge rst)
begin
	if (rst == 1'b0)
	begin
		vga_clk <= 1'b0;
		xPixel <= 10'd0;
		yPixel <= 10'd0;
	end
	else
	begin
		// The vga_clk is the 25MHz pixel clock (50MHz / 2)
		vga_clk = ~vga_clk; 
		
		if (vga_clk == 1'b1) // Increment counters on the rising edge of the 25MHz pixel clock
		begin
			if(xPixel == WIDTH) // End of a horizontal line
			begin
				xPixel <= 10'd0; // Reset X counter
				if(yPixel == HEIGHT) // End of a vertical frame
				begin
					yPixel <= 10'd0; // Reset Y counter (start of new frame)
				end
				else
				begin
					yPixel <= yPixel + 1'b1; // Move to the next line
				end
			end
			else
			begin
				xPixel <= xPixel + 1'b1; // Move to the next pixel
			end
		end
	end
end

endmodule