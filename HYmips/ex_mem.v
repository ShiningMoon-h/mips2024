`include "defines.v"

module ex_mem(

	input wire clk,
	input wire rst,
	input wire[5:0] stop,
	
	
	//来自执行阶段的信息	
	input wire[`RegAddrBus]       ex_wd,
	input wire                    ex_wreg,
	input wire[`RegBus]           ex_wdata, 
	
	input wire[`AluOpBus]       ex_memop,
	input wire[`RegBus]         ex_maddr,
	input wire[`RegBus]         ex_reg2,
	
	//送到访存阶段的信息
	output reg[`RegAddrBus]      mem_wd,
	output reg                   mem_wreg,
	output reg[`RegBus]			 mem_wdata,
	output reg[`AluOpBus]       mem_memop,
	output reg[`RegBus]         mem_maddr,
	output reg[`RegBus]         mem_reg2

	
	
);


	always @ (posedge clk) begin
		if(rst == `RstEnable) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `False;
		    mem_wdata <= `ZeroWord;
			mem_memop<=`ALUOP_NOP;
			mem_maddr<=`ZeroWord;
			mem_reg2<=`ZeroWord;
		end
		else if(stop[3]==`True&&stop[4]==`False) begin
			mem_wd <= `NOPRegAddr;
			mem_wreg <= `WriteDisable;
		    mem_wdata <= `ZeroWord;
			mem_memop<=`ALUOP_NOP;
			mem_maddr<=`ZeroWord;
			mem_reg2<=`ZeroWord; 
		end
		else if(stop[3]==`False)begin
			mem_wd <= ex_wd;
			mem_wreg <= ex_wreg;
			mem_wdata <= ex_wdata;
			mem_memop<=ex_memop;
			mem_maddr<=ex_maddr;
			mem_reg2<=ex_reg2;		
		end    //if
	end      //always
			

endmodule