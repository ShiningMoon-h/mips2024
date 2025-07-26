//全局
`define True 1'b1
`define False 1'b0
`define RstEnable 1'b1
`define RstDisable 1'b0
`define ZeroWord 32'h00000000
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define AluOpBus 7:0
`define AluSelBus 2:0
`define InstValid 1'b0
`define InstInvalid 1'b1
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define OffsetBus 15:0
`define OffsetWidth 16
`define HalfZero 16'h0000
//op
`define OP_NOP 6'b000000
`define OP_ORI  6'b001101
`define OP_XORI 6'b001110
`define OP_ANDI 6'b001100
`define OP_LUI 6'b001111
`define OP_ADDIU 6'b001001
`define OP_MUL   6'b011100
`define OP_SPECIAL 6'b000000
`define OP_BEQ  6'b000100
`define OP_BNE  6'b000101
`define OP_BGEZ 6'b000001
`define OP_BGTZ 6'b000111
`define OP_J    6'b000010
`define OP_JAL  6'b000011
`define OP_LW 6'b100011
`define OP_SW 6'b101011
`define OP_LB 6'b100000
`define OP_SB 6'b101000
//fun
`define FUN_ADDU 6'b100001
`define FUN_OR   6'b100101
`define FUN_XOR  6'b100110
`define FUN_SLL  6'b000000
`define FUN_SLLV 6'b000100
`define FUN_SLT  6'b101010
`define FUN_AND  6'b100100
`define FUN_SRL  6'b000010
`define FUN_JR   6'b001000
//AluOp
`define ALUOP_NOP   8'b00000000
`define ALUOP_OR    8'b00100001
`define ALUOP_XOR   8'b00100010
`define ALUOP_AND   8'b00100011
`define ALUOP_SLL   8'b00100100
`define ALUOP_SLLV  8'b00100101
`define ALUOP_SRL   8'b00100110
`define ALUOP_ADDU  8'b10000001
`define ALUOP_MUL   8'b10000011
`define ALUOP_SLT   8'b10000010
`define ALUOP_BNE   8'b01010010

//MEMOP
`define MEMOP_LW  8'b00000001
`define MEMOP_SW  8'b00000010
`define MEMOP_LB  8'b00000011
`define MEMOP_SB  8'b00000100
//AluSel
`define RES_LOGIC      3'b001
`define RES_NOP        3'b000
`define RES_ARITHMETIC 3'b100
`define RES_JUMP       3'b110
`define RES_LOADSTORE  3'b111
//inst_rom
`define InstAddrBus 31:0
`define InstBus 31:0
`define InstMemNum 131071
`define InstMemNumLog2 17
//regfile
`define RegAddrBus 4:0
`define RegBus 31:0
`define RegWidth 32
`define DoubleRegWidth 64
`define DoubleRegBus 63:0
`define RegNum 32
`define RegNumLog2 5
`define NOPRegAddr 5'b00000
//ram
`define ByteBus 7:0
`define ByteWidth 8