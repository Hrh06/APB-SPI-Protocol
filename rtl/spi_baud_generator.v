module spi_baud_generator(	input		PCLK,
						PRESET_n,
				input	[1:0] 	spi_mode_i,
				input		spiswai_i,
				input	[2:0]	sppr_i,
				input	[2:0]	spr_i,
				input		cpol_i,
						cpha_i,
						ss_i,
				output reg	sclk_o,
				output [11:0]	BaudRateDivisor_o,
				output reg	miso_receive_sclk_o,
						miso_receive_sclk0_o,
						mosi_send_sclk_o,
						mosi_send_sclk0_o);

	parameter RUN = 2'b00,
		  WAIT = 2'b01,
		  STOP = 2'b10;

	wire pre_sclk_s;
	reg [11:0] count_s;

	assign BaudRateDivisor_o = ((sppr_i+1) * (2**(spr_i+1)));
	assign pre_sclk_s = cpol_i ? 1'b1 : 1'b0;
	
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			count_s <= 12'b0;
			sclk_o <= pre_sclk_s;
		end
		else if(!ss_i && (!spiswai_i && (spi_mode_i == RUN || spi_mode_i == WAIT))) begin
			if(count_s == ((BaudRateDivisor_o/2)-1'b1)) begin
				sclk_o <= ~sclk_o;
				count_s <= 12'b0;
			end else
				count_s <= count_s + 1'b1;
		end
		else begin
			sclk_o <= pre_sclk_s;
			count_s <= 12'b0;
		end
	end

	//sclk for receiving data through miso input
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			miso_receive_sclk_o <= 1'b0;
			miso_receive_sclk0_o <= 1'b0;
		end
		else begin
			if((!cpha_i&&cpol_i)||(cpha_i&&!cpol_i)) begin	//receive_sclk0 is assert on falling edge of sclk(cpol != cpha)
				if(sclk_o == 1'b1) begin
					if(count_s == ((BaudRateDivisor_o/2)-2'b01))
						miso_receive_sclk0_o <= 1'b1; //asserted for only a single clock cycle
					else
						miso_receive_sclk0_o <= 1'b0;
				end else
					miso_receive_sclk0_o <= 1'b0;
			end
			if((!cpha_i&&!cpol_i)||(cpha_i&&cpol_i)) begin	//receive_sclk is assert on rising edge of sclk(cpol = cpha)
				if(sclk_o == 1'b0) begin
					if(count_s == ((BaudRateDivisor_o/2)-2'b01))
						miso_receive_sclk_o <= 1'b1; //asserted for only a single clock cycle
					else
						miso_receive_sclk_o <= 1'b0;
				end else
					miso_receive_sclk_o <= 1'b0;
			end
		end
	end
	
	//sclk for send data through mosi output
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			mosi_send_sclk_o <= 1'b0;
			mosi_send_sclk0_o <= 1'b0;
		end
		else begin
			if((!cpha_i&&cpol_i)||(cpha_i&&!cpol_i)) begin	//send_sclk0 is assert a clock before the falling edge of sclk(cpol != cpha)
				if(sclk_o == 1'b1) begin
					if(count_s == ((BaudRateDivisor_o/2)-2'b10))
						mosi_send_sclk0_o <= 1'b1; // this should be asserted for only a single clock cycle
					else
						mosi_send_sclk0_o <= 1'b0;
				end else
					mosi_send_sclk0_o <= 1'b0;
			end
			if((!cpha_i&&!cpol_i)||(cpha_i&&cpol_i)) begin	//send_sclk is assert a clock before the rising edge of sclk (cpol = cpha)
				if(sclk_o == 1'b0) begin
					if(count_s == ((BaudRateDivisor_o/2)-2'b10))
						mosi_send_sclk_o <= 1'b1; //This should be asserted for only a single clock cycle
					else
						mosi_send_sclk_o <= 1'b0;
				end else
					mosi_send_sclk_o <= 1'b0;
			end
		end
	end
endmodule
