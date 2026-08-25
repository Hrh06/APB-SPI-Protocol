`define SPI_APB_DATA_WIDTH 8
`define SPI_REG_WIDTH 8
`define SPI_APB_ADDR_WIDTH 3
module apb_slave_interface_tb;

	reg PCLK = 1'b0;
	reg	PRESET_n,
		PWRITE,
		PSEL,
		PENABLE,
		ss,
		receive_data,
		tip;
	reg [`SPI_APB_ADDR_WIDTH-1:0] PADDR;
	reg [`SPI_APB_DATA_WIDTH-1:0] PWDATA;
	reg [`SPI_APB_DATA_WIDTH-1:0] miso_data;
	wire	mstr,
			cpol,
			cpha,
			lsbfe,
			spiswai,
			spi_interrupt_request,
			send_data,
			PREADY,
			PSLVERR;
	wire	[`SPI_APB_DATA_WIDTH-1:0] mosi_data;
	wire	[1:0] spi_mode;
	wire	[`SPI_APB_DATA_WIDTH-1:0] PRDATA;
	wire	[2:0] sppr,
			spr;
			
	apb_slave_interface DUT(	PCLK,
								PRESET_n,
								PWRITE,
								PSEL,
								PENABLE,
								ss,
								receive_data,
								tip,
								PADDR,
								PWDATA,
								miso_data,
								mstr,
								cpol,
								cpha,
								lsbfe,
								spiswai,
								spi_interrupt_request,
								send_data,
								PREADY,
								PSLVERR,
								mosi_data,
								spi_mode,
								PRDATA,
								sppr,
								spr);

	always #5 PCLK = ~PCLK;
	
	task reset;
		begin
			@(negedge PCLK)
			PRESET_n = 1'b0;
			@(negedge PCLK)
			PRESET_n = 1'b1;
		end
	endtask
	
	task initialize;
		begin
		//Control register 1 write
		@(negedge PCLK)
		PADDR = 3'b0;
		PWRITE = 1'b1;
		PSEL = 1'b1;
		PENABLE = 1'b0;
		PWDATA = 8'b1111_0100;
		ss = 1'b1;
		tip = 1'b0;
		
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
		
		//Control register 2 write
		@(negedge PCLK)
		PADDR = 3'b1;
		PWRITE = 1'b1;
		PSEL = 1'b1;
		PENABLE = 1'b0;
		PWDATA = 8'b1100_0010;
		
		@(negedge PCLK)
		PADDR = 3'b1;
		PWRITE = 1'b1;
		PSEL = 1'b1;
		PENABLE = 1'b1;
		PWDATA = 8'b1100_0010;
		
		@(negedge PCLK)
		PENABLE = 1'b1;

		@(negedge PCLK)
		PENABLE = 1'b1;
		
		@(negedge PCLK)
		PWRITE = 1'b0;
		PSEL = 1'b0;
		PENABLE = 1'b0;
		
		//Baud register Write
		@(negedge PCLK)
		PADDR = 3'b010;
		PWRITE = 1'b1;
		PSEL = 1'b1;
		PENABLE = 1'b0;
		PWDATA = 8'b0010_0111;
		
		@(negedge PCLK)
		PADDR = 3'b010;
		PWRITE = 1'b1;
		PSEL = 1'b1;
		PENABLE = 1'b1;
		PWDATA = 8'b0010_0111;
		
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
	
	task write;
		begin
		@(negedge PCLK)
		PADDR = 3'b101;
		PWRITE = 1'b1;
		PSEL = 1'b1;
		PENABLE = 1'b0;
		PWDATA = 8'b1100_1111;
		
		@(negedge PCLK)
		PADDR = 3'b101;
		PWRITE = 1'b1;
		PSEL = 1'b1;
		PENABLE = 1'b1;
		PWDATA = 8'b1100_1111;
		
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
	
	task read;
		begin
		@(negedge PCLK)
		PADDR = 3'b101;
		PWRITE = 1'b0;
		PSEL = 1'b1;
		PENABLE = 1'b0;
		
		@(negedge PCLK)
		PADDR = 3'b101;
		PWRITE = 1'b0;
		PSEL = 1'b1;
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
	
	initial begin
		#5;
		reset;
		#10;
		initialize;
		#10;
		write;
		#10;
		miso_data = 8'hff;
		ss =1'b0;
		receive_data = 1'b1;
		read;
		#20;
		receive_data = 1'b0;
		#50 $finish;
	end

endmodule