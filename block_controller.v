`timescale 1ns / 1ps

module block_controller(
	// input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input mastClk,
	input bright,
	input rst,
	// input up, input down, input left, input right,
	input [9:0] hCount, vCount,
	input [3:0] Head_X, Head_Y, Tail_X, Tail_Y, Apple_X, Apple_Y,
	input [224:0] Cell_Snake_Vector,
	output reg [11:0] rgb,
	output reg [11:0] background
   );
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	// reg[3:0] Head_X, Head_Y;
	// reg[3:0] Tail_X, Tail_Y;
	
	wire [11:0] apple_color;
	wire[11:0] sh_color; 
	wire [11:0] sb_color;
	wire [11:0] tile_color;


	localparam CELL_SIZE = 30;
	localparam GRID_SIZE = 15;
	localparam H_CENTER  = (640 - GRID_SIZE*CELL_SIZE)/2;
	localparam V_CENTER  = (480 - GRID_SIZE*CELL_SIZE)/2;

	localparam integer SHIFT_X = 2;
	localparam integer SHIFT_Y = 1;

	localparam integer H_OFFSET = H_CENTER + SHIFT_X*CELL_SIZE;
	localparam integer V_OFFSET = V_CENTER + SHIFT_Y*CELL_SIZE;


	wire in_grid_x = (hCount >= H_OFFSET) &&
                     (hCount <  H_OFFSET + GRID_SIZE*CELL_SIZE);
    wire in_grid_y = (vCount >= V_OFFSET) &&
                     (vCount <  V_OFFSET + GRID_SIZE*CELL_SIZE);

	wire in_grid = in_grid_x && in_grid_y;
	// wire [9:0] rel_x = hCount - H_OFFSET;
	// wire [9:0] rel_y = vCount - V_OFFSET;

	wire [9:0] rel_x = in_grid_x ? (hCount - H_OFFSET) : 10'd0;
	wire [9:0] rel_y = in_grid_y ? (vCount - V_OFFSET) : 10'd0;


	// // which tile are we in? (0–14)
	// wire [3:0] tile_x = rel_x / CELL_SIZE;
	// wire [3:0] tile_y = rel_y / CELL_SIZE;

	function [3:0] tile_from_rel;
    input [9:0] rel;
    begin
        if      (rel <  30)  tile_from_rel = 4'd0;
        else if (rel <  60)  tile_from_rel = 4'd1;
        else if (rel <  90)  tile_from_rel = 4'd2;
        else if (rel < 120)  tile_from_rel = 4'd3;
        else if (rel < 150)  tile_from_rel = 4'd4;
        else if (rel < 180)  tile_from_rel = 4'd5;
        else if (rel < 210)  tile_from_rel = 4'd6;
        else if (rel < 240)  tile_from_rel = 4'd7;
        else if (rel < 270)  tile_from_rel = 4'd8;
        else if (rel < 300)  tile_from_rel = 4'd9;
        else if (rel < 330)  tile_from_rel = 4'd10;
        else if (rel < 360)  tile_from_rel = 4'd11;
        else if (rel < 390)  tile_from_rel = 4'd12;
        else if (rel < 420)  tile_from_rel = 4'd13;
        else                 tile_from_rel = 4'd14; // up to 450
    end
	endfunction

	reg [3:0] tile_x , tile_y ;

	always @* begin
    if (in_grid) begin
        tile_x = tile_from_rel(rel_x);
        tile_y = tile_from_rel(rel_y);
    end else begin
        tile_x = 4'd0;
        tile_y = 4'd0;
    end
	end

	wire [9:0] tile_x_base = tile_x * CELL_SIZE; // 30 = 16+8+4+2 -> shifts/adds, cheap
	wire [9:0] tile_y_base = tile_y * CELL_SIZE;

	wire [4:0] tile_col = rel_x - tile_x_base; // 0..29
	wire [4:0] tile_row = rel_y - tile_y_base; // 0..29


	// // which pixel inside the tile? (0–29)
	// wire [4:0] tile_row = rel_y % CELL_SIZE;
	// wire [4:0] tile_col = rel_x % CELL_SIZE;	

	wire [7:0] cell_index = tile_x * GRID_SIZE + tile_y;

	wire snake_here = in_grid && Cell_Snake_Vector[cell_index];
	wire head_here = in_grid && (tile_x == Head_X) && (tile_y == Head_Y);
	wire apple_here = in_grid && (tile_x == Apple_X) && (tile_y == Apple_Y);
	wire body_here = in_grid && (tile_x == Tail_X) && (tile_y == Tail_Y);


	// apple_rom ar(.clk(mastClk), .row(vCount-APPLE_Y_POS), .col(hCount-APPLE_X_POS), .color_data(apple_color));
	// snakeHead_rom shr(.clk(mastClk), .row(vCount-yHeadPos), .col(hCount-xHeadPos), .color_data(sh_color));
	// snakeBody_rom sbr(.clk(mastClk), .row(vCount-yBodyPos), .col(hCount-xBodyPos), .color_data(sb_color));
	// bg_rom br (.clk(mastClk), .row(tile_row), .col(tile_col), .color_data(tile_color));

	apple_rom ar(.clk(mastClk), .row(tile_row), .col(tile_col), .color_data(apple_color));
	snakeHead_rom shr(.clk(mastClk), .row(tile_row), .col(tile_col), .color_data(sh_color));
	snakeBody_rom sbr(.clk(mastClk), .row(tile_row), .col(tile_col), .color_data(sb_color));
	bg_rom br (.clk(mastClk), .row(tile_row), .col(tile_col), .color_data(tile_color));


	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (apple_here) 
			rgb = apple_color; 
		else if (head_here)
			rgb = sh_color;
		else if (body_here || snake_here)
			rgb = sb_color;
		else if (in_grid)	
			rgb=tile_color;
		else
			rgb=background;
	end


	
	
endmodule
