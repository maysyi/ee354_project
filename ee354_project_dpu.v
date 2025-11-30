//////////////////////////////////////////////////////////////////////////////////
// File based on: ee354_GCD.v 
// Description: Modified significantly from template file, to execute Snake game. This file contains the DPU
//////////////////////////////////////////////////////////////////////////////////

// Module to generate apple
module ee354_project_apples(Clk, SCEN, Reset, Cell_Snake_Vector, New_Apple, Apple_X, Apple_Y);

    // INPUTS
    input Clk, SCEN, Reset;
    input [224:0] Cell_Snake_Vector; // Presence of snake body taken from another module (probably Length)
    input New_Apple; // Request for new apple from another module (probably Length)

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
    
    wire [3:0] LFSR_X = LFSR[7:4] % 15;
    wire [3:0] LFSR_Y = LFSR[3:0] % 15;

    wire Cell_Check = Cell_Snake_Vector[LFSR_X*15 + LFSR_Y]; // Checks if generated apple location is where snake is

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

// Module to update length and position of snake head and tail
module ee354_project_length(Clk, SCEN, Reset, Speed_Clk, q_I, q_Run, q_Win, q_Lose, In_Dirn, Head_X, Head_Y, Apple_X, Apple_Y, Length, Cell_Snake);

    // INPUTS
    input Clk, SCEN, Reset, Speed_Clk; // Speed_Clk need to generate in top file (the speed/intervals at which the snake moves)
    input q_I, q_Run, q_Win, q_Lose;
    input [1:0] In_Dirn; // Encoded "state" assignment. This tells us which button is pushed. Data from top file
    input [3:0] Apple_X;
    input [3:0] Apple_Y;

    // OUTPUT
    output reg [7:0] Length;
    output reg [7:0] Cell_Snake [0:224]; // 225 registers to store coordinates for each snake part (1111 1111 means snake part does not exist yet)
    output reg [3:0] Head_X;
    output reg [3:0] Head_Y;
    output reg [3:0] Tail_X;
    output reg [3:0] Tail_Y;
    output reg New_Apple;
    output reg Collision;

    // LOCAL VARIABLES
    reg [7:0] Head_Ptr; // Points to NEXT head in circular buffer
    reg [7:0] Tail_Ptr; // Points to NEXT tail in circular buffer
    reg [3:0] Curr_Dirn;

    // Update Head and Tail
    always @(posedge Clk, posedge Reset) 
    begin
        if (Reset)
            begin
                Cell_Snake[0] <= 8'h86 // Tail at (8, 6)
                Cell_Snake[1] <= 8'h87
                Cell_Snake[2] <= 8'h88 // Head at (8, 8)
                for (i = 3; i < 225; i = i + 1)
                    Cell_Snake[i] <= 8'hFF;
                Head_X <= 4'h8;
                Head_Y <= 4'h8;
                Tail_X <= 4'h8;
                Tail_Y <= 4'h6;
                Head_Ptr <= 8'h02; // Points to current head at index 2
                Tail_Ptr <= 8'h00; // Points to current tail at index 0
                Length <= 8'h03;
                New_Apple <= 0;
                Collision <= 0;
                Current_Dirn <= 2'b00; // Start moving up first
            end
        else if (q_Run) // Need to add conditional state requirement
            begin
                if (SCEN) // When button pressed
                    // Update current direction
                    Current_Dirn <= In_Dirn
                
                if (Speed_Clk)
                begin
                    // Update next location of head (note blocking assignment)
                    case (Current_Dirn)
                        2'b00: // UP
                            Next_Head_Y = Head_Y + 4'h1;
                        2'b01: // DOWN
                            Next_Head_Y = Head_Y - 4'h1; 
                        2'b10: // LEFT
                            Next_Head_X = Head_X - 4'h1; 
                        2'b11: // RIGHT
                            Next_Head_X = Head_X + 4'h1; 
                    endcase

                    // If apple eaten (add head but don't remove tail)
                    if ((Next_Head_X == Apple_X) && (Next_Head_Y == Apple_Y))
                    begin
                        Head_Ptr <= (Head_Ptr + 8'h01) % 225; // Loops back to 0 when exceeds 225
                        Cell_Snake[(Head_Ptr + 8'h01) % 225] <= {Next_Head_X, Next_Head_Y};
                        Head_X <= Next_Head_X;
                        Head_Y <= Next_Head_Y;
                        Length <= Length + 8'h01;
                        New_Apple <= 1;
                    end
                    // If apple not eaten (just continue moving)
                    else 
                    begin
                        Head_Ptr <= (Head_Ptr + 8'h01) % 225; // Loops back to 0 when exceeds 225
                        Cell_Snake[(Head_Ptr + 8'h01) % 225] <= {Next_Head_X, Next_Head_Y};
                        Head_X <= Next_Head_X;
                        Head_Y <= Next_Head_Y;
                        Tail_Ptr <= (Tail_Ptr + 8'h01) % 225;
                        Cell_Snake[Tail_Ptr] <= 8'hFF; // Mark old tail as empty
                        Tail_X <= Cell_Snake[(Tail_Ptr + 8'h01) % 225][7:4]; // Extract X from new tail
                        Tail_Y <= Cell_Snake[(Tail_Ptr + 8'h01) % 225][3:0]; // Extract Y from new tail 
                        New_Apple <= 0;                   
                    end

                    // Check for wall or body collision
                    if ((Next_Head_X > 4'hE) || (Next_Head_Y > 4'hE))
                        Collision <= 1;
                    else
                        for (i=0; i<225; i=i+1)
                        begin
                            if (Cell_Snake[i] != 8'hFF) // If this segment exists
                            begin
                                if ((Cell_Snake[i][7:4] == Next_Head_X) && (Cell_Snake[i][3:0] == Next_Head_Y))
                                begin
                                    Collision = 1;
                                    return;
                                end
                            end
                        end
                end
            end
    end    

endmodule
