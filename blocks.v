// Behavioral level CPU blocks
// Based on library from
// J. Wawrzynek
// February 2016

//Behavioral model of 32-bit Register:
// positive edge-triggered,
// synchronous active-high reset.
module register (q,d,clk,rst);
   input [31:0] d;
   input 	clk, rst;
   output [31:0] q;
   //
   reg [31:0] q;
   always @ (posedge clk)
     if (rst) 
      q <= 0; 
    else 
      q <= d;
endmodule // register

//Behavioral model of N-bit Register:
// positive edge-triggered,
// synchronous active-high reset.
module n_register (q,d,clk,rst);
   parameter nBits = 32; //default val 32
   input [nBits-1:0] d;
   input clk, rst;
   output [nBits-1:0] q;
   //
   reg [nBits-1:0] q;
   always @ (posedge clk)
     if (rst) 
      q <= 0; 
    else 
      q <= d;
endmodule // n_register

//Behavioral model of 32-bit adder.
module adder (s,a,b);
   input [31:0] a,b;
   output [31:0] s;
   reg [31:0] 	 s;
   //
   always @ (a or b)
     s = a + b;
endmodule // adder

//Behavioral model of Read Only Memory:
// 32-bit wide, 1024 words deep,
// asynchronous read-port,
// initialize from file on positive
// edge of reset signal, by reading
// contents of "text.dat" interpreted
// as hex.
//
module rom (data,address,rst);
   input rst;
   input [31:0] address;
   output [31:0] data;
   reg [31:0] data;
   
   reg [31:0] programMemoryArray [0:1023];
   always @ (posedge rst)
     $readmemh("text.dat", programMemoryArray);
   always @ (address)
     data = programMemoryArray[address[11:2]];
endmodule // rom

//Behavioral model of Random Access Memory:
// 32-bit wide, 1024 words deep,
// synchronous write-port if WR=1,
// initialize from hex file ("data.dat") on positive
// edge of reset signal.
//
module ram (readData,address,writeData,clk,rst,wr);
   input clk, rst, wr;
   input [31:0] address, writeData;
   output [31:0] readData;
   reg [31:0] readData;
   //
   reg [31:0] memArray [0:1023];
   reg dirty;
   always @ (posedge rst)
     $readmemh("data.dat", memArray);
   always @ (posedge clk)
     if (wr)
	 begin
		memArray[address[11:2]] = writeData;
        dirty = 1'b1;
	 end
   always @ (address or dirty)
	 begin
		readData = memArray[address[11:2]];
		dirty = 0;
	 end
endmodule // ram

//Behavioral model of 32-bit wide 2-to-1 multiplexor.
module mux32 (out,in0,in1,select);
   input [31:0] in0,in1;
   input select;
   output [31:0] out;
   //
   reg [31:0] out;
   always @ (in0 or in1 or select)
     if (select) out=in1;
     else out=in0;
endmodule // mux32

//Behavioral model of 5-bit wide 2-to-1 multiplexor.
module mux5 (out,in0,in1,select);
   input [4:0] in0,in1;
   input select;
   output [4:0] out;
   //
   reg [4:0] out;
   always @ (in0 or in1 or select)
     if (select) out=in1;
     else out=in0;
endmodule // mux5

//Behavioral model of register file:
// 32-bit wide, 32 words deep,
// two asynchronous read-ports,
// one synchronous write-port.
//
module registerFile (clk,readData1,readAddress1,readData2,readAddress2,writeData,writeEnable,writeAddress);
   input clk, writeEnable;
   input [4:0] writeAddress, readAddress1, readAddress2;
   input [31:0] writeData;
   output [31:0] readData1, readData2;
   reg [31:0] readData1, readData2;
   //
   reg [31:0] array [0:31];
   reg 	      dirty1, dirty2;
   always @ (posedge clk)
     if (writeEnable)
        if (writeAddress!=4'h0) 
        begin
            array[writeAddress] = writeData;
            dirty1=1'b1;
            dirty2=1'b1;
        end
   always @ (readAddress1 or dirty1) 
     begin
		readData1 = array[readAddress1];
		dirty1=0;
     end
   always @ (readAddress2 or dirty2)
     begin
		readData2 = array[readAddress2];
		dirty2=0;
     end
   initial
     array[0]=0;
endmodule // registerFile

//Sign extender from 16- to 32-bits.
module signExtender (ExtOp,in,out);
   input [15:0]  in;
   input ExtOp;
   output [31:0] out;
   reg [31:0] 	 out;

   always @ (in)
		if(ExtOp)
		 out = {in[15],in[15],in[15],in[15],in[15],in[15],in[15],in[15],
				in[15],in[15],in[15],in[15],in[15],in[15],in[15],in[15],
				in[15:0] };
		else
		 out = { 16'b0, in[15:0] };
endmodule // signExtender

//Behavioral model of ALU:
// 8 functions and "zero" flag,
// A is top input, B is bottom
//
module alu (control,A,B,result,z);
   input [31:0] A, B;
   input [2:0] control;
   output z;
   output [31:0] result;
   reg z;
   reg [31:0] result;
   
   always @ (A or B or control)
     begin
		case (control)
		  3'b000: // add
			result=A+B;
		  3'b001: // subtract
			result=A-B;
		  3'b010: // OR
			result=A|B;
		  3'b011: // NOR
			result=~(A|B);
		  3'b100: // AND
			result=A&B;
		endcase // case(control)
		z = (result==0) ? 1'b1 : 1'b0;
     end // always @ (A or B or control)
endmodule // alu

module comparator (A,B,equal);
   input [31:0] A, B;
   output equal;
   reg equal;
 
   always @ (A or B)
		if(A == B)
			equal = 1;
		else
			equal = 0;
endmodule // comparator