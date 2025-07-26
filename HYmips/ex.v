`include "defines.v"

module ex(

	input wire rst,
	
	//来自ID/EX
	input wire[`AluOpBus]         aluop_i,
	input wire[`AluSelBus]        alusel_i,
	input wire[`RegBus]           reg1_i,
	input wire[`RegBus]           reg2_i,
	input wire[`RegAddrBus]       wd_i,
	input wire                    wreg_i,
	input wire             	 delaying_i,//没用
	input wire[`InstAddrBus] delay_addr_i,//延迟槽后一条指令pc
	input wire[`OffsetBus]   offset_i,
	
	output reg[`RegAddrBus]       wd_o,
	output reg                    wreg_o,
	output reg[`RegBus]			  wdata_o,
	output wire[`AluOpBus]       memop_o,
	output wire[`RegBus]         mem_addr_o,
	output wire[`RegBus]         reg2_o,

	output reg stop_o
	
);
	reg[31:0] logicout;
	reg[31:0] arithres;

	reg is_reg1_less_reg2;
	reg[31:0] sub;
	always@(*)begin
		sub=reg1_i-reg2_i;
		is_reg1_less_reg2=sub[31]?1'b1:1'b0;
	end
	wire[31:0] reg1_m;//乘法负数取补码
	wire[31:0] reg2_m;
	wire[63:0] temp_mul_res;
	reg[63:0] mul_res;
	assign reg1_m=(reg1_i[31]==1'b1)?(~reg1_i+1'b1):reg1_i;
	assign reg2_m=(reg2_i[31]==1'b1)?(~reg2_i+1'b1):reg2_i;
	assign temp_mul_res=reg1_m*reg2_m;
	always@(*)begin
		if(rst)
		mul_res={`ZeroWord,`ZeroWord};
		else if(reg1_i[31]^reg2_i[31]==1'b1)
		mul_res=(~temp_mul_res+1'b1);
		else if(reg1_i[31]^reg2_i[31]==1'b0)
		mul_res=temp_mul_res;
		else
		mul_res={`ZeroWord,`ZeroWord};
	end
	assign memop_o = aluop_i;
	assign reg2_o = reg2_i;
	assign mem_addr_o = reg1_i+{{16{offset_i[15]}},offset_i};

	always @ (*) begin
		if(rst == `RstEnable) begin
			logicout = `ZeroWord;
		end else begin
			logicout = `ZeroWord;
			case (aluop_i)
				`ALUOP_OR:begin
					logicout = reg1_i | reg2_i;
				end
				`ALUOP_AND:begin
					logicout = reg1_i & reg2_i;
				end
				`ALUOP_XOR:begin
					logicout=reg1_i^reg2_i;
				end
				`ALUOP_SLL:begin
					logicout=reg2_i<<reg1_i[4:0];
				end
				`ALUOP_SRL:begin
					logicout=reg2_i>>reg1_i[4:0];
				end
				`ALUOP_SLLV:begin
					logicout=reg2_i<<reg1_i;
				end
				`ALUOP_NOP:begin
					logicout=reg1_i;
				end
				default:begin
				end
			endcase
		end    //if
	end      //always
	always@(*)begin
		if(rst==`RstEnable)begin
			arithres = `ZeroWord;
		end 
		else begin
			arithres = `ZeroWord;
			case(aluop_i)
				`ALUOP_ADDU:begin
					arithres=reg1_i+reg2_i;
				end
				`ALUOP_SLT:begin
					arithres=is_reg1_less_reg2;
				end
				`ALUOP_MUL:begin
					arithres=mul_res;
				end
				default:begin
				end
			endcase
		end
	end

 always @ (*) begin
	if(rst==`True)begin
		wd_o=5'b00000;
		wreg_o=`False;
	end
	else begin
	 wd_o = wd_i;
	 wreg_o = wreg_i;
	 case (alusel_i) 
	 	`RES_LOGIC:begin
	 		wdata_o = logicout;
	 	end
		`RES_ARITHMETIC:begin
			wdata_o=arithres;
		end
		`RES_JUMP:begin
			wdata_o=delay_addr_i;
		end
	 	default: begin
	 		wdata_o = `ZeroWord;
	 	end
	 endcase
	end
 end	

endmodule