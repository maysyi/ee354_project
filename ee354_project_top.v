//////////////////////////////////////////////////////////////////////////////////
// File based on: ee354_GCD_tb.v 
// Description: Modified significantly from template file to instantiate FPGA.
//////////////////////////////////////////////////////////////////////////////////

// Clock division segment not done.

module ee354_project_top(
	ClkPort,                           // the 100 MHz incoming clock signal	
	BtnL, BtnU, BtnD, BtnR,            // the Left, Up, Down, and the Right buttons (Direction buttons)
	BtnC,                              // the Center button (Reset)
	// Sw7, Sw6, Sw5, Sw4, Sw3, Sw2, Sw1, Sw0, // 8 switches (that we are not using)
	// Ld7, Ld6, Ld5, Ld4,
	Ld3, Ld2, Ld1, Ld0, // 8 LEDs (that we will use to show states. Only 4 will be used since we only have 4 states)
	An7, An6, An5, An4, An3, An2, An1, An0,	// 8 anodes (for SSD to show apple count. Probably won't need all.)
	Ca, Cb, Cc, Cd, Ce, Cf, Cg,        // 7 cathodes (for SSD to show apple count)
	Dp , // Dot Point Cathode on SSDs (will be disabling in code later)
	
	hSync, vSync,
	vgaR, vgaG, vgaB,
	QuadSpiFlashCS
);

	//  INPUTS
	// Clock & Reset I/O
	input ClkPort;	
	// Project Specific Inputs
	input BtnL, BtnU, BtnD, BtnR, BtnC;	
	
	//  OUTPUTS
	// Project Specific Outputs
	// LEDs
	output 	Ld0, Ld1, Ld2, Ld3;
	// SSD Outputs
	output 	Cg, Cf, Ce, Cd, Cc, Cb, Ca, Dp;
	output 	An0, An1, An2, An3;	
	output 	An4, An5, An6, An7;
	output hSync, vSync;
	output [3:0] vgaR, vgaG, vgaB;
	output QuadSpiFlashCS;

	//  LOCAL SIGNALS
	wire		Reset;
	wire		board_clk, sys_clk;
	wire [1:0] 	ssdscan_clk;
	reg [26:0]	DIV_CLK;
	
	// Debouncing modules
	wire BtnU_SCEN, BtnD_SCEN, BtnL_SCEN, BtnR_SCEN, BtnC_SCEN;

    ee354_debouncer #(.N_dc(28)) debounce_U (
        .CLK(sys_clk), .RESET(Reset), .PB(BtnU),
        .DPB(), .SCEN(BtnU_SCEN), .MCEN(), .CCEN()
    );
    
    ee354_debouncer #(.N_dc(28)) debounce_D (
        .CLK(sys_clk), .RESET(Reset), .PB(BtnD),
        .DPB(), .SCEN(BtnD_SCEN), .MCEN(), .CCEN()
    );
    
    ee354_debouncer #(.N_dc(28)) debounce_L (
        .CLK(sys_clk), .RESET(Reset), .PB(BtnL),
        .DPB(), .SCEN(BtnL_SCEN), .MCEN(), .CCEN()
    );
    
    ee354_debouncer #(.N_dc(28)) debounce_R (
        .CLK(sys_clk), .RESET(Reset), .PB(BtnR),
        .DPB(), .SCEN(BtnR_SCEN), .MCEN(), .CCEN()
    );
    
    ee354_debouncer #(.N_dc(28)) debounce_C (
        .CLK(sys_clk), .RESET(Reset), .PB(BtnC),
        .DPB(), .SCEN(BtnC_SCEN), .MCEN(), .CCEN()
    );

	// Assigning directions
	wire [1:0] In_Dirn;
    wire SCEN_dir; // Combined SCEN for any direction button
    
    assign SCEN_dir = BtnU_SCEN | BtnD_SCEN | BtnL_SCEN | BtnR_SCEN;
    
    assign In_Dirn = BtnU_SCEN ? 2'b00 :  // UP
                     BtnD_SCEN ? 2'b01 :  // DOWN
                     BtnL_SCEN ? 2'b10 :  // LEFT
                     BtnR_SCEN ? 2'b11 :  // RIGHT
                     2'b00;            // Default UP

	// State machine module
	wire q_Win, q_Lose, q_Run, q_I;
    wire Collision;
    wire [7:0] Length;
    ee354_project_sm state_machine (
        .Clk(sys_clk),
        .Reset(Reset),
        .Ack(BtnC_SCEN),
        .Collision(Collision),
        .Length(Length),
        .q_I(q_I),
        .q_Run(q_Run),
        .q_Lose(q_Lose),
        .q_Win(q_Win)
    );

	// Length and head/tail position
	wire [3:0] Head_X, Head_Y;
	wire [3:0] Tail_X, Tail_Y;
	wire [3:0] Apple_X, Apple_Y;
	wire New_Apple;
	// occupancy vector: 225 bits (one per cell)
	wire [224:0] Cell_Snake_Vector;
	// Snake movement clock (game speed clock from divided sys_clk)
	wire Speed_Clk;
    
	ee354_project_length snake_length (
		.Clk(sys_clk),
		.SCEN(SCEN_dir),
		.Reset(Reset),
		.Speed_Clk(Speed_Clk),
		.q_I(q_I),
		.q_Run(q_Run),
		.q_Win(q_Win),
		.q_Lose(q_Lose),
		.In_Dirn(In_Dirn),
		.Head_X(Head_X),
		.Head_Y(Head_Y),
		.Apple_X(Apple_X),
		.Apple_Y(Apple_Y),
		.Length(Length),
		.Cell_Snake_Vector(Cell_Snake_Vector),
		.Tail_X(Tail_X),
		.Tail_Y(Tail_Y),
		.New_Apple(New_Apple),
		.Collision(Collision)
	);

	// `Cell_Snake_Vector` is provided by the length module (225-bit occupancy vector)
    ee354_project_apples apple_gen (
        .Clk(sys_clk),
        .SCEN(SCEN_dir),
        .Reset(Reset),
        .Cell_Snake_Vector(Cell_Snake_Vector),
        .New_Apple(New_Apple),
        .Apple_X(Apple_X),
        .Apple_Y(Apple_Y)
    );
	

	wire bright;
	wire [9:0] hCount, vCount;
	wire [11:0] rgb;
	wire [11:0] background;
	assign background = 12'b1111_1111_1111; // white background

	display_controller dc(.clk(ClkPort), .hSync(hSync), .vSync(vSync), .bright(bright), .hCount(hCount), .vCount(vCount));
	block_controller bc(.clk(Speed_Clk), .mastClk(ClkPort), .bright(bright), .rst(Reset), .hCount(hCount), .vCount(vCount), .Head_X(Head_X), .Head_Y(Head_Y), .Tail_X(Tail_X), .Tail_Y(Tail_Y), .Apple_X(Apple_X), .Apple_Y(Apple_Y), .Cell_Snake_Vector(Cell_Snake_Vector), .rgb(rgb), .background(background));

	assign vgaR = rgb[11 : 8];
	assign vgaG = rgb[7  : 4];
	assign vgaB = rgb[3  : 0];
	assign QuadSpiFlashCS = 1'b1;

	// Clock division segment
	// BUFGP is a Xilinx primitive; for simulation, use simple wire assignment (uncomment BUFGP instantiation below for synthesis/FPGA implementation)
	// BUFGP BUFGP1 (board_clk, ClkPort);
	assign board_clk = ClkPort;

	assign Reset = BtnC;
	
	// Create a series of slower "divided" clocks
  	always @(posedge board_clk, posedge Reset) 	
    begin							
        if (Reset)
		DIV_CLK <= 0;
        else
		DIV_CLK <= DIV_CLK + 1'b1;
    end

	// In this design, we run the core design at full 100MHz clock
	assign	sys_clk = board_clk;
	
	// Snake movement clock
	assign Speed_Clk = DIV_CLK[24]; // DIV_CLK[24] gives ~6 Hz, good for visible snake movement

	// Indicate current state on LEDs.
	assign {Ld0, Ld1, Ld2, Ld3} = {q_I, q_Run, q_Lose, q_Win};
	
	// Display length on SSD
	reg [3:0]	SSD; // One-hot state assignment for which SSD to use
	wire [3:0]	SSD3, SSD2, SSD1, SSD0; // To display up to 225
	reg [7:0]  SSD_CATHODES;
	
	wire [7:0] hundreds, tens, ones;
	assign hundreds = Length / 100;           // Hundreds digit (0-2)
	assign tens = (Length / 10) % 10;         // Tens digit (0-9)
	assign ones = Length % 10;                // Ones digit (0-9)
	assign SSD3 = 4'd0;                       // Always 0 (leftmost digit unused)
	assign SSD2 = q_I ? 4'd0 : hundreds[3:0]; // Hundreds place - use 4 bits
	assign SSD1 = q_I ? 4'd0 : tens[3:0];     // Tens place - use 4 bits
	assign SSD0 = q_I ? 4'd3 : ones[3:0];     // Ones place - use 4 bits (show "3" initially for starting length)

	// Need a scan clk for the seven segment display 
	// 191Hz (100 MHz / 2^19) works well
	// 100 MHz / 2^18 = 381.5 cycles/sec ==> frequency of DIV_CLK[17]
	// 100 MHz / 2^19 = 190.7 cycles/sec ==> frequency of DIV_CLK[18]
	// 100 MHz / 2^20 =  95.4 cycles/sec ==> frequency of DIV_CLK[19]
	
	// 381.5 cycles/sec (2.62 ms per digit) [which means all 4 digits are lit once every 10.5 ms (reciprocal of 95.4 cycles/sec)] works well.
	//                  --|  |--|  |--|  |--|  |--|  |--|  |--|  |--|  |   
    //                    |  |  |  |  |  |  |  |  |  |  |  |  |  |  |  | 
	//  DIV_CLK[17]       |__|  |__|  |__|  |__|  |__|  |__|  |__|  |__|
	//
	//               -----|     |-----|     |-----|     |-----|     |
    //                    |  0  |  1  |  0  |  1  |     |     |     |     
	//  DIV_CLK[18]       |_____|     |_____|     |_____|     |_____|
	//
	//         -----------|           |-----------|           |
    //                    |  0     0  |  1     1  |           |           
	//  DIV_CLK[19]       |___________|           |___________|
	//
	
	assign ssdscan_clk = DIV_CLK[19:18];
	
	assign An3	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An2	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An1	=  !((ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An0	=  !((ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	// Close another four anodes
	assign An7 = 1'b1;
	assign An6 = 1'b1;
	assign An5 = 1'b1;
	assign An4 = 1'b1;
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
				  2'b00: SSD = SSD3;
				  2'b01: SSD = SSD2; 
				  2'b10: SSD = SSD1;
				  2'b11: SSD = SSD0;
		endcase 
	end
	
	// Convert SSD number to ssd
	// We convert the output of our 4-bit 3x1 mux

	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES};

	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)
			4'b0000: SSD_CATHODES = 8'b00000011; // 0
			4'b0001: SSD_CATHODES = 8'b10011111; // 1
			4'b0010: SSD_CATHODES = 8'b00100101; // 2
			4'b0011: SSD_CATHODES = 8'b00001101; // 3
			4'b0100: SSD_CATHODES = 8'b10011001; // 4
			4'b0101: SSD_CATHODES = 8'b01001001; // 5
			4'b0110: SSD_CATHODES = 8'b01000001; // 6
			4'b0111: SSD_CATHODES = 8'b00011111; // 7
			4'b1000: SSD_CATHODES = 8'b00000001; // 8
			4'b1001: SSD_CATHODES = 8'b00001001; // 9
			4'b1010: SSD_CATHODES = 8'b00010001; // A
			4'b1011: SSD_CATHODES = 8'b11000001; // B
			4'b1100: SSD_CATHODES = 8'b01100011; // C
			4'b1101: SSD_CATHODES = 8'b10000101; // D
			4'b1110: SSD_CATHODES = 8'b01100001; // E
			4'b1111: SSD_CATHODES = 8'b01110001; // F    
			default: SSD_CATHODES = 8'bXXXXXXXX; // default is not needed as we covered all cases
		endcase
	end	
	
endmodule

