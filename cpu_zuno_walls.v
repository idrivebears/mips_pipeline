// CPU
module CPU (clk, rst);
	input clk, rst;
	
	// Wires for IFID
	wire [63:0] IFID_Reg;
	wire [31:0] IFID_pc_4, IFID_Instr;

	// Wires for IDEX
	wire [115:0] IDEX_Reg;
	wire [31:0] IDEX_pc_4, IDEX_ExtImm, IDEX_rdData1, IDEX_rdData2;
	wire [4:0] IDEX_rd, IDEX_rt;
	wire [5:0] IDEX_funct;

	// Wires for EXMEM
	wire [101:0] EXMEM_Reg;
	wire [31:0] EXMEM_pc_4_ba, EXMEM_alu_result, EXMEM_readData2;
	wire EXMEM_z;
	wire [4:0] EXMEM_wrAddr2;

	// Wires for MEMWVB
	wire [63:0] MEMWB_Reg;
	wire [31:0] MEMWB_alu_result, MEMWB_readDataOut;


	wire [31:0] Inst, pc, pc_4, pc_4_ba, pc_d, BranchAddress, ExtImm, alu_result, rdData1, rdData2, alu_b, bj_4, JumpAddr, luiResult, jalMuxOut, readDataOut, lwMuxOut, luiMuxOut, jrMuxOut, pc_8, adderWrOut;
	wire [25:0] Addr;
	wire [15:0] Imm;
	wire [5:0] OpCode, funct;
	wire [4:0] rs, rt, rd, shamt, wrAddr, wrAddr2;
	wire [2:0] Control;
	wire z, WrEn, imm, ExtOp, branch, wr, jump, lui, jal, jr;
	
	assign OpCode = IFID_Inst[31:26];
	assign rs = IFID_Inst[25:21];
	assign rt = IFID_Inst[20:16];
	assign rd = IFID_Inst[15:11];
	assign shamt = IFID_Inst[10:6];
	assign funct = IFID_Inst[5:0];
	assign Imm = IFID_Inst[15:0];
	assign Addr = IFID_Inst[25:0];
	assign luiResult = {Imm, 16'b0};
	
	assign BranchAddress = {ExtImm[29:0],2'b0};
	assign JumpAddr = {pc[31:28],Addr,2'b0} - 32'd12288;
	
	//Module instantiation
	//MUX32
	mux32 branchMux(.out(pc_d),.in0(pc_4),.in1(pc_4_ba),.select(branch));
	mux32 immMux(.out(alu_b),.in0(rdData2),.in1(ExtImm),.select(imm));
	mux32 jumpMux(.out(bj_4),.in0(pc_d),.in1(JumpAddr),.select(jump));
	mux32 jr_mux(.out(jrMuxOut),.in0(bj_4),.in1(rdData1),.select(jr));
	mux32 luiMux(.out(luiMuxOut),.in0(alu_result),.in1(luiResult),.select(lui));
	mux32 jalMux(.out(jalMuxOut),.in0(luiMuxOut),.in1(pc_8),.select(jal)); ******** pc_8 -> pc_4
	mux32 lwMux(.out(lwMuxOut),.in0(jalMuxOut),.in1(readDataOut),.select(lw));
	
	//MUX5
	mux5 wrAddrMuxMux(.out(wrAddr),.in0(rd),.in1(rt),.select(imm));
	mux5 wrAddrJumpMux(.out(wrAddr2),.in0(wrAddr),.in1(5'b11111), .select(jal));
	
	//PROGRAM COUNTER
	register PC(.q(pc),.d(jrMuxOut),.clk(clk),.rst(rst));
	
	//ADDERS
	adder adder1(.s(pc_4),.a(pc),.b(4));
	adder adder2(.s(pc_4_ba),.a(pc_4),.b(BranchAddress));
	adder adder3(.s(pc_8),.a(pc_4),.b(0)); *
	adder adderWrData(.s(adderWrOut),.a(ExtImm),.b(rdData1)); * 

	//MEMORY RAM & ROM
	rom rom1(.data(Inst),.address(pc),.rst(rst));
	ram ram1(.readData(readDataOut),.address(adderWrOut),.writeData(rdData2),.clk(clk),.rst(rst),.wr(wr));    ********* adderWrOut(wrAddRam) -> alu_result
	
	//REGISTER FILE
	registerFile regFile1(.clk(clk),.readData1(rdData1),.readAddress1(rs),.readData2(rdData2),.readAddress2(rt),.writeData(lwMuxOut),.writeEnable(WrEn),.writeAddress(wrAddr2));
	
	//SIGN EXTENDER
	signExtender signExt1(.ExtOp(ExtOp),.in(Imm),.out(ExtImm));

	//ALU
	alu alu1(.control(Control),.A(rdData1),.B(alu_b),.result(alu_result),.z(z));
	
	//CONTROL UNIT
	ControlUnit CtrlUnit(.OpCode(OpCode), .funct(funct), .z(z), .WrEn(WrEn), .imm(imm), .ExtOp(ExtOp), .branch(branch), .Control(Control), .jump(jump), .wr(wr), .lw(lw), .lui(lui), .jr(jr), .jal(jal);

	// PIPELINES

	//IFID PIPELINE 
	n_register #(.nBits(64)) IFID(.q(IFID_Reg), .d({pc_4,Inst}), .clk(clk),. rst(rst));
	assign IFID_pc_4      = IFID_Reg[63:32];
	assign IFID_Inst      = IFID_Reg[31:0];

	//IDEX PIPELINE 32(IFID_PC4) + 32(readdata1) + 32(readdata2) + 32(Sign extend) + 16(Imm)
	n_register #(.nBits(144)) IDEX(.q(IDEX_Reg), .d({IFID_pc_4, rdData1, rdData2, ExtImm, funct, rt, rd}), .clk(clk),.rst(rst));
	assign IDEX_pc_4      = IDEX_Reg[143:112];
	assign IDEX_rdData1  = IDEX_Reg[111:80];
	assign IDEX_rdData12 = IDEX_Reg[79:48];
	assign IDEX_ExtImm   = IDEX_Reg[47:16];
	assign IDEX_funct    = IDEX_Reg[15:10];
	assign IDEX_rt       = IDEX_Reg[9:5];
	assign IDEX_rd       = IDEX_Reg[4:0];

	//EXMEM PIPELINE 
	n_register #(.nBits(102)) EXMEM(.q(EXMEM_Reg), .d({pc_4_ba, z, alu_result,wrAddr2,rdData2}), .clk(clk),.rst(rst));
	assign EXMEM_pc_4_ba     = EXMEM_Reg[101:70];
	assign EXMEM_z           = EXMEM_Reg[69];
	assign EXMEM_alu_result  = EXMEM_Reg[68:37];
	assign EXMEM_wrAddr2     = EXMEM_Reg[36:32];
	assign EXMEM_readData2   = EXMEM_Reg[31:0];

	//MEMWB PIPELINE
	n_register #(.nBits(64)) MEMWB(.q(MEMWB_Reg), .d({readDataOut, alu_result}), .clk(clk),.rst(rst));
	assign MEMWB_readDataOut = MEMWB_Reg[63:32];
	assign MEMWB_alu_result  = MEMWB_Reg[31:0];

	
endmodule // CPU 


// Control Unit
module ControlUnit(OpCode, funct, z, WrEn, imm, ExtOp, branch, Control, jump, wr, lw, lui, jr, jal);
	input [5:0] OpCode, funct;
	input z;
	output WrEn, imm, ExtOp, branch, jump, wr, lw, lui, jr, jal;
	output [2:0] Control;
	
	wire RFormat, Add, And, Addi, Andi, Beq, Sub, Nor, Or, Jr, Bne, Ori, Lw, Sw, Lui, Jump, Jal;

	//All instructions: add, sub, and, or, nor, addi, andi, ori, lw, sw, beq, bne, j, jal, jr, lui

	//R-Format instructions
	assign Rformat = (~OpCode[5])&(~OpCode[4])&(~OpCode[3])&(~OpCode[2])&(~OpCode[1])&(~OpCode[0]);
	assign Add = (Rformat)&(funct[5])&(~funct[4])&(~funct[3])&(~funct[2])&(~funct[1])&(~funct[0]);
	assign Sub = (Rformat)&(funct[5])&(~funct[4])&(~funct[3])&(~funct[2])&(funct[1])&(~funct[0]);
	assign Nor = (Rformat)&(funct[5])&(~funct[4])&(~funct[3])&(funct[2])&(funct[1])&(funct[0]);
	assign Or = (Rformat)&(funct[5])&(~funct[4])&(~funct[3])&(funct[2])&(~funct[1])&(funct[0]);
	assign And = (Rformat)&(funct[5])&(~funct[4])&(~funct[3])&(funct[2])&(~funct[1])&(~funct[0]);
	assign Jr = (Rformat)&(~funct[5])&(~funct[4])&(funct[3])&(~funct[2])&(~funct[1])&(~funct[0]);

	//I-Format instructions
	assign Addi = (~OpCode[5])&(~OpCode[4])&(OpCode[3]) &(~OpCode[2])&(~OpCode[1])&(~OpCode[0]);
	assign Andi = (~OpCode[5])&(~OpCode[4])&(OpCode[3]) &(OpCode[2]) &(~OpCode[1])&(~OpCode[0]);
	assign Beq  = (~OpCode[5])&(~OpCode[4])&(~OpCode[3])&(OpCode[2]) &(~OpCode[1])&(~OpCode[0]);
	assign Bne  = (~OpCode[5])&(~OpCode[4])&(~OpCode[3])&(OpCode[2]) &(~OpCode[1])& (OpCode[0]);
	assign Ori  = (~OpCode[5])&(~OpCode[4])&(OpCode[3]) &(OpCode[2]) &(~OpCode[1])& (OpCode[0]);
	assign Lw   = (OpCode[5]) &(~OpCode[4])&(~OpCode[3])&(~OpCode[2])&(OpCode[1]) & (OpCode[0]);
	assign Sw   = (OpCode[5]) &(~OpCode[4])&(OpCode[3]) &(~OpCode[2])&(OpCode[1]) & (OpCode[0]);
	assign Lui  = (~OpCode[5])&(~OpCode[4])&(OpCode[3]) &(OpCode[2]) &(OpCode[1]) & (OpCode[0]);
	
	//J-Format instructions
	assign Jump = (~OpCode[5])&(~OpCode[4])&(~OpCode[3])&(~OpCode[2])&(OpCode[1])&(~OpCode[0]);
	assign Jal = (~OpCode[5])&(~OpCode[4])&(~OpCode[3])&(~OpCode[2])&(OpCode[1])&(OpCode[0]);
	
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

	assign WrEn = Add|Addi|And|Andi|Sub|Nor|Or|Ori|Lw|Jal|Lui;
	assign imm = Addi|Andi|Ori|Lw|Lui;
	assign ExtOp = Addi|Beq|Bne|Sw|Lw;
	assign branch = (Beq&z)|(Beq&~z);
	assign jump = Jump|Jal;
	assign jal = Jal;
	assign lui = Lui;
	assign jr = Jr;
	assign wr = Sw;
	assign lw = Lw;
	assign Control[0] = Beq|Bne|Sub|Nor;
	assign Control[1] = Nor|Or|Ori;
	assign Control[2] = And|Andi;

endmodule // ControlUnit