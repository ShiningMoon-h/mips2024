`include "defines.v"

module id_ex(

	input wire clk,
	input wire rst,
	input wire[5:0] stop,

	//ID浼犳潵
	input wire[`AluOpBus]         id_aluop,
	input wire[`AluSelBus]        id_alusel,
	input wire[`RegBus]           id_reg1,
	input wire[`RegBus]           id_reg2,
	input wire[`RegAddrBus]       id_wd,
	input wire                    id_wreg,
	input wire[15:0]              id_offset,
		//寤惰繜妲借緭鍏?
	input wire              id_nextdelay,
	input wire              id_delaying,
	input wire[`InstAddrBus] id_delay_addr,

	//浼犲埌EX
	output reg[`AluOpBus]         ex_aluop,
	output reg[`AluSelBus]        ex_alusel,
	output reg[`RegBus]           ex_reg1,
	output reg[`RegBus]           ex_reg2,
	output reg[`RegAddrBus]       ex_wd,
	output reg                    ex_wreg,
	output reg[`OffsetBus]        ex_offset,
		//寤惰繜妲借緭鍑?
	output reg               nextid_nextdelay,
	output reg               ex_delaying,
	output reg[`InstAddrBus] ex_delay_addr
);

	always @ (posedge clk) begin
		if (rst == `RstEnable) begin
			ex_aluop <= `ALUOP_NOP;
			ex_alusel <= `RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			nextid_nextdelay<=`False;
			ex_delaying<=`False;
			ex_delay_addr<=`ZeroWord;
			ex_offset<=`HalfZero;
		end 
		else if (stop[2]==`True&&stop[3]==`False) begin
			ex_aluop <= `ALUOP_NOP;
			ex_alusel <= `RES_NOP;
			ex_reg1 <= `ZeroWord;
			ex_reg2 <= `ZeroWord;
			ex_wd <= `NOPRegAddr;
			ex_wreg <= `WriteDisable;
			nextid_nextdelay<=`False;
			ex_delaying<=`False;
			ex_delay_addr<=`ZeroWord;
			ex_offset<=`HalfZero;
		end 
		else if(stop[2]==`False)begin		
			ex_aluop <= id_aluop;
			ex_alusel <= id_alusel;
			ex_reg1 <= id_reg1;
			ex_reg2 <= id_reg2;
			ex_wd <= id_wd;
			ex_wreg <= id_wreg;	
			nextid_nextdelay<=id_nextdelay;
			ex_delaying<=id_delaying;
			ex_delay_addr<=id_delay_addr;
			ex_offset<=id_offset;
		end
	end
	
endmodule