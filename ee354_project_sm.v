//////////////////////////////////////////////////////////////////////////////////
// File based on: ee354_GCD.v 
// Description: Modified significantly from template file, to execute Snake game. This file contains the NSL and SM
//////////////////////////////////////////////////////////////////////////////////

// Add coordinates for each snake part (up to 255)

// State machine module
module ee354_project_sm(Clk, Reset, Ack, Collision, Length, Cell_Snake, q_I, q_Run, q_Lose, q_Win);

	// INPUTS
	input Clk, Reset, Ack;
    input Collision;
    input [7:0] Length;

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
                    if (Collision)
                        state <= LOSE;
                    else if (Length == 8'd225)
                        state <= WIN;
                    else
                        state <= RUN;
                LOSE:
                    // State transfers
                    if (Ack)
                        state <= I;
                    else
                        state <= LOSE;
                WIN:
                    // State transfers
                    if (Ack)
                        state <= I;
                    else 
                        state <= WIN;
                default:		
                    state <= UNK;
            endcase
	end
	
endmodule