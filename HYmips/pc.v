// Description: 指令指针寄存器PC
`include "defines.v"

module pc_mod(

	input wire clk,
	input wire rst,
	//跳转指令
	input wire jump_en,
	input wire[31:0] jump_addr,
	input wire[5:0] stop,
	
	output reg[31:0] pc,
	output reg ce
	
);

	always @ (posedge clk) begin
		if (ce == 1'b0) begin
			pc <= 32'h80000000;
		end 
		else begin
			if(stop[0]==`True)begin
			end
			else if(jump_en==1'b1)begin
				pc<=jump_addr;
			end
			else if(stop[0]==`False)begin
	 		pc <= pc + 4'h4;
			end
		end
	end
	
	always @ (posedge clk) begin
		if (rst == 1'b1) begin
			ce <= 1'b0;
		end else begin
			ce <= 1'b1;
		end
	end

endmodule