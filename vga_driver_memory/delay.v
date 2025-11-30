module delay(clk,rst,en,done);
input clk;
input rst;
input en;
output reg done;

reg[24:0] count;
reg[2:0] NS;
reg[2:0] S;

parameter START=3'd0,
				CHECK_CT = 3'd1,
				DONE = 3'd2,
				ADD_CT = 3'd3,
				WAIT = 3'd4;
				
always@(posedge clk or negedge rst)
	if(rst==1'b0)
		S<=START;
	else
		S<=NS;

always@(*)
	case(S)
		START: if(en==1'b1)
					NS=CHECK_CT;
				else     
					NS=START;
		CHECK_CT: if(count>=25'd25000000)		//only 25M insteak of 50M because each count goes through 2 states
						NS=DONE;
					else
						NS=ADD_CT;
		ADD_CT: NS = CHECK_CT;
		DONE: NS=WAIT;
		WAIT: NS=START;
	endcase

always@(posedge clk or negedge rst)
	if(rst==1'b0)
	begin
		count<=26'd0;
		done<=1'd0;
	end else
		case(S)
			START:begin
						count<=26'd0;
						done<=1'd0;
					end
			ADD_CT:count<=count+1;
			DONE: done<=1'b1;
		endcase
endmodule