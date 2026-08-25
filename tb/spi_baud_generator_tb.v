module spi_baud_generator_tb();

	reg 	  PCLK,
		  PRESET_n;
	reg [2:0] sppr_i;
	reg [2:0] spr_i;
	reg	  spiswai_i,
		  cpol_i,
		  cpha_i,
		  ss_i;
	reg [1:0] spi_mode_i;
	wire	  sclk_o,
		  miso_receive_sclk_o,
		  miso_receive_sclk0_o,
		  miso_send_sclk_o,
		  miso_send_sclk0_o;
	wire [11:0] BaudRateDivisor_o;

	spi_baud_generator DUT(	PCLK,
                           	PRESET_n,
				spi_mode_i,
				spiswai_i,
				sppr_i,
				spr_i,
				cpol_i,
				cpha_i,
				ss_i,
				sclk_o,
				BaudRateDivisor_o,
				miso_receive_sclk_o,
				miso_receive_sclk0_o,
				mosi_send_sclk_o,
				mosi_send_sclk0_o);

	initial begin
		PCLK = 1'b0;
		forever #5 PCLK = ~PCLK;
	end

	task initialize;
		begin
			spi_mode_i = 2'b0;
			sppr_i = 3'b0;
			spr_i = 3'b0;
			spiswai_i = 1'b0;
			cpol_i = 1'b0;
			cpha_i = 1'b1;
			ss_i = 1'b1;
			PRESET_n = 1'b0;
		end
	endtask

	task reset;
		begin
			#1;
			PRESET_n = 1'b0;
			#43;
			PRESET_n = 1'b1;
		end
	endtask

	task baud_gen(input [2:0] i, j, input m, n);
		begin
			spi_mode_i = 2'b01;
			sppr_i = i;
			spr_i = j;
			cpol_i = m;
			cpha_i = n;
			ss_i = 1'b0;
			spiswai_i = 1'b0;
		end
	endtask

	initial begin
		initialize;
		#10;
		reset;
		#10;
		baud_gen(3'd1,3'd1,1'b0,2'b0);
		#200;
		baud_gen(3'd1,3'd1,1'b1,2'b0);
		#200;
		baud_gen(3'd1,3'd1,1'b1,2'b1);
		#200;
		baud_gen(3'd1,3'd1,1'b0,2'b1);
		#600;
		spiswai_i = 1'b1;

		#4000
		$finish;
	end
endmodule
