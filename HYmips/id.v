`include "defines.v"

module id(

	input wire       rst,
	input wire[31:0] pc_i,
	input wire[31:0] inst_i,
	//regfile's input
	input wire[31:0]           reg1_data_i,
	input wire[31:0]           reg2_data_i,
	//ouput to regfile
	output reg                    reg1_read_o,
	output reg                    reg2_read_o,     
	output reg[4:0]       reg1_addr_o,
	output reg[4:0]       reg2_addr_o, 	      
	
	//to EX
	output reg[7:0]         aluop_o,
	output reg[2:0]         alusel_o,
	output reg[31:0]           reg1_o,
	output reg[31:0]           reg2_o,
	output reg[4:0]               wd_o,
	output reg                    wreg_o,
	output wire[15:0]             offset_o,
	//旁路
	input wire              ex_en_i,
	input wire[31:0]     ex_wdata_i,
	input wire[4:0] ex_waddr_i,
	
	input wire              mem_en_i,
	input wire[31:0]     mem_wdata_i,
	input wire[4:0] mem_waddr_i,
	//跳转
		//跳转指令
	output reg is_jump_o,
	output reg[31:0] jump_addr_o,
	output reg is_nextdelay_o,//ce_next
		//延迟槽
	input wire delaying_i,//没用
	output reg is_delay_o,//没用
	output reg[31:0] delay_addr_o,//延迟槽后一条指令pc

	input wire[7:0] memop_i,
	output wire stop_o
);

  wire[5:0] op = inst_i[31:26];
  wire[4:0] rs = inst_i[25:21];
  wire[4:0] rt = inst_i[20:16];
  wire[4:0] rd = inst_i[15:11];
  wire[4:0] sa = inst_i[10:6];
  wire[5:0] fun = inst_i[5:0];
  reg[31:0] imm;//特殊值
  reg instvalid;

	wire loading;
	reg loadstop_reg1;
	reg loadstop_reg2;

	assign offset_o = inst_i[15:0];
	wire[31:0] pc_delay=pc_i+ 4'h4;
	wire last_lw;
	wire last_lb;
	assign last_lw=(memop_i==`MEMOP_LW)?`True:`False;
	assign last_lb=(memop_i==`MEMOP_LB)?`True:`False;
	assign loading=last_lw|last_lb;

	always @ (*) begin	
		if (rst == 1'b1) begin
			aluop_o = `ALUOP_NOP;
			alusel_o = `RES_NOP;
			wreg_o = `False;
			instvalid = `False;
			reg1_read_o = 1'b0;
			reg2_read_o = 1'b0;
			wd_o = 5'b00000;
			reg1_addr_o = 5'b00000;
			reg2_addr_o = 5'b00000;
			imm = 32'h0;

			jump_addr_o=`ZeroWord;//jump
			delay_addr_o=`ZeroWord;
			is_jump_o=`False;
			is_nextdelay_o=`False;
	  	end 
	  	else begin
			wreg_o = `False;
			instvalid = `False;
			reg1_read_o = 1'b0;
			reg2_read_o = 1'b0;
			is_jump_o=`False;
			is_nextdelay_o=`False;
			case (op)
		  	`OP_ORI:begin     //ORI
				aluop_o = `ALUOP_OR;
		  		alusel_o = `RES_LOGIC;
				wreg_o = `True;
				instvalid = `True;
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {16'h0, inst_i[15:0]};
				wd_o = rt;//rename wd_o
				reg1_addr_o = rs;    //rs
		  	end
			`OP_XORI:begin
				aluop_o = `ALUOP_XOR;
		  		alusel_o = `RES_LOGIC;
				wreg_o = `True;
				instvalid = `True;
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {16'h0, inst_i[15:0]};
				wd_o = rt;//rename wd_o
				reg1_addr_o = rs;
			end
			`OP_ANDI:begin
				aluop_o = `ALUOP_AND;
		  		alusel_o = `RES_LOGIC;
				wreg_o = `True;
				instvalid = `True;
				reg1_read_o = 1'b1;
				reg2_read_o = 1'b0;
				imm = {16'h0, inst_i[15:0]};
				wd_o = rt;
				reg1_addr_o = rs;
			end
			`OP_LUI:begin
				aluop_o = `ALUOP_NOP;
		  		alusel_o = `RES_LOGIC;
				wreg_o = `True;
				instvalid = `True;
				reg1_read_o = 1'b0;//r1=imm
				reg2_read_o = 1'b0;//r2=imm
				imm = {inst_i[15:0],16'h0};
				wd_o=rt;
			end
			`OP_BNE:begin
				aluop_o=`ALUOP_BNE;
				alusel_o=`RES_NOP;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`True;
				reg1_addr_o = rs;    //rs
				reg2_addr_o = rt;    //rt
				imm <= {{14{inst_i[15]}},inst_i[15:0],2'b00};
				if(reg1_o!=reg2_o)begin
					jump_addr_o=pc_i+4'h4+imm;
					is_jump_o=`True;
					is_nextdelay_o=`True;
				end
				else if(reg1_o==reg2_o)begin
					jump_addr_o=`ZeroWord;
					is_jump_o=`False;
					is_nextdelay_o=`False;
				end
			end
			`OP_BEQ:begin
				aluop_o=`ALUOP_BNE;
				alusel_o=`RES_NOP;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`True;
				reg1_addr_o = rs;    //rs
				reg2_addr_o = rt;    //rt
				imm <= {{14{inst_i[15]}},inst_i[15:0],2'b00};
				if(reg1_o==reg2_o)begin
					jump_addr_o=pc_i+4'h4+imm;
					is_jump_o=`True;
					is_nextdelay_o=`True;
				end
				else if(reg1_o!=reg2_o)begin
					jump_addr_o=`ZeroWord;
					is_jump_o=`False;
					is_nextdelay_o=`False;
				end
			end
			`OP_BGEZ:begin
				case(rt)
				5'b00001:begin
				aluop_o=`ALUOP_BNE;
				alusel_o=`RES_NOP;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`False;
				reg1_addr_o=rs;
				imm <= {{14{inst_i[15]}},inst_i[15:0],2'b00};
				if(reg1_o[31]==1'b0)begin
					is_jump_o=`True;
					jump_addr_o=pc_i+4'h4+imm;
					is_nextdelay_o=`True;
				end
				else if(reg1_o[31]==1'b1)begin
					jump_addr_o=`ZeroWord;
					is_jump_o=`False;
					is_nextdelay_o=`False;
				end
				end
				default:begin
				end
				endcase
			end
			`OP_BGTZ:begin
				case(rt)
				5'b00000:begin
				aluop_o=`ALUOP_BNE;
				alusel_o=`RES_NOP;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`False;
				reg1_addr_o=rs;
				imm <= {{14{inst_i[15]}},inst_i[15:0],2'b00};
				if((reg1_o[31]==1'b0)&&(reg1_o!=`ZeroWord))begin
					is_jump_o=`True;
					jump_addr_o=pc_i+4'h4+imm;
					is_nextdelay_o=`True;
				end
				else if((reg1_o[31]==1'b1)||(reg1_o==`ZeroWord))begin
					jump_addr_o=`ZeroWord;
					is_jump_o=`False;
					is_nextdelay_o=`False;
				end
				end
				default:begin
				end
				endcase
			end
			`OP_J:begin
				aluop_o=`ALUOP_BNE;
				alusel_o=`RES_NOP;
				instvalid=`True;
				reg1_read_o=`False;
				reg2_read_o=`False;
				jump_addr_o={pc_delay[31:28],inst_i[25:0],2'b00};
				is_jump_o=`True;
				is_nextdelay_o=`True;
			end
			`OP_JAL:begin
				aluop_o=`ALUOP_BNE;
				alusel_o=`RES_JUMP;
				instvalid=`True;
				reg1_read_o=`False;
				reg2_read_o=`False;
				wreg_o=`True;
				wd_o=5'b11111;
				jump_addr_o={pc_delay[31:28],inst_i[25:0],2'b00};
				is_jump_o=`True;
				is_nextdelay_o=`True;
				delay_addr_o=pc_delay+4'h4;
			end
			`OP_LW:begin
				aluop_o=`MEMOP_LW;
				alusel_o=`RES_LOADSTORE;
				wreg_o=`True;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`False;
				wd_o=rt;
				reg1_addr_o = rs;    //rs
			end
			`OP_LB:begin
				aluop_o=`MEMOP_LB;
				alusel_o=`RES_LOADSTORE;
				wreg_o=`True;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`False;
				wd_o=rt;
				reg1_addr_o = rs;    //rs
			end
			`OP_SW:begin
				aluop_o=`MEMOP_SW;
				alusel_o=`RES_LOADSTORE;
				wreg_o=`False;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`True;
				reg1_addr_o = rs;    //rs
				reg2_addr_o = rt;    //rt
			end
			`OP_SB:begin
				aluop_o=`MEMOP_SB;
				alusel_o=`RES_LOADSTORE;
				wreg_o=`False;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`True;
				reg1_addr_o = rs;
				reg2_addr_o=rt;
			end
			`OP_ADDIU:begin
				aluop_o=`ALUOP_ADDU;
				alusel_o=`RES_ARITHMETIC;
				wreg_o=`True;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`False;
				reg1_addr_o = rs;    //rs
				wd_o=rt;
				imm <= {{16{inst_i[15]}},inst_i[15:0]};
			end
			`OP_MUL:begin
				aluop_o=`ALUOP_MUL;
				alusel_o=`RES_ARITHMETIC;
				wreg_o=`True;
				instvalid=`True;
				reg1_read_o=`True;
				reg2_read_o=`True;
				reg1_addr_o = rs;
				reg2_addr_o=rt;    //rs
				wd_o=rd;
			end
			`OP_SPECIAL:begin
				wd_o=rd;
				reg1_addr_o = rs;    //rs
				reg2_addr_o = rt;    //rt
				case(fun)
					`FUN_ADDU:begin
						aluop_o = `ALUOP_ADDU;
		  				alusel_o = `RES_ARITHMETIC;
						wreg_o = `WriteEnable;
						instvalid = `InstValid;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b1;
					end
					`FUN_OR:begin
						aluop_o = `ALUOP_OR;
		  				alusel_o = `RES_LOGIC;
						wreg_o = `WriteEnable;
						instvalid = `InstValid;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b1;
					end
					`FUN_AND:begin
						aluop_o = `ALUOP_AND;
		  				alusel_o = `RES_LOGIC;
						wreg_o = `WriteEnable;
						instvalid = `InstValid;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b1;
					end
					`FUN_XOR:begin
						aluop_o = `ALUOP_XOR;
		  				alusel_o = `RES_LOGIC;
						wreg_o = `WriteEnable;
						instvalid = `InstValid;
						reg1_read_o = 1'b1;
						reg2_read_o = 1'b1;
					end
					`FUN_SLL:begin
						aluop_o = `ALUOP_SLL;
		  				alusel_o = `RES_LOGIC;
						wreg_o = `WriteEnable;
						instvalid = `InstValid;
						reg1_read_o = `False;
						reg2_read_o = 1'b1;
						imm={27'b0,sa};
					end
					`FUN_SRL:begin
						aluop_o = `ALUOP_SRL;
		  				alusel_o = `RES_LOGIC;
						wreg_o = `WriteEnable;
						instvalid = `InstValid;
						reg1_read_o = `False;
						reg2_read_o = 1'b1;
						imm={27'b0,sa};
					end
					`FUN_SLLV:begin
						aluop_o=`ALUOP_SLLV;
						alusel_o=`RES_LOGIC;
						wreg_o=`True;
						instvalid=`True;
						reg1_read_o=`True;
						reg2_read_o=`True;
					end
					`FUN_SLT:begin
						aluop_o=`ALUOP_SLT;
						alusel_o=`RES_ARITHMETIC;
						wreg_o=`True;
						instvalid=`True;
						reg1_read_o=`True;
						reg2_read_o=`True;
					end
					`FUN_JR:begin
						aluop_o=`ALUOP_BNE;
						alusel_o=`ALUOP_NOP;
						wreg_o=`False;
						instvalid=`True;
						reg1_read_o=`True;
						reg2_read_o=`False;
						jump_addr_o=reg1_o;
						is_jump_o=`True;
						is_nextdelay_o=`True;
					end
					default:begin
					end
				endcase//fun
			end
		    default:begin
		    end
		  endcase	//op		
		end
	end
	
	//r1,r2
	always @ (*) begin
		loadstop_reg1=`False;
		if(rst == `RstEnable) begin
			reg1_o = `ZeroWord;
	  	end
		else if(reg1_read_o==`True&&loading&&reg1_addr_o==ex_waddr_i)
		loadstop_reg1=`True;
	  	else if((reg1_read_o == 1'b1)&&(ex_en_i==1'b1)&&(ex_waddr_i==rs)) begin//ex data
		reg1_o=ex_wdata_i;
	  	end 
	  	else if((reg1_read_o == 1'b1)&&(mem_en_i==1'b1)&&(mem_waddr_i==rs)) begin//mem data
		reg1_o=mem_wdata_i;
	  	end 
	  	else if(reg1_read_o == 1'b1) begin
	  	reg1_o = reg1_data_i;
	  	end 
	  	else if(reg1_read_o == 1'b0) begin
	  	reg1_o = imm;
	  	end 
	  	else begin
	    reg1_o = `ZeroWord;
	  	end
	end
	
	always @ (*) begin
		loadstop_reg2=`False;
		if(rst == `RstEnable) begin
			reg2_o = `ZeroWord;
	  	end
		else if(reg2_read_o==`True&&loading&&reg2_addr_o==ex_waddr_i)
		loadstop_reg2=`True;
		else if((reg2_read_o == 1'b1)&&(ex_en_i==1'b1)&&(ex_waddr_i==rt)) begin//ex
		reg2_o=ex_wdata_i;
	  	end
		else if((reg2_read_o == 1'b1)&&(mem_en_i==1'b1)&&(mem_waddr_i==rt)) begin//mem
		reg2_o=mem_wdata_i;
	  	end
		else if(reg2_read_o == 1'b1) begin
	  	reg2_o = reg2_data_i;
	  	end
		else if(reg2_read_o == 1'b0) begin
	  	reg2_o = imm;
	  	end
		else begin
	    reg2_o = `ZeroWord;
	    end
	end
	assign stop_o=loadstop_reg1|loadstop_reg2;
	always@(*)begin
		if(rst==`True)begin
			is_delay_o=`False;
		end	
		else begin
			is_delay_o=delaying_i;
		end
	end

endmodule