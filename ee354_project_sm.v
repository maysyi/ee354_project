//////////////////////////////////////////////////////////////////////////////////
// File based on: ee354_GCD.v 
// Description: Modified significantly from template file, to execute Snake game. This file contains the NSL and SM
//////////////////////////////////////////////////////////////////////////////////

// QUESTIONS:
// How to check where TAIL is supposed to be?

// State machine module
module ee354_project_sm(Clk, SCEN, Reset, Ack, Next_Head_X, Next_Head_Y, Length, Cell_Snake, q_I, q_Run, q_Lose, q_Win);

	// INPUTS
	input	Clk, SCEN, Reset, Ack;
	input [3:0] Next_Head_X;
    input [3:0] Next_Head_Y;
    input [7:0] Length;
    input [255:0] Cell_Snake;

	// OUTPUTS
	output q_I, q_Run, q_Lose, q_Win; // States

    // LOCAL VARIABLES
	reg [3:0] state;
    assign {q_Win, q_Lose, q_Run, q_I} = state;	
	localparam 	
	I = 4'b0001, RUN = 4'b0010, LOSE = 4'b0100, WIN = 4'b1000, UNK = 4'bXXXX;
	
	// NSL AND SM
	always @ (posedge Clk, posedge Reset)
	begin 
		if(Reset) 
		  begin
			state <= I;		
		  end
		else
            case(state)	
                I:
                    state <= RUN;	
                RUN:
                    if (Cell_Snake[Next_Head_X*16 + Next_Head_Y] == 1) // Snake bit itself (Head is at a position on the grid that is not empty - aka marked as 1 already)
                        state <= LOSE;
                    else if (Length == 255)
                        state <= WIN;
                LOSE:
                    // State transfers
                    if (Ack)
                        state <= I;
                WIN:
                    // State transfers
                    if (Ack)
                        state <= I;
                default:		
                    state <= UNK;
            endcase
	end
	
endmodule