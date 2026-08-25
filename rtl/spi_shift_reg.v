`define SPI_APB_ADDR_WIDTH 3
`define SPI_APB_DATA_WIDTH 8
module spi_shift_reg(	input	PCLK,
				PRESET_n,
				ss_i,
				send_data_i,
				receive_data_i,
				lsbfe_i,
				cpha_i,
				cpol_i,
				miso_i,
				miso_receive_sclk_i,
				miso_receive_sclk0_i,
				mosi_send_sclk_i,
				mosi_send_sclk0_i,
			input [`SPI_APB_DATA_WIDTH-1:0]	data_mosi_i,
			output [`SPI_APB_DATA_WIDTH-1:0] data_miso_o,
			output reg	mosi_o);
	
	reg [`SPI_APB_DATA_WIDTH-1:0] shift_reg;
	reg [`SPI_APB_DATA_WIDTH-1:0] temp_reg;
	reg [2:0] count,
		  count1,
		  count2,
		  count3;

	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			shift_reg <= 8'b0;
		end
		else if(send_data_i)
			shift_reg <= data_mosi_i;
	end

	assign data_miso_o = receive_data_i ? temp_reg : 8'b0;

	//logic for sending data from master
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			mosi_o <= 1'b0;
			count <= 3'b0;
			count1 <= 3'd7;
		end
		else begin
			if(!ss_i) begin
				if((!cpha_i&&cpol_i) || (cpha_i&&!cpol_i)) begin
					if(lsbfe_i) begin
						if(count <= 3'd7) begin
							if(mosi_send_sclk0_i) begin
								count <= count+1'b1;
								mosi_o <= shift_reg[count];
							end
						end
						else
							count <= 3'b0;
					end
					else begin
						if(count1 >= 3'd0) begin
							if(mosi_send_sclk0_i) begin
								count1 <= count1-1'b1;
                          		mosi_o <= shift_reg[count1];
							end
						end
						else
							count1 <= 3'd7;
					end
				end
				else begin	
					if(lsbfe_i) begin
						if(count <= 3'd7) begin
							if(mosi_send_sclk_i) begin
								count <= count+1'b1;
								mosi_o <= shift_reg[count];
							end
						end
						else
							count <= 3'b0;
					end
					else begin
						if(count1 >= 3'd0) begin
							if(mosi_send_sclk_i) begin
								count1 <= count1-1'b1;
                          		mosi_o <= shift_reg[count1];
							end
						end
						else
							count1 <= 3'd7;
					end
				end
			end
		end
	end

	//logic for storing receiving data
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			count2 <= 3'd0;
			count3 <= 3'b111;
			temp_reg <= 8'b0;
		end
		else begin
			if(!ss_i) begin
				if((!cpha_i&&cpol_i) || (cpha_i&&!cpol_i)) begin
					if(lsbfe_i) begin
						if(count2 <= 3'd7) begin
							if(miso_receive_sclk0_i) begin
								count2 <= count2+1'b1;
								temp_reg[count2] <= miso_i;
							end
						end
						else
							count2 <= 3'b0;
					end
					else begin
						if(count3 >= 3'b000) begin
							if(miso_receive_sclk0_i) begin
								count3 <= count3-1'b1;
                          		temp_reg[count3] <= miso_i;
							end
						end
						else
							count3 <= 3'b111;
					end
				end
				else begin	
					if(lsbfe_i) begin
						if(count2 <= 3'd7) begin
							if(miso_receive_sclk_i) begin
								count2 <= count2+1'b1;
								temp_reg[count2] <= miso_i;
							end
						end
						else
							count2 <= 3'b0;
					end
					else begin
						if(count3 >= 3'd0) begin
							if(miso_receive_sclk_i) begin
								count3 <= count3-1'b1;
                          		temp_reg[count3] <= miso_i;
							end
						end
						else
							count3 <= 3'd7;
					end
				end
			end
		end
	end

endmodule
