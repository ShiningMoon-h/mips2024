
// 通用寄存器堆，共32个
`include "defines.v"

module regfile(

	input wire clk,
	input wire rst,
	
	//写端口
	input wire			    we,
	input wire[4:0] waddr,
	input wire[31:0]     wdata,
	
	//读端口1
	input wire				re1,
	input wire[4:0] raddr1,
	output reg[31:0]     rdata1,
	
	//读端口2
	input wire				re2,
	input wire[4:0] raddr2,
	output reg[31:0]     rdata2
	
);
	integer i;
	reg[`RegBus]  regs[0:`RegNum-1];
	//写入数据
	always @ (posedge clk) begin
		if (rst == `RstDisable) begin
			if((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
				regs[waddr] = wdata;
			end
		end
		else begin
		for(i=0;i<32;i=i+1)begin
			regs[i]=`ZeroWord;
		end
		end
	end
	//读取数据1
	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata1 = `ZeroWord;
	  end
	    else if(raddr1 == `RegNumLog2'h0) begin
	  		rdata1 = `ZeroWord;
	  end
	  	else if((raddr1==waddr)&&(re1==`True)&&(we==`True)) begin
			rdata1=wdata;
		end
	    else if(re1 == `ReadEnable) begin
	      rdata1 = regs[raddr1];
	  end
	    else begin
	      rdata1 = `ZeroWord;
	  end
	end
	//读取数据2
	always @ (*) begin
		if(rst == `RstEnable) begin
			  rdata2 = `ZeroWord;
	  end
	  	else if(raddr2 == `RegNumLog2'h0) begin
	  		rdata2 = `ZeroWord;
	  end
	  	else if((raddr2==waddr)&&(re2==`True)&&(we==`True)) begin
			rdata2=wdata;
		end
	 	else if(re2 == `ReadEnable) begin
	      rdata2 = regs[raddr2];
	  end
	  	else begin
	      rdata2 = `ZeroWord;
	  end
	end

endmodule