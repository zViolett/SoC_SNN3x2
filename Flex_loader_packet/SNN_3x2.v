module SNN_3x2 #(
    parameter WIDTH = 30
) (
    input                   clk                 ,   //snn clock
    input                   reset_n             ,   //snn resetn
    input                   sys_clk             ,   //cpu clock
    input                   sys_reset_n         ,   //cpu resetn

    input                   packet_winc         ,   //packet in write enable
    input       [29:0]      packet_wdata        ,   //packet in from cpu
    input                   spike_en            ,   //spike out enable
    input                   load_end            ,   //done loading packet
    output                  tick_ready          ,   //tick for system
    output                  complete            ,   //all process complete
    output      [249:0]     spike_out		,
    output      [2:0]       grid_state
    
);

    wire                ren_to_input_buffer                 ;
    wire                tick                                ;
    wire                packet_out_valid                    ;
    wire    [7:0]       packet_out                          ;
    wire    [2:0]       grid_state                          ;
    wire                input_buffer_empty                  ;
    wire    [2:0]       state                               ;
    wire    [29:0] 	packet_in			    ;
    wire                forward_north_local_buffer_empty_all;
    wire                complete_for_tick_gen               ;
    wire    [2:0]       grid_state_in                       ;

    assign  complete_for_tick_gen = complete;
    assign  tick = tick_ready;
    assign  grid_state_in = grid_state;

    load_packet packet_loader(
		.clk                   	(clk                    ),
		.reset_n               	(reset_n                ),
		.sys_clk               	(sys_clk                ),
		.sys_reset_n           	(reset_n                ),
		.ren_to_input_buffer	(ren_to_input_buffer	),
		.tick              	(tick_ready		),
		.packet_out_valid  	(packet_out_valid	),
		.packet_out        	(packet_out		),
		.grid_state        	(grid_state_in  	),
		.packet_winc            (packet_winc            ),
        	.packet_wdata           (packet_wdata           ),
        	.spike_en               (spike_en               ),
        	.load_end               (load_end               ),
		.input_buffer_empty	(input_buffer_empty	),
		.complete          	(complete		),
		.state             	(state			),
		.spike_out         	(spike_out		),
		.packet_in		(packet_in		)
	);

    RANCNetworkGrid_3x2 RANCNetworkGrid_3x2_ins(
        .clk                   	                (clk                                    ),
	.reset_n               	                (reset_n                                ),
        .tick                                   (tick_ready                             ),
        .input_buffer_empty                     (input_buffer_empty                     ),
        .packet_in                              (packet_in                              ),
        .packet_out                             (packet_out                             ),
        .packet_out_valid                       (packet_out_valid                       ),
        .ren_to_input_buffer                    (ren_to_input_buffer                    ),
        .grid_state                             (grid_state                             ),
        .forward_north_local_buffer_empty_all   (forward_north_local_buffer_empty_all   )
	);

    tick_gen tick_generation(
        .clk                   	                (clk                                    ),
	.rst_n               	                (reset_n                                ),
        .state                                  (state                                  ),
        .grid_state                             (grid_state_in                          ),
        .input_buffer_empty                     (input_buffer_empty                     ),
        .forward_north_local_buffer_empty_all   (forward_north_local_buffer_empty_all   ),
        .complete                               (complete_for_tick_gen                  ),
        .tick                                   (tick_ready                             )
    );

endmodule
