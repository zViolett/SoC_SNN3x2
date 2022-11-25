`timescale 1ns/1ps
module top ();
	parameter NUM_OUTPUT = 250; // Số spike bắn ra
	// parameter NUM_PICTURE = 4; // Số ảnh test
	// parameter NUM_PACKET = 549; // số lượng input packet trong file
	parameter NUM_PICTURE = 100; // Số ảnh test
	parameter NUM_PACKET = 13910; // số lượng input packet trong file
	
	reg clk, sys_clk, reset_n, sys_rst, csr_rst, sys_reset_n;

	reg			packet_winc 		;
	reg	[29:0]		packet_wdata		;
	reg			spike_en    		;
	reg			load_end    		;
	
	wire			tick			;
  	wire                	complete            	;
        wire    [249:0]     	spike_out	        ;
	wire	[2:0]		grid_state		;
	
	SNN_3x2 SNN_3x2_dut(
		.clk              	(clk				),
		.reset_n          	(reset_n			),
		.sys_clk          	(sys_clk			),
		.sys_reset_n      	(sys_reset_n			),
		.packet_winc        	(packet_winc        		),
        	.packet_wdata       	(packet_wdata      		),
        	.spike_en           	(spike_en           		),
        	.load_end           	(load_end           		),
		.tick_ready		(tick				),
		.complete         	(complete			),
		.spike_out		(spike_out			),
		.grid_state		(grid_state			)
	);


	// đọc số lượng packet trong mỗi tick
	reg [11:0] num_pic [0:NUM_PICTURE - 1];
	initial $readmemh("/coasiasemi/projectx/internship/20220404/dat.nguyen/ranc3x2/sim/tb_unit/tb_num_inputs.txt", num_pic);
	
	// đọc tất cả các packet
	reg [29:0] packet [0:NUM_PACKET - 1];
	initial $readmemb("/coasiasemi/projectx/internship/20220404/dat.nguyen/ranc3x2/sim/tb_unit/tb_input.txt", packet);

	reg [NUM_OUTPUT - 1:0] output_soft [0:NUM_PICTURE - 1];
	initial $readmemb("/coasiasemi/projectx/internship/20220404/dat.nguyen/ranc3x2/sim/tb_unit/simulator_output.txt", output_soft);
	reg [NUM_OUTPUT - 1:0] output_file [0:NUM_PICTURE - 1];

	int begin_packet_addr;
	int i,j,m,n;
	int num_line;
	reg wrong;
	initial wrong = 0;

	initial begin
	    clk = 0;
	    forever #5 clk = ~clk;
	end

	initial begin
	    sys_clk = 0;
	    forever #3 sys_clk = ~sys_clk;
	end

	initial begin
	    sys_rst = 1;
	    csr_rst = 0; @(negedge clk); sys_rst = 0;
	    #50 csr_rst = 1;
	end

	always @(sys_rst, csr_rst) begin
	    reset_n = sys_rst | csr_rst;
		sys_reset_n = reset_n;
	end

	initial begin
		#8000000 $finish();
		wait(complete == 1) $display ("Complete SNN");
		$finish();
	end

	always @(tick) begin
		if(tick && spike_en) begin
			output_file[num_line] = spike_out;
			@(negedge clk);
			num_line = num_line + 1;
		end
	end

	
	initial begin
		begin_packet_addr = 0;
		packet_winc = 0;
		spike_en = 0;
		load_end = 0;
		num_line	= 0;
		#100;
		for (i = 0; i < NUM_PICTURE; i++) begin
			if (i > 2) begin
				spike_en = 1;
			end
	    		@(posedge clk);
	    		for (j = 0; j < num_pic[i]; j++) begin
	    			@(negedge sys_clk);
	        		packet_wdata = packet[begin_packet_addr + j];
	        		packet_winc = 1;
	        		@(negedge sys_clk);
	        		packet_winc = 0;
	    		end
	    		begin_packet_addr = begin_packet_addr + num_pic[i];
			wait(grid_state == 7);
		end
		load_end = 1;
		wait(complete == 1) $display ("Complete SNN");
		$writememb("/coasiasemi/projectx/internship/20220404/dat.nguyen/ranc3x2/sim/tb_unit/output.txt", output_file);
		for(m = 0; m < NUM_PICTURE; m = m + 1) begin
            		for(n = 0; n < NUM_OUTPUT; n = n + 1) begin
                		if(output_file[m][n] != output_soft[m][n]) begin
                   			$display("Error at neuron %d, picture %d", n, m);
					wrong = 1;
                		end
           		end
       		end
		#1; if(~wrong) $display("Test pass without error");
		$finish();
	end
endmodule
