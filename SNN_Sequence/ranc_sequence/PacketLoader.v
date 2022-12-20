module load_packet #(
    parameter WIDTH = 30
)
(
    input                   clk                 ,   //snn clock
    input                   reset_n             ,   //snn resetn
    input                   sys_clk             ,   //cpu clock
    input                   sys_reset_n         ,   //cpu resetn
    input                   ren_to_input_buffer ,
    input                   tick                ,
    input                   packet_out_valid    ,
    input       [7:0]       packet_out          ,
    input       [2:0]       grid_state          ,

    input                   packet_winc         ,   //packet in write enable to fifo
    input       [29:0]      packet_wdata        ,   //packet in from cpu
    input                   spike_en            ,   //spike out enable (Status signal for FSM)
    input                   load_end            ,   //done loading packet (Status signal for FSM)
    
    output                  packet_wfull        ,
    output                  input_buffer_empty  ,
    output                  complete            ,   //all process complete
    output      [2:0]       state               ,   //state of loading packet process
    output      [249:0]     spike_out           ,
    output      [WIDTH-1:0] packet_in
);

////////////////////////////////////////
/*           FSM States               */
////////////////////////////////////////
    localparam  [2:0]   IDLE        = 3'b000;
    localparam  [2:0]   LOAD	    = 3'b001;
    localparam  [2:0]   COMPUTE     = 3'b010;
    localparam  [2:0]   WAIT_END    = 3'b100;
    
    reg [2:0]           state_reg, state_next               ;
    reg                 complete_reg, complete_next         ;
    reg [249:0]         compute_out_reg, compute_out_next   ;
    reg [249:0]         spike_reg, spike_next               ;
    reg [2:0]           cnt_end_reg, cnt_end_next           ;

    // wire                packet_wfull                        ;
   

////////////////////////////////////////
/*    Packket load handle             */
////////////////////////////////////////

async_fifo #(
		.DSIZE      (30     ), 
		.ASIZE      (8      ),
		.FALLTHROUGH("FALSE")
	) load_packet_fifo(
		.wclk    (sys_clk            ),
		.wrst_n  (sys_reset_n        ),
		.winc    (packet_winc        ),
		.wdata   (packet_wdata       ),
		.wfull   (packet_wfull       ),
		.rclk    (clk                ),
		.rrst_n  (reset_n            ),
		.rinc    (ren_to_input_buffer),
		.rdata   (packet_in          ),
		.rempty  (input_buffer_empty )
	);

    always @(posedge clk or negedge reset_n ) begin
        if (!reset_n) begin
            state_reg       <= IDLE ;
            complete_reg    <= 0    ;
            cnt_end_reg     <= 0    ;
        end
        else begin
            state_reg           <= state_next           ;
            compute_out_reg     <= compute_out_next     ;
            complete_reg        <= complete_next        ;
            spike_reg           <= spike_next           ;
            cnt_end_reg         <= cnt_end_next         ;  
        end
    end

    always @(packet_out_valid, tick) begin
        if(tick) compute_out_next = {250{1'b0}};
        if(packet_out_valid) begin
            compute_out_next[249 - packet_out] = 1'b1;
        end
    end

    always @(*) begin
        complete_next   = complete_reg;
        cnt_end_next    = cnt_end_reg;
        case (state_reg)
            IDLE:begin
                if (!input_buffer_empty)
                    state_next      = LOAD;
                else
                    state_next      = IDLE;
            end
            LOAD:begin
                if (input_buffer_empty)begin
                    state_next      = COMPUTE;
                end
                else
                    state_next = LOAD;
            end
            COMPUTE:begin
                if (tick) begin
                    state_next = LOAD;
                    if(spike_en) spike_next = compute_out_reg;
                end
                if (load_end)begin
                    state_next      = WAIT_END;
                end
                else if (grid_state == 5)
                    state_next      = LOAD;
                else
                    state_next      = COMPUTE;
            end
            WAIT_END:begin
                if (tick)begin
                    cnt_end_next    = cnt_end_reg + 1'b1;
                    spike_next      = compute_out_reg;
                end
                if (cnt_end_reg == 2) begin
                    complete_next   = 1'b1;
                    state_next      = IDLE;
                end
                else
                    state_next      = WAIT_END;
            end
        endcase
    end
    
    assign state                = state_reg;
    assign spike_out            = spike_reg;
    assign complete             = complete_reg;
    
endmodule
