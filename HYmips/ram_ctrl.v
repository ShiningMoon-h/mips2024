`define UartState 32'hBFD003FC
`define UartAddr 32'hBFD003F8

module ram_ctrl(
    input wire clk,
    input wire rst,

    input wire inst_ce,
    input wire[31:0] inst_addr,
    output reg[31:0] inst,

    //BaseRAM信号
    inout wire[31:0] base_ram_data,  //BaseRAM数据，低8位与CPLD串口控制器共享
    output reg[19:0] base_ram_addr, //BaseRAM地址
    output reg[3:0] base_ram_be,  //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg base_ram_ce,       //BaseRAM片选，低有效
    output reg base_ram_oe,       //BaseRAM读使能，低有效
    output reg base_ram_we,       //BaseRAM写使能，低有效

    input wire[31:0] mem_addr,
    input wire mem_we,
    input wire mem_ce,
    input wire[31:0] mem_data_o,
    output reg[31:0] mem_data_i,
    input wire[3:0] mem_sel,

    //ExtRAM信号
    inout wire[31:0] ext_ram_data,  //ExtRAM数据
    output reg[19:0] ext_ram_addr, //ExtRAM地址
    output reg[3:0] ext_ram_be,  //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output reg ext_ram_ce,       //ExtRAM片选，低有效
    output reg ext_ram_oe,       //ExtRAM读使能，低有效
    output reg ext_ram_we,       //ExtRAM写使能，低有效

    output wire rxd,
    output wire txd,
    output wire[1:0] state


);
reg[31:0] uart_data;
wire[31:0] base_data;
wire[31:0] ext_data;
wire is_UartState = (mem_addr ==  `UartState);
wire is_UartAddr = (mem_addr == `UartAddr);

wire is_base_ram=(is_UartState != 1'b1 && is_UartAddr != 1'b1&&(mem_addr>=32'h80000000)&&(mem_addr<32'h80400000))?1'b1:1'b0;
wire is_ext_ram=(is_UartState != 1'b1 && is_UartAddr != 1'b1&&(mem_addr>=32'h80400000)&&(mem_addr<32'h80800000))?1'b1:1'b0;

assign base_ram_data=(inst_ce&&(!base_ram_we))?mem_data_o:32'bz;
assign base_data=base_ram_data;
always@(*)begin
        base_ram_addr=20'h00000;
        base_ram_be=4'b1111;
        base_ram_ce=1'b0;
        base_ram_oe=1'b1;
        base_ram_we=1'b1;
        if(is_base_ram)begin
        base_ram_addr=mem_addr[21:2];
        base_ram_be=~mem_sel;
        base_ram_ce=~mem_ce;
        base_ram_oe=mem_we;
        base_ram_we=~mem_we;
        end
        else begin
        base_ram_addr=inst_addr[21:2];
        base_ram_be=4'b0000;
        base_ram_ce=~inst_ce;
        base_ram_oe=1'b0;
        base_ram_we=1'b1;
        end
end
always@(*)begin
        inst = base_data;
end

assign ext_ram_data=mem_we?mem_data_o:32'bz;
assign ext_data=ext_ram_data;
always@(*)begin
        ext_ram_addr = 20'h00000;
        ext_ram_be = 4'b1111;
        ext_ram_ce = 1'b1;
        ext_ram_oe = 1'b1;
        ext_ram_we = 1'b1;
        if(is_ext_ram)begin
        ext_ram_addr=mem_addr[21:2];
        ext_ram_be=~mem_sel;
        ext_ram_ce=~mem_ce;
        ext_ram_oe=mem_we;
        ext_ram_we=~mem_we;
        end
        else begin
        ext_ram_addr = 20'h00000;
        ext_ram_be = 4'b1111;
        ext_ram_ce = 1'b1;
        ext_ram_oe = 1'b1;
        ext_ram_we = 1'b1;
        end
end
always@(*)begin
        if(is_ext_ram)
    mem_data_i=ext_data;
    else if(is_base_ram)
    mem_data_i=base_data;
    else if(is_UartAddr||is_UartState)
    mem_data_i=uart_data;
end

wire [7:0]  RxD_data;           //接收到的数据
wire [7:0]  TxD_data;           //待发送的数据
wire        RxD_data_ready;     //接收器收到数据完成之后，置为1
wire        TxD_busy;           //发送器状态是否忙碌，1为忙碌，0为不忙碌
wire        TxD_start;          //发送器是否可以发送数据，1代表可以发送
wire        RxD_clear;          //为1时将清除接收标志（ready信号）

wire        RxD_FIFO_wr_en;
wire        RxD_FIFO_full;
wire [7:0]  RxD_FIFO_din;
reg         RxD_FIFO_rd_en;
wire        RxD_FIFO_empty;
wire [7:0]  RxD_FIFO_dout;

reg         TxD_FIFO_wr_en;
wire        TxD_FIFO_full;
reg  [7:0]  TxD_FIFO_din;
wire        TxD_FIFO_rd_en;
wire        TxD_FIFO_empty;
wire [7:0]  TxD_FIFO_dout;

//串口实例化模块，波特率9600，仿真时可改为59000000
async_receiver #(.ClkFrequency(11059200),.Baud(9600))   //接收模块
                ext_uart_r(
                   .clk(clk),                           //外部时钟信号
                   .RxD(rxd),                           //外部串行信号输入
                   .RxD_data_ready(RxD_data_ready),     //数据接收到标志
                   .RxD_clear(RxD_clear),               //清除接收标志
                   .RxD_data(RxD_data)                  //接收到的一字节数据
                );

async_transmitter #(.ClkFrequency(11059200),.Baud(9600)) //发送模块
                    ext_uart_t(
                      .clk(clk),                        //外部时钟信号
                      .TxD(txd),                        //串行信号输出
                      .TxD_busy(TxD_busy),              //发送器忙状态指示
                      .TxD_start(TxD_start),            //开始发送信号
                      .TxD_data(TxD_data)               //待发送的数据
                    );

//fifo接收模块
fifo_generator_0 RXD_FIFO (
    .rst(rst),
    .clk(clk),
    .wr_en(RxD_FIFO_wr_en),     //写使能
    .din(RxD_FIFO_din),         //接收到的数据
    .full(RxD_FIFO_full),

    .rd_en(RxD_FIFO_rd_en),
    .dout(RxD_FIFO_dout),       //接收到mem的数据
    .empty(RxD_FIFO_empty)      //判空标志
);

//fifo发送模块
fifo_generator_0 TXD_FIFO (
    .rst(rst),
    .clk(clk),
    .wr_en(TxD_FIFO_wr_en),     //写使能
    .din(TxD_FIFO_din),         //要发送的数据
    .full(TxD_FIFO_full),

    .rd_en(TxD_FIFO_rd_en),     //高位使串口发送
    .dout(TxD_FIFO_dout),       //发送到串口
    .empty(TxD_FIFO_empty)      //判空标志
);

assign state = {!RxD_FIFO_empty,!TxD_FIFO_full};

assign TxD_FIFO_rd_en = TxD_start;
assign TxD_start = (!TxD_busy) && (!TxD_FIFO_empty);
assign TxD_data = TxD_FIFO_dout;

assign RxD_FIFO_wr_en = RxD_data_ready;
assign RxD_FIFO_din = RxD_data;
assign RxD_clear = RxD_data_ready && (!RxD_FIFO_full);

always @(*) begin
    TxD_FIFO_wr_en = `WriteDisable;
    TxD_FIFO_din = 8'h00;
    RxD_FIFO_rd_en = `ReadDisable;
    uart_data = `ZeroWord;
    if(is_UartState) begin            //询问串口状态
        TxD_FIFO_wr_en = `WriteDisable;
        TxD_FIFO_din = 8'h00;
        RxD_FIFO_rd_en = `ReadDisable;
        uart_data = {{30{1'b0}}, state};
    end 
    else if(is_UartAddr) begin        //通过串口传递）数据
        if(mem_we == `WriteDisable) begin   //接收串口数据
            TxD_FIFO_wr_en = `WriteDisable;
            TxD_FIFO_din = 8'h00;
            RxD_FIFO_rd_en = `ReadEnable;
            uart_data = {{24{1'b0}}, RxD_FIFO_dout};
        end
        else begin                          //发送串口数据
            TxD_FIFO_wr_en = `WriteEnable;
            TxD_FIFO_din = mem_data_o[7:0];
            RxD_FIFO_rd_en = `ReadDisable;
            uart_data = `ZeroWord;
        end
    end
    else begin
        TxD_FIFO_wr_en = `WriteDisable;
        TxD_FIFO_din = 8'h00;
        RxD_FIFO_rd_en = `ReadDisable;
        uart_data = `ZeroWord;
    end
end

endmodule

