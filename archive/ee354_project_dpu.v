//////////////////////////////////////////////////////////////////////////////////
// File based on: ee354_GCD.v 
// Description: Modified significantly from template file, to execute Snake game. This file contains the DPU
//////////////////////////////////////////////////////////////////////////////////

// Module to generate apple
module ee354_project_apples(Clk, SCEN, Reset, Cell_Snake, New_Apple, Apple_X, Apple_Y);

    // INPUTS
    input Clk, SCEN, Reset;
    input [255:0] Cell_Snake; // Presence of snake body taken from another module (probably Length)
    input wire New_Apple; // Request for new apple from another module (probably Length)

    // OUTPUT
    output reg [3:0] Apple_X;
    output reg [3:0] Apple_Y;

    // LOCAL VARIABLES
    reg [7:0] LFSR; // Linear Feedback Shift Register (seemingly random number generator)
    
    always @(posedge Clk or posedge Reset)
        begin
            if (Reset)
            LFSR <= 8'hA5; // Seed
            else
                begin
                    LFSR <= {LFSR[6:0], LFSR[7] ^LFSR[5] ^ LFSR[4] ^ LFSR[3]};
                end
        end
    
    wire [3:0] LFSR_X = LFSR[7:4] % 16;
    wire [3:0] LFSR_Y = LFSR[3:0] % 16;

    wire Cell_Check = Cell_Snake[LFSR_X*16 + LFSR_Y]; // Checks if generated apple location is where snake is

    always @ (posedge Clk)
    begin
        if (Reset)
            begin
                Apple_X <= 4'd3;
                Apple_Y <= 4'd3;
            end
        else if (New_Apple && !Cell_Check)
            begin
                Apple_X <= LFSR_X;
                Apple_Y <= LFSR_Y;
            end
    end

endmodule

// Module to update cell direction instruction and position of head (Using new method, unnecessary)
/*
module ee354_project_head_control(Clk, SCEN, Reset, In_Dirn, Head_X, Head_Y);

	// INPUTS
	input Clk, SCEN, Reset;
	input [1:0] In_Dirn; // Encoded "state" assignment. This tells us which button is pushed. Data from top file
    // Up: 00, Down: 01, Left: 10, Right: 11

    // OUTPUT
    output reg [3:0] Head_X
    output reg [3:0] Head_Y
	
    // LOCAL VARIABLES
	reg [1:0] Cell_Dirn[0:15][0:15]; // 16x16 cells holding 2 bit instructions for direction.
    reg [1:0] Head_Dirn;
    integer i, j;
	
    // Data transfer for position and length
	always @ (posedge Reset)
	begin 
        for (i = 0; i < 16; i = i + 1)
            for (j = 0; j < 16; j = j + 1)
                Cell_Dirn[i][j] <= 2'b00;   // UP
        Head_X <= 4'd8;
        Head_Y <= 4'd8; // Set in center of screen
	end

    assign Head_Dirn = Cell_Dirn[Head_X][Head_Y];
		
    always @ (posedge Clk)
    begin
        if (!Reset & SCEN)
            if (In_Dirn != Head_Dirn)
                begin
                    case(In_Dirn)
                        2'b00: // UP
                            begin
                                if (Head_Dirn != 2'b01)
                                    for (i = 0; i < 16; i = i + 1)
                                        Cell_Dirn[Head_X][i] <= 2'b00;
                            end
                        2'b01: // DOWN
                            begin
                                if (Head_Dirn != 2'b00)
                                    for (i = 0; i < 16; i = i + 1)
                                        Cell_Dirn[Head_X][i] <= 2'b01;
                            end
                        2'b10: // LEFT
                            begin
                                if (Head_Dirn != 2'b11)
                                    for (i = 0; i < 16; i = i + 1)
                                        Cell_Dirn[Head_X][i] <= 2'b10;
                            end
                        2'b11: //RIGHT
                            begin
                                if (Head_Dirn != 2'b10)
                                    for (i = 0; i < 16; i = i + 1)
                                        Cell_Dirn[Head_X][i] <= 2'b11;
                            end
                    endcase
                end

            case(Cell_Dirn[Head_X][Head_Y])
                2'b00: Head_Y <= Head_Y + 1;  // UP
                2'b01: Head_Y <= Head_Y - 1;  // DOWN
                2'b10: Head_X <= Head_X - 1;  // LEFT
                2'b11: Head_X <= Head_X + 1;  // RIGHT
            endcase
    end
endmodule
*/

// Module to update length and position of snake head and tail
module ee354_project_length(Clk, SCEN, Reset, In_Dirn, Head_X, Head_Y, Apple_X, Apple_Y, Length, Cell_Snake);

    // INPUTS
    input Clk, SCEN, Reset;
    input [1:0] In_Dirn; // Encoded "state" assignment. This tells us which button is pushed. Data from top file
    input [3:0] Apple_X;
    input [3:0] Apple_Y;

    // OUTPUT
    output reg [7:0] Length;
    output reg [255:0] Cell_Snake;
    output [3:0] Head_X;
    output [3:0] Head_Y;
    output wire New_Apple;

    // LOCAL VARIABLES
    reg [3:0] Tail_X;
    reg [3:0] Tail_Y;

    // Update Head
    always @(posedge Clk, posedge Reset) begin
        if (Reset)
            begin
                Head_X <= 8;
                Head_Y <= 8;
                Length <= 2;
                Cell_Snake <= 0;
                Cell_Snake[Head_X*16 + Head_Y] <= 1;
                Tail_X <= Head_X;
                Tail_Y <= Head_Y - 1;
                Cell_Snake[Tail_X*16 + Tail_Y] <= 1;
                New_Apple <= 0;
            end
        else if (SCEN) // Need to add conditional state requirement
            begin
                // Update head based on input
                Tail_X <= Head_X;
                Tail_Y <= Head_Y;
                case (In_Dirn)
                    2'b00: // UP
                        Head_Y <= Head_Y + 1; 
                    2'b01: // DOWN
                        Head_Y <= Head_Y - 1; 
                    2'b10: // LEFT
                        Head_X <= Head_X - 1; 
                    2'b11: // RIGHT
                        Head_X <= Head_X + 1; 
                endcase

                // Handle tail
                if ((Head_X == Apple_X) && (Head_Y == Apple_Y))
                    begin
                        Cell_Snake[Head_X*16 + Head_Y] <= 1;
                        New_Apple <= 1;
                        Length <= Length + 1;
                    end
                else
                    begin
                        Cell_Snake[Head_X*16 + Head_Y] <= 1;
                        Cell_Snake[Tail_X*16 + Tail_Y] <= 0;
                        New_Apple <= 0;
                    end
            end
    end    

endmodule
