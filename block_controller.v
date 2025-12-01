`timescale 1ns / 1ps

module block_controller(
	input clk, //this clock must be a slow enough clock to view the changing positions of the objects
	input mastClk,
	input bright,
	input rst,
	input up, input down, input left, input right,
	input [9:0] hCount, vCount,
	output reg [11:0] rgb,
	output reg [11:0] background
   );
	
	//these two values dictate the center of the block, incrementing and decrementing them leads the block to move in certain directions
	reg[3:0] head_x, head_y;
	reg[3:0] body_x, body_y;
	wire [9:0] xHeadPos;
	wire [9:0] yHeadPos;
	wire [9:0] xBodyPos;
	wire [9:0] yBodyPos;
	
	// reg moveUp;
	wire [11:0] apple_color;
	wire[11:0] sh_color; 
	wire [11:0] sb_color;
	wire [11:0] tile_color;
	parameter RED   = 12'b1111_0000_0000;

	wire apple_fill;
	wire head_fill;
	wire body_fill;

	//pull from top file later 
	localparam [9:0] APPLE_X = 300;
    localparam [9:0] APPLE_Y = 200;

	localparam CELL_SIZE = 30;
	localparam GRID_SIZE = 15;
	localparam H_OFFSET  = (640 - GRID_SIZE*CELL_SIZE)/2;
	localparam V_OFFSET  = (480 - GRID_SIZE*CELL_SIZE)/2;

	wire in_grid_x = (hCount >= H_OFFSET) &&
                     (hCount <  H_OFFSET + GRID_SIZE*CELL_SIZE);
    wire in_grid_y = (vCount >= V_OFFSET) &&
                     (vCount <  V_OFFSET + GRID_SIZE*CELL_SIZE);

	wire in_grid = in_grid_x && in_grid_y;
	wire [9:0] rel_x = hCount - H_OFFSET;
	wire [9:0] rel_y = vCount - V_OFFSET;

	// which tile are we in? (0–14)
	wire [3:0] tile_x = rel_x / CELL_SIZE;
	wire [3:0] tile_y = rel_y / CELL_SIZE;

	// which pixel inside the tile? (0–29)
	wire [4:0] tile_row = rel_y % CELL_SIZE;
	wire [4:0] tile_col = rel_x % CELL_SIZE;	

	assign xHeadPos = H_OFFSET + head_x * CELL_SIZE;
	assign yHeadPos = V_OFFSET + head_y * CELL_SIZE;

	assign xBodyPos = H_OFFSET + body_x * CELL_SIZE;
	assign yBodyPos = V_OFFSET + body_y * CELL_SIZE;


	apple_rom ar(.clk(mastClk), .row(vCount-APPLE_Y), .col(hCount-APPLE_X), .color_data(apple_color));
	snakeHead_rom shr(.clk(mastClk), .row(vCount-yHeadPos), .col(hCount-xHeadPos), .color_data(sh_color));
	snakeBody_rom sbr(.clk(mastClk), .row(vCount-yBodyPos), .col(hCount-xBodyPos), .color_data(sb_color));
	bg_rom br (.clk(mastClk), .row(tile_row), .col(tile_col), .color_data(tile_color));

	assign apple_fill = (vCount >= APPLE_Y) && (vCount <= APPLE_Y + 29) && 
						(hCount >= APPLE_X) && (hCount <= APPLE_X + 29);
	assign sh_fill = (vCount >= yHeadPos) && (vCount <= yHeadPos + 29) && 
						(hCount >= xHeadPos) && (hCount <= xHeadPos + 29);
	assign sb_fill = (vCount >= yBodyPos) && (vCount <= yBodyPos + 29) && 
						(hCount >= xBodyPos) && (hCount <= xBodyPos + 29);

	/*when outputting the rgb value in an always block like this, make sure to include the if(~bright) statement, as this ensures the monitor 
	will output some data to every pixel and not just the images you are trying to display*/
	always@ (*) begin
    	if(~bright )	//force black if not inside the display area
			rgb = 12'b0000_0000_0000;
		else if (apple_fill) 
			rgb = apple_color; 
		else if (sh_fill)
			rgb = sh_color;
		else if (sb_fill)
			rgb = sb_color;
		else if (in_grid)	
			rgb=tile_color;
		else
			rgb=background;
	end
		//the +-5 for the positions give the dimension of the block (i.e. it will be 10x10 pixels)
	
	always@(posedge clk, posedge rst) 
	begin
		if(rst)
		begin 
			//rough values for center of screen
			head_x <= 7;   // roughly center (0..14)
			head_y <= 7;
			body_x <= 6;   // one tile behind
			body_y <= 7;
			// moveUp <= 1'b0;
		end
		else if (clk) begin
		
		/* Note that the top left of the screen does NOT correlate to vCount=0 and hCount=0. The display_controller.v file has the 
			synchronizing pulses for both the horizontal sync and the vertical sync begin at vcount=0 and hcount=0. Recall that after 
			the length of the pulse, there is also a short period called the back porch before the display area begins. So effectively, 
			the top left corner corresponds to (hcount,vcount)~(144,35). Which means with a 640x480 resolution, the bottom right corner 
			corresponds to ~(783,515).  
		*/

			if(right) begin
				body_x <= head_x;
        		body_y <= head_y;
				head_x <= (head_x == GRID_SIZE-1) ? 0 : head_x + 1;
			end
			else if(left) begin
				body_x <= head_x;
        		body_y <= head_y;
				head_x <= (head_x == 0) ? GRID_SIZE-1 : head_x - 1;
			end
			else if(up) begin
				body_x <= head_x;
       			body_y <= head_y;	
				head_y <= (head_y == 0) ? GRID_SIZE-1 : head_y - 1;
			end
			else if(down) begin
				body_x <= head_x;
        		body_y <= head_y;
				head_y <= (head_y == GRID_SIZE-1) ? 0 : head_y + 1;
			end
		end
	end
	
	//the background color reflects the most recent button press
	always@(posedge clk, posedge rst) begin
		if(rst)
			background <= 12'b1111_1111_1111;
		else 
			if(right)
				background <= 12'b1111_1111_0000;
			else if(left)
				background <= 12'b0000_1111_1111;
			else if(down)
				background <= 12'b0000_1111_0000;
			else if(up)
				background <= 12'b0000_0000_1111;
	end

	
	
endmodule
