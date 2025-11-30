//////////////////////////////////////////////////////////////////////////////////
// File based on: ee354_GCD_tb.v 
// Description: Modified significantly from template file, to execute Snake game simulation. This file is the testbench
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module ee354_project_tb();

	// Inputs
	reg ClkPort;
	reg BtnL, BtnU, BtnD, BtnR, BtnC;

	// Outputs
	wire Ld0, Ld1, Ld2, Ld3;
	wire An0, An1, An2, An3, An4, An5, An6, An7;
	wire Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;

	// Local variables
	integer test_num;
	
	// Instantiate the Unit Under Test (UUT)
	ee354_project_top uut (
		.ClkPort(ClkPort),
		.BtnL(BtnL), .BtnU(BtnU), .BtnD(BtnD), .BtnR(BtnR),
		.BtnC(BtnC),
		.Ld3(Ld3), .Ld2(Ld2), .Ld1(Ld1), .Ld0(Ld0),
		.An7(An7), .An6(An6), .An5(An5), .An4(An4), .An3(An3), .An2(An2), .An1(An1), .An0(An0),
		.Ca(Ca), .Cb(Cb), .Cc(Cc), .Cd(Cd), .Ce(Ce), .Cf(Cf), .Cg(Cg),
		.Dp(Dp)  
	);
		
		initial 
		  begin
			ClkPort = 0; // Initialize clock
		  end
		
		always  begin #5; ClkPort = ~ ClkPort; end // 100 MHz clock
		
		initial begin
		// Initialize Inputs
		BtnL = 1'b0;
		BtnU = 1'b0;
		BtnD = 1'b0;
		BtnR = 1'b0;
		BtnC = 1'b0;
		test_num = 0;

		$display("EE354L Project Testbench Starting...");
		$display("--------------------------------------------------");

		// Wait 100 ns for global reset to finish
		#100;
		
		// Test 1: Reset and Initial State
		test_num = test_num + 1;
		$display("Test %0d: Reset and Initial State", test_num);
		$display("  Applying reset...");
		BtnC = 1'b1;
		@(posedge ClkPort);
		BtnC = 1'b0;
		@(posedge ClkPort);
		$display("  TEST:     Ld3=%b, Ld2=%b, Ld1=%b, Ld0=%b", Ld3, Ld2, Ld1, Ld0);
		$display("  EXPECTED: Ld3=0, Ld2=0, Ld1=0, Ld0=1 (Initial state)\n");			
		
		// Test 2: Initial to run state
		test_num = test_num + 1;
		$display("Test %0d: Initial to run state", test_num);
		$display("  Waiting for state transition...");
		@(posedge ClkPort);
		$display("  TEST:     Ld3=%b, Ld2=%b, Ld1=%b, Ld0=%b", Ld3, Ld2, Ld1, Ld0);
		$display("  EXPECTED: Ld3=0, Ld2=0, Ld1=1, Ld0=0 (Run state)\n");	

		// Test 3: Move down
		test_num = test_num + 1;
		$display("Test %0d: Move right", test_num);
		$display("  Pressing down button...");
		BtnR = 1'b1;
		@(posedge ClkPort);
		BtnR = 1'b0;
		@(posedge ClkPort);
		$display("  Button released\n");

		// Test 4: Long Running Simulation
		test_num = test_num + 1;
		$display("Test %0d: Long Running Simulation", test_num);
		$display("  Running simulation...");
		repeat(5000) @(posedge ClkPort);
		$display("  Simulation complete");
		$display("  TEST:     Ld3=%b, Ld2=%b, Ld1=%b, Ld0=%b", Ld3, Ld2, Ld1, Ld0);
		$display("  EXPECTED: Ld3=0, Ld2=1, Ld1=0, Ld0=0 (Lose state)");	
		
		// generate a Start pulse
		$display("--------------------------------------------------");
		$display("Testbench Complete");
		end
      
endmodule

