`include "defines.v"

module mem(

	input wire rst,
	
	//来自执行阶段的信息
	input wire[4:0]       		  wd_i,
	input wire                    wreg_i,
	input wire[31:0]			  wdata_i,
	input wire[7:0]      memop_i,
	input wire[31:0]     maddr_i,
	input wire[31:0]     reg2_i,
	input wire[31:0]	 mdata_i,
	//送到回写阶段的信息
	output reg[4:0]      		 wd_o,
	output reg                   wreg_o,
	output reg[31:0]			 wdata_o,
	output reg[31:0]     maddr_o,
	output reg[31:0]     mdata_o,
	output reg[3:0]      msel_o,
	output reg           mem_ce_o,
	output reg           mem_we_o,
	output wire stop_en
);
wire[1:0] byteaddr=maddr_i[1:0];
wire baseraming_1=(maddr_i>=32'h80000000)?`True:`False;
wire baseraming_2=(maddr_i<32'h80400000)?`True:`False;
assign stop_en=baseraming_1&baseraming_2;
	always @ (*) begin
		if(rst == `RstEnable) begin
			wd_o = `NOPRegAddr;
			wreg_o = `WriteDisable;
		    wdata_o = `ZeroWord;
			maddr_o=`ZeroWord;
			mdata_o=`ZeroWord;
			msel_o=4'b0000;
			mem_ce_o=1'b0;
			mem_we_o=1'b0;
		end 
		else begin
		  	wd_o = wd_i;
			wreg_o = wreg_i;
			wdata_o = wdata_i;
			maddr_o=`ZeroWord;
			mdata_o=`ZeroWord;
			msel_o=4'b1111;
			mem_ce_o=1'b0;
			mem_we_o=1'b0;
			case(memop_i)
				`MEMOP_LW:begin
					wdata_o=mdata_i;
					maddr_o=maddr_i;
					mem_ce_o=1'b1;
					mem_we_o=1'b0;
				end
				`MEMOP_SW:begin
					maddr_o=maddr_i;
					mdata_o=reg2_i;
					mem_ce_o=1'b1;
					mem_we_o=1'b1;
				end
				`MEMOP_LB:begin
					maddr_o=maddr_i;
					mem_ce_o=1'b1;
					mem_we_o=1'b0;
					case(byteaddr)
						2'b00:begin
							msel_o=4'b0001;
							wdata_o={{24{mdata_i[7]}},mdata_i[7:0]};
						end
						2'b01:begin
							msel_o=4'b0010;
							wdata_o={{24{mdata_i[15]}},mdata_i[15:8]};
						end
						2'b10:begin
							msel_o=4'b0100;
							wdata_o={{24{mdata_i[23]}},mdata_i[23:16]};
						end
						2'b11:begin
							msel_o=4'b1000;
							wdata_o={{24{mdata_i[31]}},mdata_i[31:24]};
						end
						default:begin
						end
					endcase
				end
				`MEMOP_SB:begin
					maddr_o=maddr_i;
					mem_ce_o=1'b1;
					mem_we_o=1'b1;
					case(byteaddr)
						2'b00:begin
							msel_o=4'b0001;
							mdata_o={24'h000000,reg2_i[7:0]};
						end
						2'b01:begin
							msel_o=4'b0010;
							mdata_o={16'h0000,reg2_i[7:0],8'h00};
						end
						2'b10:begin
							msel_o=4'b0100;
							mdata_o={8'h00,reg2_i[7:0],16'h0000};
						end
						2'b11:begin
							msel_o=4'b1000;
							mdata_o={reg2_i[7:0],24'h000000};
						end
						default:begin
						end
					endcase
				end
				default:begin
				end
			endcase
		end    //if
	end      //always
			

endmodule