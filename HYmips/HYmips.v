`include "defines.v"

module HYmips(

	input wire clk,
	input wire rst,

	input wire[`RegBus]  inst,
	output wire[`RegBus] pc,
	output wire 		 inst_ce,

	input wire[`RegBus]  mdata_mem,
	output wire[`RegBus] mem_maddr,
	output wire[3:0]     mem_msel,
	output wire          mem_we,
	output wire          mem_ce,
	output wire[`RegBus] mem_mdata	
);
	//jump back to pc
	wire jump;
	wire[`InstAddrBus] jump_addr;
	
	//pc to if_id
	wire[`InstAddrBus] id_pc_i;
	wire[`InstBus]     id_inst_i;
	
	//ID to ID/EX
	wire[`AluOpBus]    id_aluop_o;
	wire[`AluSelBus]   id_alusel_o;
	wire[`RegBus]      id_reg1_o;
	wire[`RegBus]      id_reg2_o;
	wire               id_wreg_o;
	wire[`RegAddrBus]  id_wd_o;
	wire[`OffsetBus] id_offset;
		//delay
	wire delay;
	wire[`InstAddrBus] delay_addr;
	wire nextdelay;
	
	//ID/EX to EX
	wire[`AluOpBus]    ex_aluop_i;
	wire[`AluSelBus]   ex_alusel_i;
	wire[`RegBus]      ex_reg1_i;
	wire[`RegBus]      ex_reg2_i;
	wire               ex_wreg_i;
	wire[`RegAddrBus]  ex_wd_i;
	wire[`OffsetBus] offset_ex;
		//delay
	wire delaying;
	wire[`InstAddrBus] delaying_addr;
	wire nextdelaying;

	
	//EX TO EX/MEM
	wire              ex_wreg_o;
	wire[`RegAddrBus] ex_wd_o;
	wire[`RegBus]     ex_wdata_o;
	wire[`AluOpBus] ex_memop;
	wire[`RegBus]   ex_maddr;
	wire[`RegBus]   ex_reg2;

	//EX/MEM TO MEM
	wire mem_wreg_i;
	wire[`RegAddrBus] mem_wd_i;
	wire[`RegBus]     mem_wdata_i;
	wire[`AluOpBus] memop_mem;
	wire[`RegBus]   maddr_mem;
	wire[`RegBus]   reg2_mem;

	//MEM TO MEM/WB
	wire mem_wreg_o;
	wire[`RegAddrBus] mem_wd_o;
	wire[`RegBus] mem_wdata_o;
	
	//MEM/WB to WB	
	wire wb_wreg_i;
	wire[`RegAddrBus] wb_wd_i;
	wire[`RegBus] wb_wdata_i;
	
	//ID regfile
  wire reg1_read;
  wire reg2_read;
  wire[`RegBus] reg1_data;
  wire[`RegBus] reg2_data;
  wire[`RegAddrBus] reg1_addr;
  wire[`RegAddrBus] reg2_addr;

	//CTRL
	wire id_stop;
	wire ex_stop;
	wire mem_stop;
	wire[5:0] stop;
  

	pc_mod pc_mod0(
		.clk(clk),
		.rst(rst),
		.pc(pc),
		.ce(inst_ce),
		.jump_en(jump),
		.jump_addr(jump_addr),
		.stop(stop)
	);
	
	if_id if_id0(
		.clk(clk),
		.rst(rst),
		.stop(stop),
		.if_pc(pc),
		.if_inst(inst),
		.id_pc(id_pc_i),
		.id_inst(id_inst_i)      	
	);
	
	id id0(
		.rst(rst),
		.pc_i(id_pc_i),
		.inst_i(id_inst_i),
		.stop_o(id_stop),

		.reg1_data_i(reg1_data),
		.reg2_data_i(reg2_data),

		//regfile
		.reg1_read_o(reg1_read),
		.reg2_read_o(reg2_read), 	  

		.reg1_addr_o(reg1_addr),
		.reg2_addr_o(reg2_addr), 
	  
		//ID/EX
		.aluop_o(id_aluop_o),
		.alusel_o(id_alusel_o),
		.reg1_o(id_reg1_o),
		.reg2_o(id_reg2_o),
		.wd_o(id_wd_o),
		.wreg_o(id_wreg_o),
		.offset_o(id_offset),

		.memop_i(ex_memop),

		//闂佸搫鍟╁ù鍥晸閿燂拷?
		.ex_en_i(ex_wreg_o),
		.ex_waddr_i(ex_wd_o),
		.ex_wdata_i(ex_wdata_o),

		.mem_en_i(mem_wreg_o),
		.mem_waddr_i(mem_wd_o),
		.mem_wdata_i(mem_wdata_o),

		//jump
		.delaying_i(nextdelaying),
		.is_delay_o(delay),
		.delay_addr_o(delay_addr),
		.is_nextdelay_o(nextdelay),
		.is_jump_o(jump),
		.jump_addr_o(jump_addr)
	);

	regfile regfile1(
		.clk (clk),
		.rst (rst),
		.we	(wb_wreg_i),
		.waddr (wb_wd_i),
		.wdata (wb_wdata_i),
		.re1 (reg1_read),
		.raddr1 (reg1_addr),
		.rdata1 (reg1_data),
		.re2 (reg2_read),
		.raddr2 (reg2_addr),
		.rdata2 (reg2_data)
	);


	id_ex id_ex0(
		.clk(clk),
		.rst(rst),
		.stop(stop),
		
		.id_aluop(id_aluop_o),
		.id_alusel(id_alusel_o),
		.id_reg1(id_reg1_o),
		.id_reg2(id_reg2_o),
		.id_wd(id_wd_o),
		.id_wreg(id_wreg_o),
		.id_offset(id_offset),
	
		.ex_aluop(ex_aluop_i),
		.ex_alusel(ex_alusel_i),
		.ex_reg1(ex_reg1_i),
		.ex_reg2(ex_reg2_i),
		.ex_wd(ex_wd_i),
		.ex_wreg(ex_wreg_i),
		.ex_offset(offset_ex),
		//delay
		.id_delaying(delay),
		.id_delay_addr(delay_addr),
		.id_nextdelay(nextdelay),
		.ex_delaying(delaying),
		.ex_delay_addr(delaying_addr),
		.nextid_nextdelay(nextdelaying)
	);		
	
	ex ex0(
		.rst(rst),
		.stop_o(ex_stop),

		.aluop_i(ex_aluop_i),
		.alusel_i(ex_alusel_i),
		.reg1_i(ex_reg1_i),
		.reg2_i(ex_reg2_i),
		.wd_i(ex_wd_i),
		.wreg_i(ex_wreg_i),
		.offset_i(offset_ex),
			//jump
		.delaying_i(delaying),
		.delay_addr_i(delaying_addr),
	  
		.wd_o(ex_wd_o),
		.wreg_o(ex_wreg_o),
		.wdata_o(ex_wdata_o),
		.memop_o(ex_memop),
		.mem_addr_o(ex_maddr),
		.reg2_o(ex_reg2)
		
	);

  ex_mem ex_mem0(
		.clk(clk),
		.rst(rst),
		.stop(stop),

		.ex_wd(ex_wd_o),
		.ex_wreg(ex_wreg_o),
		.ex_wdata(ex_wdata_o),
		.ex_memop(ex_memop),
		.ex_maddr(ex_maddr),
		.ex_reg2(ex_reg2),
	
		.mem_wd(mem_wd_i),
		.mem_wreg(mem_wreg_i),
		.mem_wdata(mem_wdata_i),
		.mem_memop(memop_mem),
		.mem_maddr(maddr_mem),
		.mem_reg2(reg2_mem)
			       	
	);
	
	mem mem0(
		.rst(rst),
	
		.wd_i(mem_wd_i),
		.wreg_i(mem_wreg_i),
		.wdata_i(mem_wdata_i),
		.memop_i(memop_mem),
		.maddr_i(maddr_mem),
		.reg2_i(reg2_mem),
	  	.mdata_i(mdata_mem),

		.wd_o(mem_wd_o),
		.wreg_o(mem_wreg_o),
		.wdata_o(mem_wdata_o),
		.maddr_o(mem_maddr),
		.msel_o(mem_msel),
		.mem_we_o(mem_we),
		.mem_ce_o(mem_ce),
		.mdata_o(mem_mdata),
		.stop_en(mem_stop)
	);

	mem_wb mem_wb0(
		.clk(clk),
		.rst(rst),
		.stop(stop),

		.mem_wd(mem_wd_o),
		.mem_wreg(mem_wreg_o),
		.mem_wdata(mem_wdata_o),
	
		.wb_wd(wb_wd_i),
		.wb_wreg(wb_wreg_i),
		.wb_wdata(wb_wdata_i)						       	
	);

	ctrl ctrl0(
		.rst(rst),
		.id_stop(id_stop),
		.ex_stop(ex_stop),
		.mem_stop(mem_stop),
		.stop(stop)
	);

endmodule