//CPU test bench
module testCPU;
   reg CLK,RST;
   
   CPU CPUblock(.clk(CLK), .rst(RST));

	initial
		begin
			CLK=1'b0;
			forever
				#1 CLK = ~CLK;
		end
	 
	initial
		begin
			#0 RST=1'b1;
			#4 RST=1'b0;
		end
		
endmodule // testCPU

