module spi_slave_selector(input	PCLK,
				PRESET_n,
				mstr_i,
				send_data_i,
				spiswai_i,
			input [1:0] 	spi_mode_i,
			output reg 	ss_o,
			input [11:0]	baudratedivisor_i,
			output		tip_o,
			output reg	receive_data_o);

	parameter RUN = 2'b00,
		  WAIT = 2'b01,
		  STOP = 2'b10;

	reg [15:0] count_s;
	wire [15:0] target_s;
	reg rcv_s;

	assign target_s = 4'd8*baudratedivisor_i;
	assign tip_o = ~ss_o;

	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			count_s <= 16'hffff;
			ss_o <= 1'b1;
			rcv_s <= 1'b0;
		end
		else if(mstr_i && (spi_mode_i == RUN || (spi_mode_i == WAIT && !spiswai_i)))begin
			if(send_data_i) begin
				ss_o <= 1'b0;
				count_s <= 16'h0000;
			end
			else if(count_s <= (target_s-1'b1)) begin
				ss_o <= 1'b0;
				count_s <= count_s + 1'b1;
				if(count_s == (target_s - 1'b1))
					rcv_s <= 1'b1;
			end
			else begin
				ss_o <= 1'b1;
				rcv_s <= 1'b0;
				count_s <= 16'hffff;
			end
		end
		else begin
			ss_o <= 1'b1;
			rcv_s <= 1'b0;
			count_s <= 16'hffff;
		end
	end

	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			receive_data_o <= 1'b0;
		end
		else begin
			receive_data_o <= rcv_s;
		end
	end

endmodule
