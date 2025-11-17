//////////////////////////////////////////////////////////////////////////////////
// File based on: ee354_GCD.v 
// Description: Modified significantly from template file, to execute Snake game. This file contains the NSL and SM
//////////////////////////////////////////////////////////////////////////////////

// State machine module
module ee354_project_sm(Clk, SCEN, Reset, Ack, In_Dirn, Out_Dirn, Collide, Full, q_I, q_Up, q_Down, q_Left, q_Right, q_Lose, q_Win);

	// INPUTS
	input	Clk, SCEN, Reset, Ack;
	input [1:0] In_Dirn; // Encoded "state" assignment. This tells us which button is pushed.
    // Up: 00, Down: 01, Left: 10, Right: 11
    input Collide, Full;
	
	// OUTPUTS
	output reg [1:0] Out_Dirn; // Output to trigger direction of snake in VGA
	output q_I, q_Up, q_Down, q_Left, q_Right, q_Lose, q_Win; // States

    // LOCAL VARIABLES
	reg [6:0] state;
    assign {q_Win, q_Lose, q_Right, q_Left, q_Down, q_Up, q_I} = state;	
	localparam 	
	I = 7'b0000001, UP = 7'b0000010, DOWN = 7'b0000100, LEFT = 7'b0001000, RIGHT = 7'b0010000, LOSE = 7'b0100000, WIN = 7'b1000000, UNK = 7'bXXXXXXX;
	
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
                    state <= UP;	
                UP: 
                    if (SCEN)
                    begin		
                        // State transfers
                        if (Collide)
                            state <= LOSE;
                        else if (Full)
                            state <= WIN;
                        else
                            if (In_Dirn == 2'b10)
                                state <= LEFT;
                            // else if (In_Dirn == 2'b01) // Because there is no 180deg turn in Snake game
                            //     state <= DOWN;
                            else if (In_Dirn == 2'b11)
                                state <= RIGHT;
                    end
                LEFT:
                    if (SCEN)
                    begin
                        // State transfers
                        if (Collide)
                            state <= LOSE;
                        else if (Full)
                            state <= WIN;
                        else
                            if (In_Dirn == 2'b00)
                                state <= UP;
                            else if (In_Dirn == 01)
                                state <= DOWN;
                            // else if (In_Dirn == 2'b11)
                            //     state <= RIGHT;
                    end
                DOWN:
                    if (SCEN)
                    begin
                        // State transfers
                        if (Collide)
                            state <= LOSE;
                        else if (Full)
                            state <= WIN;
                        else
                            // if (In_Dirn == 2'b00)
                            //     state <= UP;
                            else if (In_Dirn == 2'b10)
                                state <= LEFT;
                            else if (In_Dirn == 2'b11)
                                state <= RIGHT;
                    end
                RIGHT:
                    if (SCEN)
                    begin
                        // State transfers
                        if (Collide)
                            state <= LOSE;
                        else if (Full)
                            state <= WIN;
                        else
                            if (In_Dirn == 2'b00)
                                state <= UP;
                            else if (In_Dirn == 01)
                                state <= DOWN;
                            // else if (In_Dirn == 2'b10)
                            //     state <= LEFT;
                    end
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
		
    // Output signal
    always @(*) begin
        case(state)
            UP:    Out_Dirn = 2'b00;
            DOWN:  Out_Dirn = 2'b01;
            LEFT:  Out_Dirn = 2'b10;
            RIGHT: Out_Dirn = 2'b11;
            default: Out_Dirn = 2'b00;
        endcase
    end
	
endmodule