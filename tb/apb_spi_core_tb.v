module apb_spi_core_tb;

	reg	PCLK = 0,
		PRESET_n,
		PWRITE,
		PSEL,
		PENABLE;
	reg [2:0]	PADDR;
	reg [7:0]	PWDATA;
	wire		PREADY,
				PSLVERR;
	wire [7:0]	PRDATA;
	reg			miso;
	wire		ss,
				sclk,
				spi_interrupt_request,
				mosi;
								
	apb_spi_core DUT(	PCLK,
						PRESET_n,
						PWRITE,
						PSEL,
						PENABLE,
						PADDR,
						PWDATA,
						PRDATA,
						PREADY,
						PSLVERR,
						miso,
						ss,
						sclk,
						spi_interrupt_request,
						mosi);
						
	always #5 PCLK = ~PCLK;
	
	task reset;
		begin
		#10;
		PRESET_n = 1'b0;
		#10;
		PRESET_n = 1'b1;
		end
	endtask
	
	task initialize;
		begin
			PRESET_n = 1'b1;
			PWRITE = 1'b0;
			PSEL = 1'b0;
			PENABLE = 1'b0;
			PADDR = 3'b000;
			PWDATA = 8'h00;
			miso =1'b0;
		end
	endtask
	
	task reg_write(input [2:0] addr, input [7:0] data);
		begin
			@(negedge PCLK)
			PADDR = addr;
			PWRITE = 1'b1;
			PSEL = 1'b1;
			PENABLE = 1'b0;
			PWDATA = data;
			
			@(negedge PCLK)
			PENABLE = 1'b1;
			
			@(negedge PCLK)
			PENABLE = 1'b1;

			@(negedge PCLK)
			PENABLE = 1'b1;
			
			@(negedge PCLK)
			PWRITE = 1'b0;
			PSEL = 1'b0;
			PENABLE = 1'b0;
		end
	endtask
	
	task reg_read(input [2:0] addr);
		begin
			@(negedge PCLK)
			PADDR = addr;
			PWRITE = 1'b0;
			PSEL = 1'b1;
			PENABLE = 1'b0;
			
			@(negedge PCLK)
			PENABLE = 1'b1;
			
			@(negedge PCLK)
			PENABLE = 1'b1;

			@(negedge PCLK)
			PENABLE = 1'b1;
			
			@(negedge PCLK)
			PWRITE = 1'b0;
			PSEL = 1'b0;
			PENABLE = 1'b0;
		end
	endtask
	
	task send_spi_slave_data(input [7:0] slave_data);
        integer i;
        begin
            // Wait for Chip Select to become active (active low)
            wait (ss == 1'b0);
            for (i = 7; i >= 0; i = i - 1) begin
                // Drive MISO on the falling edge of SCLK so the master 
                // can sample it safely on the rising edge
                @(negedge sclk);
                miso = slave_data[i];
            end
        end
    endtask
		
	initial begin
		reset;
		#10;
		initialize;
		#20;
		reg_write(3'b000,8'b0101_0001);//to control reg 1
		reg_write(3'b010,8'b0000_0010);//to baudrate reg
		#300;
		reg_write(3'b000,8'b0101_0101);//to control reg 1
		#300;
		reg_write(3'b000,8'b0101_1101);//to control reg 1
		#300;
		reg_write(3'b000,8'b0101_1001);//to control reg 1
		#200;
		reg_write(3'b000,8'b0101_1001);//to control reg 1
		#200;
		reg_write(3'b101,8'b0101_1010);//to data reg
		#600;
		reg_read(3'b000);//read the control reg 1 
		#200;
		reg_write(3'b000,8'b0000_0100);//write to control reg 1
		#200;
		reg_write(3'b001,8'b0100_0010);//write to control reg 2
		#200;
		reg_write(3'b001,8'b0000_0000);//write to control reg 2 (deassert spiswai)
		reg_write(3'b000,8'b0101_0100);//write to control reg 1 (assert spe,mstr,cpha,lsbfe)
		#200
		reg_write(3'b101, 8'hFF);	//write to data reg (for dummy data to receive the miso data
		send_spi_slave_data(8'b1010_1001); //receive the miso data
		#500;
		reg_read(3'b101);//read the data register
		#1000 $finish;
	end

endmodule
