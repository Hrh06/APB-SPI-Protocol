module spi_shift_reg_tb;

	reg  	PCLK,
		PRESET_n,
		ss_i,
		send_data_i,
		receive_data_i,
		lsbfe_i,
		cpha_i,
		cpol_i,
		miso_i;
	reg [7:0]	data_mosi_i;
	wire [7:0]	data_miso_o;
	wire		mosi_o;
	
	reg [1:0] spi_mode_i;
	reg [2:0] sppr_i = 0;
	reg [2:0] spr_i = 0;
	reg spiswai_i;
	reg sclk_o;
	wire [11:0] BaudRateDivisor_o;
	wire pre_sclk_s;
	reg [11:0] count_s;
	reg	miso_receive_sclk_o;
	reg	miso_receive_sclk0_o;
	reg mosi_send_sclk_o;
	reg mosi_send_sclk0_o;
	
	integer i;
	
	parameter RUN = 2'b00,
		  WAIT = 2'b01,
		  STOP = 2'b10;
		  
	spi_shift_reg DUT(	PCLK,
						PRESET_n,
						ss_i,
						send_data_i,
						receive_data_i,
						lsbfe_i,
						cpha_i,
						cpol_i,
						miso_i,
						miso_receive_sclk_o,
						miso_receive_sclk0_o,
						mosi_send_sclk_o,
						mosi_send_sclk0_o,
						data_mosi_i,
						data_miso_o,
						mosi_o);
		  
	initial begin
		PCLK = 1'b0;
		forever #5 PCLK = ~PCLK;
	end

	assign BaudRateDivisor_o = ((sppr_i+1) * (2**(spr_i+1)));
	//assign BaudRateDivisor_o = 4;
	assign pre_sclk_s = cpol_i ? 1'b1 : 1'b0;
	
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			count_s <= 12'b0;
			sclk_o <= pre_sclk_s;
		end
		else if(!ss_i && (!spiswai_i && (spi_mode_i == RUN || spi_mode_i == WAIT))) begin
			if(count_s == (BaudRateDivisor_o-1'b1)) begin
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
	
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			miso_receive_sclk_o <= 1'b0;
			miso_receive_sclk0_o <= 1'b0;
		end
		else begin
			if((!cpha_i&&cpol_i)||(cpha_i&&!cpol_i)) begin
				if(sclk_o == 1'b1) begin
					if(count_s == ((BaudRateDivisor_o/2)-2'b01))
						miso_receive_sclk0_o <= 1'b1; // this should be asserted for only a single clock cycle
					else
						miso_receive_sclk0_o <= 1'b0;
				end else
					miso_receive_sclk0_o <= 1'b0;
			end
			if((!cpha_i&&!cpol_i)||(cpha_i&&cpol_i)) begin
				if(sclk_o == 1'b0) begin
					if(count_s == ((BaudRateDivisor_o/2)-2'b01))
						miso_receive_sclk_o <= 1'b1; //This should be asserted for only a single clock cycle
					else
						miso_receive_sclk_o <= 1'b0;
				end else
					miso_receive_sclk_o <= 1'b0;
			end
		end
	end
	
	always @(posedge PCLK or negedge PRESET_n) begin
		if(!PRESET_n) begin
			mosi_send_sclk_o <= 1'b0;
			mosi_send_sclk0_o <= 1'b0;
		end
		else begin
			if((!cpha_i&&cpol_i)||(cpha_i&&!cpol_i)) begin
				if(sclk_o == 1'b1) begin
					if(count_s == ((BaudRateDivisor_o/2)-2'b10))
						mosi_send_sclk0_o <= 1'b1; // this should be asserted for only a single clock cycle
					else
						mosi_send_sclk0_o <= 1'b0;
				end else
					mosi_send_sclk0_o <= 1'b0;
			end
			if((!cpha_i&&!cpol_i)||(cpha_i&&cpol_i)) begin
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

	task initialize;
		begin
			ss_i = 1'b1;
			send_data_i = 1'b0;
			receive_data_i = 1'b0;
			lsbfe_i = 1'b1;
			cpha_i = 1'b1;
			cpol_i = 1'b1;
			miso_i = 1'b0;
			data_mosi_i = 8'b0;
			PRESET_n = 1'b1;
		end
	endtask
	
	task sample_posedge;
		begin
			PRESET_n = 1'b1;
			@(posedge PCLK);
			send_data_i = 1'b1;
			data_mosi_i = 8'b1100_0011;
			@(posedge PCLK)
			@(posedge PCLK)
			ss_i = 1'b0;
			send_data_i = 1'b0;
			lsbfe_i = 1'b1;
			cpha_i = 1'b0;
			cpol_i = 1'b1;
			repeat(8)
				@(posedge sclk_o);
			@(posedge PCLK)
			receive_data_i = 1'b1;
			ss_i = 1'b1;
			@(posedge PCLK)
			@(posedge PCLK)
			receive_data_i = 1'b0;
		end
	endtask
	
	task sample_negedge;
		begin
			PRESET_n = 1'b1;
			@(posedge PCLK);
			send_data_i = 1'b1;
			data_mosi_i = 8'b0011_0011;
			@(posedge PCLK)
			@(posedge PCLK)
			ss_i = 1'b0;
			send_data_i = 1'b0;
			lsbfe_i = 1'b0;
			cpha_i = 1'b0;
			cpol_i = 1'b1;
			@(posedge PCLK)
			send_data_i = 1'b0;
			repeat(8)
				@(negedge sclk_o);
			@(posedge PCLK)
			receive_data_i = 1'b1;
			ss_i = 1'b1;
			@(posedge PCLK)
			@(posedge PCLK)
			receive_data_i = 1'b0;
		end
	endtask

	task send_miso_not_cphase;
		begin
			for(i=0; i<=7; i=i+1) begin
				@(negedge sclk_o)
				begin
					miso_i = 1'b1;
				end
			end
		end
	endtask
	
	task baud_gen(input [2:0] i, j, input m, n);
		begin
			spi_mode_i = 2'b00;
			sppr_i = i;
			spr_i = j;
			cpol_i = m;
			cpha_i = n;
			ss_i = 1'b0;
			spiswai_i = 1'b0;
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

	initial begin
		initialize;
		#10;
		reset;
		#10;
		fork begin
			baud_gen(3'd0,3'd2,1'b0,1'b1);
			sample_posedge;
		end
		send_miso_not_cphase;
		join
		fork begin
			baud_gen(3'd0,3'd2,1'b0,1'b1);
			sample_negedge;
			end
			send_miso_not_cphase;
		join
		#200 $finish;
	end
	
	initial
		$monitor("Time: %0t, sclk: %b, ss: %b, mosi: %b, miso: %b, data_mosi: %b, data_miso: %b, lsbfe: %b",$time,sclk_o,ss_i,mosi_o,miso_i,data_mosi_i,data_miso_o,lsbfe_i);
endmodule
