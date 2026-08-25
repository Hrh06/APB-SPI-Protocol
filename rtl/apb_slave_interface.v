	`define SPI_APB_DATA_WIDTH 8
	`define SPI_REG_WIDTH 8
	`define SPI_APB_ADDR_WIDTH 3
module apb_slave_interface(input	PCLK,
					PRESET_n,
					PWRITE_i,
					PSEL_i,
					PENABLE_i,
					ss_i,
					receive_data_i,
					tip_i,
				input [`SPI_APB_ADDR_WIDTH-1:0]	PADDR_i,
				input [`SPI_APB_DATA_WIDTH-1:0]	PWDATA_i,
				input [`SPI_APB_DATA_WIDTH-1:0]	miso_data_i,
				output	mstr_o,
						cpol_o,
						cpha_o,
						lsbfe_o,
						spiswai_o,
						spi_interrupt_request_o,
				output reg	send_data_o,
				output	PREADY_o,
						PSLVERR_o,
				output reg	[`SPI_APB_DATA_WIDTH-1:0] mosi_data_o,
				output reg	[1:0] spi_mode_o,
				output reg	[`SPI_APB_DATA_WIDTH-1:0] PRDATA_o,
				output		[2:0] sppr_o,
							spr_o);
	

	reg [1:0] STATE, next_state; // apb mode state
	reg [1:0] next_mode; // spi mode state
	reg [7:0] SPI_CR_1, SPI_CR_2, SPI_BR, SPI_SR, SPI_DR; // Control/ Status/ Baud/ Data register
	reg spif, sptef; // interrupt and status flags
	wire modf, modfen, spe, spie, sptie, ssoe;
	wire wr_enb, rd_enb; // Write and Read enable signals

	localparam	IDLE = 2'b00,
				SETUP = 2'b01,
				ENABLE = 2'b10;

	localparam	spi_run = 2'b00,
				spi_wait = 2'b01,
				spi_stop = 2'b10;

	//APB state FSM
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n)
			STATE <= IDLE;
		else
			STATE <= next_state;
	end

	always @(*) begin
		case(STATE)
			
			IDLE: begin
				if(PSEL_i && !PENABLE_i) 
					next_state = SETUP;
				else
					next_state = IDLE;
			end
			SETUP: begin
				if(PSEL_i && PENABLE_i)
					next_state = ENABLE;
				else if(PSEL_i && !PENABLE_i)
					next_state = SETUP; 
				else
					next_state = IDLE;
			end
			ENABLE: begin
				if(PSEL_i)
					next_state = SETUP;
				else
					next_state = IDLE;
			end
			default: next_state = IDLE;
		endcase
	end

	//SPI mode FSM
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n)
			spi_mode_o <= spi_run;
		else
			spi_mode_o <= next_mode;
	end

	always @(*) begin
		case(spi_mode_o)
			spi_run: begin
				if(!spe)
					next_mode = spi_wait;
				else
					next_mode = spi_run;
			end
			spi_wait: begin
				if(spe)
					next_mode = spi_run;
				else if(spiswai_o)
					next_mode = spi_stop;
				else
					next_mode = spi_wait;
			end
			spi_stop: begin
				if(!spiswai_o)
					next_mode = spi_wait;
				else if(spe)
					next_mode = spi_run;
				else
					next_mode = spi_stop;
			end
			default: next_mode = spi_run;
		endcase
	end

	assign PREADY_o = (STATE == ENABLE) ? 1'b1 : 1'b0;
	
	assign PSLVERR_o = (STATE == ENABLE) ? ~tip_i : 1'b0;
	
	assign wr_enb = PWRITE_i && (STATE == ENABLE);
	
	assign rd_enb = !PWRITE_i && (STATE == ENABLE);
	
	//To write the data into the Control register 1, 2 and Baud rate register from PWDATA 
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			SPI_CR_1 	<= 8'b0000_0100;
			SPI_CR_2 	<= 8'b0000_0000;
			SPI_BR 		<= 8'b0000_0000;
		end
		else if(wr_enb) begin
			case(PADDR_i)
				3'b000:
					SPI_CR_1 <= PWDATA_i;
				3'b001:
					SPI_CR_2 <= (PWDATA_i & 8'b0001_1011); //Control register 2 mask value
				3'b010:
					SPI_BR <= (PWDATA_i & 8'b0111_0111); // Baud rate register mask value
				default:;
			endcase
		end
	end
	
	//To read data from the SPI registers
	always @(*) begin
		if(rd_enb) begin
			case(PADDR_i)
				3'b000:
					PRDATA_o = SPI_CR_1;
				3'b001:
					PRDATA_o = SPI_CR_2;
				3'b010:
					PRDATA_o = SPI_BR;
				3'b011:
					PRDATA_o = SPI_SR;
				3'b101:
					PRDATA_o = SPI_DR;
				default: PRDATA_o = 8'b0;
			endcase
		end
		else begin
			PRDATA_o = 8'b0;
		end
	end
	
	//SPI Control register 1 fields
	assign mstr_o	= SPI_CR_1[4];
	assign cpol_o	= SPI_CR_1[3];
	assign cpha_o	= SPI_CR_1[2];
	assign ssoe		= SPI_CR_1[1];
	assign lsbfe_o	= SPI_CR_1[0];
	assign spie		= SPI_CR_1[7];
	assign spe		= SPI_CR_1[6];
	assign sptie	= SPI_CR_1[5];
	
	//SPI Control register 2 fields
	assign spiswai_o	=SPI_CR_2[1];
	assign modfen		=SPI_CR_2[4];
	
	//SPI Baud rate register fields
	assign sppr_o	= SPI_BR[7:5];
	assign spr_o	= SPI_BR[2:0];
	
	//Detect Mode Fault
	assign modf		= !ss_i && mstr_o && modfen && !ssoe ? 1'b1 : 1'b0;
	
	assign spi_interrupt_request_o 	=	(!spie && !sptie) ? 1'b0 : 
										(spie && !sptie) ? (spif || modf):
										(!spie && sptie) ? sptef : (spif || modf || sptef);
	
	//SPI Status register
	always @(*) begin
		if(!PRESET_n) begin
			SPI_SR = 8'b0010_0000;
			sptef = 1'b0;
			spif = 1'b0;
		end
		else begin
			sptef = (SPI_DR == 8'd0);
			spif = (SPI_DR != 8'd0) ? 1'b1 : 1'b0;
			SPI_SR  = {spif, 1'b0, sptef, modf, 4'b0};
		end
	end
	
	//Logic to assert data into send_data
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			send_data_o <= 1'b0;
		end
		else begin
			if(wr_enb) begin
				send_data_o <= send_data_o;
			end
			else begin
				if((SPI_DR == PWDATA_i) && (SPI_DR != miso_data_i) && ((spi_mode_o == spi_run) || (spi_mode_o == spi_wait)))
					send_data_o <= 1'b1;
				else begin
					if((spi_mode_o == spi_run || spi_mode_o == spi_wait) && receive_data_i)
						send_data_o <= 1'b0;
					else
						send_data_o <= 1'b0;
				end
			end
		end
	end

	//Logic To write into the mosi_data from SPI Data register
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n)
			mosi_data_o <= 8'b0;
		else if(!wr_enb) begin
			if((SPI_DR == PWDATA_i) && (SPI_DR != miso_data_i) && ((spi_mode_o == spi_run) || (spi_mode_o == spi_wait)))
				mosi_data_o <= SPI_DR;
			else
				mosi_data_o <= mosi_data_o;
		end			
	end
	
	//Logic to write data from PWDATA into the SPI data register
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n)
			SPI_DR <= 8'b0;
		else begin
			if(wr_enb) begin
				SPI_DR <= (PADDR_i == 3'b101) ? PWDATA_i : SPI_DR;
			end
			else begin
				if((SPI_DR == PWDATA_i) && (SPI_DR != miso_data_i) && ((spi_mode_o == spi_run) || (spi_mode_o == spi_wait)))
					SPI_DR <= 8'b0;
				else begin
					if((spi_mode_o == spi_run || spi_mode_o == spi_wait) && receive_data_i)
						SPI_DR <= miso_data_i;
					else
						SPI_DR <= SPI_DR;
				end
			end
		end
	end
	
endmodule
