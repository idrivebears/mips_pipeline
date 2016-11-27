// CPU
module CPU (clk, rst);
	input clk, rst;
	
	// Wires for IFID
	wire [74:0] IFID_Reg;
	wire [31:0] IFID_pc_4, IFID_Inst;

	// Wires for IDEX
	wire [151:0] IDEX_Reg;
	wire [31:0] IDEX_pc_4, IDEX_ExtImm, IDEX_rdData1, IDEX_rdData2;
	wire [4:0] IDEX_rd, IDEX_rt;
	wire [5:0] IDEX_funct;

	// Wires for EXMEM
	wire [169:0] EXMEM_Reg;
	wire [31:0] EXMEM_pc_4_ba, EXMEM_alu_result, EXMEM_rdData2, EXMEM_readData1, EXMEM_ExtImm;
	wire EXMEM_z;
	wire [4:0] EXMEM_wrAddr2;


	// Wires for MEMWVB
	wire [72:0] MEMWB_Reg;
	wire [4:0] MEMWB_wrAddr2;
	wire [31:0] MEMWB_alu_result, MEMWB_readDataOut;


	wire [31:0] Inst, pc, pc_4, pc_4_ba, pc_d, BranchAddress, ExtImm, alu_result, rdData1, rdData2, alu_b, bj_4, JumpAddr, luiResult, jalMuxOut, readDataOut, lwMuxOut, luiMuxOut, jrMuxOut, pc_8, adderWrOut;
	wire [25:0] Addr;
	wire [15:0] Imm;
	wire [5:0] OpCode, funct, IFID_funct, IFID_OpCode, IDEX_OpCode, EXMEM_OpCode, EXMEM_funct, MEMWB_funct, MEMWB_OpCode;
	wire [4:0] rs, rt, rd, shamt, wrAddr, wrAddr2;
	wire [2:0] Control IFID_Control, IDEX_Control, EXMEM_Control, MEMWB_Control;
	wire z, WrEn, imm, ExtOp, branch, wr, jump, lui, jal, jr, lw;
	wire IFID_z, IFID_WrEn, IFID_imm, IFID_ExtOp, IFID_branch, IFID_wr, IFID_jump, IFID_lui, IFID_jal, IFID_jr, IFID_lw;
	wire IDEX_z, IDEX_WrEn, IDEX_imm, IDEX_ExtOp, IDEX_branch, IDEX_wr, IDEX_jump, IDEX_lui, IDEX_jal, IDEX_jr, IDEX_lw;
	wire EXMEM_WrEn, EXMEM_imm, EXMEM_ExtOp, EXMEM_branch, EXMEM_wr, EXMEM_jump, EXMEM_lui, EXMEM_jal, EXMEM_jr, EXMEM_lw;
	wire MEMWB_z, MEMWB_WrEn, MEMWB_imm, MEMWB_ExtOp, MEMWB_branch, MEMWB_wr, MEMWB_jump, MEMWB_lui, MEMWB_jal, MEMWB_jr, MEMWB_lw;
	
	assign OpCode = IFID_Inst[31:26];
	assign rs = IFID_Inst[25:21];
	assign rt = IFID_Inst[20:16];
	assign rd = IFID_Inst[15:11];
	assign shamt = IFID_Inst[10:6];
	assign funct = IFID_Inst[5:0];
	assign Imm = IFID_Inst[15:0];
	assign Addr = IFID_Inst[25:0];
	assign luiResult = {Imm, 16'b0};
	
	
	assign JumpAddr = {pc[31:28],Addr,2'b0} - 32'd12288; /*AAAAAAAAAAAAAAAAAAAAAAAHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHH*/
			
	
	//CONTROL UNIT
	ControlUnit CtrlUnit(.OpCode(OpCode), .funct(funct), .z(z), .WrEn(WrEn), .imm(imm), .ExtOp(ExtOp), .branch(branch), .Control(Control), .jump(jump), .wr(wr), .lw(lw), .lui(lui), .jr(jr), .jal(jal);

	//START
	mux32 branchMux(.out(pc_d),.in0(pc_4),.in1(EXMEM_pc_4_ba),.select(branch));
	mux32 jumpMux(.out(bj_4),.in0(pc_d),.in1(JumpAddr),.select(jump));
	mux32 jr_mux(.out(jrMuxOut),.in0(bj_4),.in1(rdData1),.select(jr));
	register PC(.q(pc),.d(jrMuxOut),.clk(clk),.rst(rst));
	adder adder1(.s(pc_4),.a(pc),.b(4));
	adder adder3(.s(pc_8),.a(pc_4),.b(0)); 
	rom rom1(.data(Inst),.address(pc),.rst(rst));

	//********************************************************* IFID PIPELINE *******************************************************************************************************/
	n_register #(.nBits(74)) IFID(.q(IFID_Reg), .d({Control, WrEn, imm, ExtOp, wr, lui, jal, lw, pc_4,Inst}), .clk(clk),. rst(rst));
	assign IFID_Control        = IFID_Reg[73:71];
	assign IFID_WrEn     	   = IFID_Reg[70];
	assign IFID_imm     	   = IFID_Reg[69];
	assign IFID_ExtOp     	   = IFID_Reg[68];
	assign IFID_wr     	       = IFID_Reg[67];
	assign IFID_lui     	   = IFID_Reg[66]; 
	assign IFID_jal     	   = IFID_Reg[65];
	assign IFID_lw     	       = IFID_Reg[64];

	assign IFID_pc_4           = IFID_Reg[63:32];
	assign IFID_Inst           = IFID_Reg[31:0];


	//REGISTER FILE
	registerFile regFile1(.clk(clk),.readData1(rdData1),.readAddress1(rs),.readData2(rdData2),.readAddress2(rt),.writeData(lwMuxOut),.writeEnable(IFID_WrEn),.writeAddress(MEMWB_wrAddr2));

	//SIGN EXTENDER
	signExtender signExt1(.ExtOp(IFID_ExtOp),.in(Imm),.out(ExtImm));


	//*********************************************************** IDEX PIPELINE ****************************************************************************************************/ 
	n_register #(.nBits(152)) IDEX(.q(IDEX_Reg), .d({IFID_Control, IFID_imm, IFID_wr, IFID_lui, IFID_jal, IFID_lw, IFID_pc_4, rdData1, rdData2, ExtImm, funct, rt, rd}), .clk(clk),.rst(rst));
	assign IDEX_Control        = IDEX_Reg[151:149];
	assign IDEX_imm     	   = IDEX_Reg[148];
	assign IDEX_wr     	       = IDEX_Reg[147];
	assign IDEX_lui     	   = IDEX_Reg[146]; 
	assign IDEX_jal     	   = IDEX_Reg[145];
	assign IDEX_lw     	       = IDEX_Reg[144];

	assign IDEX_pc_4      = IDEX_Reg[143:112];
	assign IDEX_rdData1  = IDEX_Reg[111:80];
	assign IDEX_rdData12 = IDEX_Reg[79:48];
	assign IDEX_ExtImm   = IDEX_Reg[47:16];
	assign IDEX_funct    = IDEX_Reg[15:10];
	assign IDEX_rt       = IDEX_Reg[9:5];
	assign IDEX_rd       = IDEX_Reg[4:0];

	assign BranchAddress = {IDEX_ExtImm[29:0],2'b0};	//Shift left 2 
	//MUX32 IMMMUX
	mux32 immMux(.out(alu_b),.in0(IDEX_rdData2),.in1(IDEX_ExtImm),.select(IDEX_imm));
	//MUX5
	mux5 wrAddrMuxMux(.out(wrAddr),.in0(IDEX_rd),.in1(IDEX_rt),.select(IDEX_imm));
	mux5 wrAddrJumpMux(.out(wrAddr2),.in0(wrAddr),.in1(5'b11111), .select(IDEX_jal));
	//ADDER2
	adder adder2(.s(pc_4_ba),.a(IDEX_pc_4),.b(BranchAddress));
	//ALU
	alu alu1(.control(IDEX_Control),.A(IDEX_rdData1),.B(alu_b),.result(alu_result),.z(z));	//Falta pipeline control

	//************************************************************* EXMEM PIPELINE *************************************************************************************************/
	n_register #(.nBits(170)) EXMEM(.q(EXMEM_Reg), .d({IDEX_wr, IDEX_lui, IDEX_lw, IDEX_jal, IDEX_ExtImm, rdData1, pc_4_ba, z, alu_result,wrAddr2,rdData2}), .clk(clk),.rst(rst));
	assign EXMEM_wr     	   = EXMEM_Reg[169];
	assign EXMEM_lui     	   = EXMEM_Reg[168]; 
	assign EXMEM_lw     	   = EXMEM_Reg[167];
	assign EXMEM_jal		   = EXMEM_Reg[166];

	assign EXMEM_ExtImm		 = EXMEM_Reg[165:134];
	assign EXMEM_rdData1     = EXMEM_Reg[133:102];
	assign EXMEM_pc_4_ba     = EXMEM_Reg[101:70];
	assign EXMEM_z           = EXMEM_Reg[69];
	assign EXMEM_alu_result  = EXMEM_Reg[68:37];
	assign EXMEM_wrAddr2     = EXMEM_Reg[36:32];
	assign EXMEM_rdData2     = EXMEM_Reg[31:0];

	// AdderWRDATA
	adder adderWrData(.s(adderWrOut),.a(EXMEM_ExtImm),.b(EXMEM_rdData1));
	//MEMORY RAM 
	ram ram1(.readData(readDataOut),.address(adderWrOut),.writeData(EXMEM_rdData2),.clk(clk),.rst(rst),.wr(EXMEM_wr));

	//************************************************************* MEMWB PIPELINE *************************************************************************************************/
	n_register #(.nBits(73)) MEMWB(.q(MEMWB_Reg), .d({EXMEM_lui, EXMEM_lw, EXMEM_jal,EXMEM_wrAddr2, readDataOut, EXMEM_alu_result}), .clk(clk),.rst(rst));
	assign MEMWB_lui     	   = EXMEM_Reg[72]; 
	assign MEMWB_lw     	   = EXMEM_Reg[71];
	assign MEMWB_jal		   = EXMEM_Reg[70];

	assign MEMWB_wrAddr2     = MEMWB_Reg[69:64];
	assign MEMWB_readDataOut = MEMWB_Reg[63:32];
	assign MEMWB_alu_result  = MEMWB_Reg[31:0];

	mux32 luiMux(.out(luiMuxOut),.in0(MEMWB_alu_result),.in1(luiResult),.select(MEMWB_lui));
	mux32 jalMux(.out(jalMuxOut),.in0(luiMuxOut),.in1(pc_8),.select(MEMWB_jal)); 
	mux32 lwMux(.out(lwMuxOut),.in0(jalMuxOut),.in1(MEMWB_readDataOut),.select(MEMWB_lw));


	
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