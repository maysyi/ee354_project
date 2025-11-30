//////////////////////////////////////////////////////////////////////////////////
// File: ee354_project_tb.v
// Description: Testbench for Snake game FPGA project
// Tests the top-level module with simulated button inputs and clock
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 100ps

	module ee354_project_tb();

	//////////////////////////////////////////////////////////////////////////////////
	// TESTBENCH SIGNALS
	//////////////////////////////////////////////////////////////////////////////////
	
	// Clock and Reset
	reg ClkPort;
	reg BtnC;
	
	// Button Inputs
	reg BtnL, BtnU, BtnD, BtnR;
	
	// LED Outputs
	wire Ld0, Ld1, Ld2, Ld3;
	
	// SSD Outputs
	wire Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	wire An0, An1, An2, An3, An4, An5, An6, An7;
	
	// Testbench control signals
	integer test_num;
	
	//////////////////////////////////////////////////////////////////////////////////
	// INSTANTIATE DUT (Device Under Test)
	//////////////////////////////////////////////////////////////////////////////////
	
	ee354_project_top DUT (
		.ClkPort(ClkPort),
		.BtnL(BtnL),
		.BtnU(BtnU),
		.BtnD(BtnD),
		.BtnR(BtnR),
		.BtnC(BtnC),
		.Ld0(Ld0),
		.Ld1(Ld1),
		.Ld2(Ld2),
		.Ld3(Ld3),
		.Ca(Ca),
		.Cb(Cb),
		.Cc(Cc),
		.Cd(Cd),
		.Ce(Ce),
		.Cf(Cf),
		.Cg(Cg),
		.Dp(Dp),
		.An0(An0),
		.An1(An1),
		.An2(An2),
		.An3(An3),
		.An4(An4),
		.An5(An5),
		.An6(An6),
		.An7(An7)
	);
	
	//////////////////////////////////////////////////////////////////////////////////
	// CLOCK GENERATION (100 MHz)
	//////////////////////////////////////////////////////////////////////////////////
	
	always
	begin
		ClkPort = 1'b0;
		#5;      // 5ns low
		ClkPort = 1'b1;
		#5;      // 5ns high (10ns period = 100MHz)
	end
	
	//////////////////////////////////////////////////////////////////////////////////
	// TEST PROCEDURES
	//////////////////////////////////////////////////////////////////////////////////
	
	initial
	begin
		// Initialize all inputs
		BtnL = 1'b0;
		BtnU = 1'b0;
		BtnD = 1'b0;
		BtnR = 1'b0;
		BtnC = 1'b0;
		test_num = 0;
		
		// Display testbench header
		$display("\n");
		$display("========================================");
		$display("  EE354L Snake Game Testbench");
		$display("========================================\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 1: Reset and Initial State
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: Reset and Initial State", test_num);
		$display("  Applying reset...");
		BtnC = 1'b1;
		repeat(10) @(posedge ClkPort);
		BtnC = 1'b0;
		repeat(10) @(posedge ClkPort);
		$display("  LEDs: Ld3=%b, Ld2=%b, Ld1=%b, Ld0=%b", Ld3, Ld2, Ld1, Ld0);
		$display("  Expected: Ld0=1 (Initial state)\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 2: State Transition from Initial to Run
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: State Transition (Initial -> Run)", test_num);
		$display("  Waiting for state transition...");
		repeat(100) @(posedge ClkPort);
		$display("  LEDs: Ld3=%b, Ld2=%b, Ld1=%b, Ld0=%b", Ld3, Ld2, Ld1, Ld0);
		$display("  Expected: Ld1=1 (Run state)\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 3: Button Press - Move Up
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: Button Press - Move Up", test_num);
		$display("  Pressing UP button...");
		BtnU = 1'b1;
		repeat(50) @(posedge ClkPort);
		BtnU = 1'b0;
		repeat(50) @(posedge ClkPort);
		$display("  Button released\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 4: Button Press - Move Right
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: Button Press - Move Right", test_num);
		$display("  Pressing RIGHT button...");
		BtnR = 1'b1;
		repeat(50) @(posedge ClkPort);
		BtnR = 1'b0;
		repeat(50) @(posedge ClkPort);
		$display("  Button released\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 5: Button Press - Move Down
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: Button Press - Move Down", test_num);
		$display("  Pressing DOWN button...");
		BtnD = 1'b1;
		repeat(50) @(posedge ClkPort);
		BtnD = 1'b0;
		repeat(50) @(posedge ClkPort);
		$display("  Button released\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 6: Button Press - Move Left
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: Button Press - Move Left", test_num);
		$display("  Pressing LEFT button...");
		BtnL = 1'b1;
		repeat(50) @(posedge ClkPort);
		BtnL = 1'b0;
		repeat(50) @(posedge ClkPort);
		$display("  Button released\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 7: Long Running Simulation
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: Long Running Simulation (1000 cycles)", test_num);
		$display("  Running simulation...");
		repeat(1000) @(posedge ClkPort);
		$display("  Simulation complete");
		$display("  LEDs: Ld3=%b, Ld2=%b, Ld1=%b, Ld0=%b\n", Ld3, Ld2, Ld1, Ld0);
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 8: Reset During Run
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: Reset During Run State", test_num);
		$display("  Applying reset...");
		BtnC = 1'b1;
		repeat(10) @(posedge ClkPort);
		BtnC = 1'b0;
		repeat(10) @(posedge ClkPort);
		$display("  LEDs: Ld3=%b, Ld2=%b, Ld1=%b, Ld0=%b", Ld3, Ld2, Ld1, Ld0);
		$display("  Expected: Ld0=1 (Back to Initial state)\n");
		
		//////////////////////////////////////////////////////////////////////////////////
		// TEST 9: SSD Display Test
		//////////////////////////////////////////////////////////////////////////////////
		test_num = test_num + 1;
		$display("TEST %0d: SSD Display (7-segment outputs)", test_num);
		$display("  Cathode outputs: Ca=%b, Cb=%b, Cc=%b, Cd=%b, Ce=%b, Cf=%b, Cg=%b, Dp=%b",
			Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp);
		$display("  Anode outputs: An7=%b, An6=%b, An5=%b, An4=%b, An3=%b, An2=%b, An1=%b, An0=%b\n",
			An7, An6, An5, An4, An3, An2, An1, An0);
		
		//////////////////////////////////////////////////////////////////////////////////
		// TESTBENCH COMPLETE
		//////////////////////////////////////////////////////////////////////////////////
		
		repeat(100) @(posedge ClkPort);
		$display("========================================");
		$display("  Testbench Complete");
		$display("========================================\n");
		$finish;
	end
	
	//////////////////////////////////////////////////////////////////////////////////
	// MONITORING AND DEBUGGING
	//////////////////////////////////////////////////////////////////////////////////
	
	// Optional: Monitor state changes
	initial
	begin
		$monitor("Time:%0t | LEDs:%b%b%b%b | Buttons:U=%b D=%b L=%b R=%b C=%b",
			$time, Ld3, Ld2, Ld1, Ld0, BtnU, BtnD, BtnL, BtnR, BtnC);
	end
	
	// Optional: Dump waveforms for viewing in waveform viewer
	initial
	begin
		$dumpfile("ee354_project.vcd");
		$dumpvars(0, ee354_project_tb);
	end

endmodule