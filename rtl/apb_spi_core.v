`define SPI_APB_ADDR_WIDTH 3
`define SPI_APB_DATA_WIDTH 8
module apb_spi_core(input		PCLK,
								PRESET_n,
								PWRITE_i,
								PSEL_i,
								PENABLE_i,
					input [2:0]	PADDR_i,
					input [`SPI_APB_DATA_WIDTH-1:0]	PWDATA_i,
					output [`SPI_APB_DATA_WIDTH-1:0]PRDATA_o,
					output		PREADY_o,
								PSLVERR_o,
					input		miso_i,
					output		ss_o,
								sclk_o,
								spi_interrupt_request_o,
								mosi_o);

	wire [1:0]	spi_mode;
	wire		spiswai;
	wire [2:0]	sppr;
	wire [2:0]	spr;
	wire		cpol;
	wire		cpha;
	wire		ss;
	wire		sclk;
	wire [11:0]	baudratedivisor;
	wire		miso_receive_sclk0;
	wire		miso_receive_sclk;
	wire		miso_send_sclk0;
	wire		miso_send_sclk;
	wire		mstr;
	wire		send_data;
	wire		receive_data;
	wire		tip;
	wire [`SPI_APB_DATA_WIDTH-1:0]	data_miso;
	wire [`SPI_APB_DATA_WIDTH-1:0]	data_mosi;
	wire		lsbfe;
	wire		spi_interrupt_request;
	wire		mosi;
	//wire		miso;
	
	assign ss_o = ss;
	assign sclk_o = sclk;
	assign spi_interrupt_request_o = spi_interrupt_request;
	assign mosi_o = mosi;
	
	spi_baud_generator DUT1(.PCLK(PCLK),
							.PRESET_n(PRESET_n),
							.spi_mode_i(spi_mode),
							.spiswai_i(spiswai),
							.sppr_i(sppr),
							.spr_i(spr),
							.cpol_i(cpol),
							.cpha_i(cpha),
							.ss_i(ss),
							.sclk_o(sclk),
							.BaudRateDivisor_o(baudratedivisor),
							.miso_receive_sclk_o(miso_receive_sclk),
							.miso_receive_sclk0_o(miso_receive_sclk0),
							.mosi_send_sclk_o(miso_send_sclk),
							.mosi_send_sclk0_o(miso_send_sclk0));
							
	spi_shift_reg	DUT2(	.PCLK(PCLK),
							.PRESET_n(PRESET_n),
							.ss_i(ss),
							.send_data_i(send_data),
							.receive_data_i(receive_data),
							.lsbfe_i(lsbfe),
							.cpha_i(cpha),
							.cpol_i(cpol),
							.miso_i(miso_i),
							.miso_receive_sclk_i(miso_receive_sclk),
							.miso_receive_sclk0_i(miso_receive_sclk0),
							.mosi_send_sclk_i(miso_send_sclk),
							.mosi_send_sclk0_i(miso_send_sclk0),
							.data_mosi_i(data_mosi),
							.data_miso_o(data_miso),
							.mosi_o(mosi));
							
	apb_slave_interface DUT3(	.PCLK(PCLK),
								.PRESET_n(PRESET_n),
								.PWRITE_i(PWRITE_i),
								.PSEL_i(PSEL_i),
								.PENABLE_i(PENABLE_i),
								.ss_i(ss),
								.receive_data_i(receive_data),
								.tip_i(tip),
								.PADDR_i(PADDR_i),
								.PWDATA_i(PWDATA_i),
								.miso_data_i(data_miso),
								.mstr_o(mstr),
								.cpol_o(cpol),
								.cpha_o(cpha),
								.lsbfe_o(lsbfe),
								.spiswai_o(spiswai),
								.spi_interrupt_request_o(spi_interrupt_request),
								.send_data_o(send_data),
								.PREADY_o(PREADY_o),
								.PSLVERR_o(PSLVERR_o),
								.mosi_data_o(data_mosi),
								.spi_mode_o(spi_mode),
								.PRDATA_o(PRDATA_o),
								.sppr_o(sppr),
								.spr_o(spr));

	spi_slave_selector DUT4(.PCLK(PCLK),
							.PRESET_n(PRESET_n),
							.mstr_i(mstr),
							.send_data_i(send_data),
							.spiswai_i(spiswai),
							.spi_mode_i(spi_mode),
							.ss_o(ss),
							.baudratedivisor_i(baudratedivisor),
							.tip_o(tip),
							.receive_data_o(receive_data));
							
endmodule