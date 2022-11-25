module RANCNetworkGrid_3x2 #(
    parameter GRID_DIMENSION_X = 3,
    parameter GRID_DIMENSION_Y = 2,
    parameter OUTPUT_CORE_X_COORDINATE = 2,
    parameter OUTPUT_CORE_Y_COORDINATE = 1
)(
    input clk,
    input reset_n,
    input tick,
    input input_buffer_empty,
    input [29:0] packet_in,

    output [7:0] packet_out,
    output packet_out_valid,
    output ren_to_input_buffer,
    output grid_controller_error,
    output scheduler_error,
    output [2:0] grid_state,
    output forward_north_local_buffer_empty_all,

    //*new* param loader
    input           sys_clk             ,
    input           sys_reset_n         ,
    input   [2:0]   next_core           ,
    input   [31:0]  parameter_in        ,
    input           param_winc          ,
    input   [1:0]   neuron_inst_wdata   ,
    input           neuron_inst_winc    ,
    output          next_core_en        
);

    localparam NUM_CORES = GRID_DIMENSION_X * GRID_DIMENSION_Y;
    localparam OUTPUT_CORE = OUTPUT_CORE_X_COORDINATE + OUTPUT_CORE_Y_COORDINATE * GRID_DIMENSION_X;
    // Wires for Errors:
    wire [NUM_CORES - 1:0] grid_controller_errors;
    wire [NUM_CORES - 1:0] scheduler_errors;
    
    // Wires for Eastward Routing Communication
    wire [NUM_CORES - 1:0] ren_east_bus;
    wire [NUM_CORES - 1:0] empty_east_bus;
    
    // Wires for Westward Routing Communication
    wire [NUM_CORES - 1:0] ren_west_bus;
    wire [NUM_CORES - 1:0] empty_west_bus;
    
    // Wires for Northward Routing Communication
    wire [NUM_CORES - 1:0] ren_north_bus;
    wire [NUM_CORES - 1:0] empty_north_bus;
    
    // Wires for Southward Routing Communication
    wire [NUM_CORES - 1:0] ren_south_bus;
    wire [NUM_CORES - 1:0] empty_south_bus;
    
    // Wires for packets
    wire [29:0] east_out_packets    [NUM_CORES - 1:0];
    wire [29:0] west_out_packets    [NUM_CORES - 1:0];
    wire [20:0] north_out_packets   [NUM_CORES - 1:0];
    wire [20:0] south_out_packets   [NUM_CORES - 1:0];

    //wire for param
    wire                        param_wfull_fifo            ;
    wire                        param_wen_fifo              ;
    wire    [31:0]              param_data_in_fifo          ;
    reg                         param_wen           [0:4]   ;
    reg     [31:0]              param_data_in       [0:4]   ;
    wire                        neuron_inst_wfull           ;
    wire                        neuron_inst_wen             ;
    wire    [$clog2(256)-1:0]   neuron_inst_address         ;
    wire    [1:0]               neuron_inst_data_in         ;

    wire                        p_wen_sync                  ;
    reg     [1:0]               cnt_wait_next_core          ;


    always @(posedge clk or negedge reset_n ) begin
        if (!reset_n) begin
            param_wen[0]        <=  0;
            param_data_in[0]    <=  0;
            cnt_wait_next_core  <=  0;
        end
        else begin
            if (!param_wen_fifo) begin
                cnt_wait_next_core <= cnt_wait_next_core + 1'b1;
            end
            else begin
                cnt_wait_next_core  <= 0;
            end
            if (next_core == 3'b000) begin
                param_wen[0]        <= param_wen_fifo        ;
                param_data_in[0]    <= param_data_in_fifo    ;
            end 
            else if (next_core == 3'b001) begin
                param_wen[1]        <= param_wen_fifo        ;
                param_data_in[1]    <= param_data_in_fifo    ;
                param_wen[0]        <= 0;
            end else if (next_core == 3'b010) begin
                param_wen[2]        <= param_wen_fifo        ;
                param_data_in[2]    <= param_data_in_fifo    ;
                param_wen[1]        <= 0;
            end else if (next_core == 3'b011) begin
                param_wen[3]        <= param_wen_fifo        ;
                param_data_in[3]    <= param_data_in_fifo    ;
                param_wen[2]        <= 0;
            end else if (next_core == 3'b100) begin
                param_wen[4]        <= param_wen_fifo        ;
                param_data_in[4]    <= param_data_in_fifo    ;
                param_wen[3]        <= 0;
            end
            else begin
                param_wen[0] <= 0;
                param_wen[1] <= 0;
                param_wen[2] <= 0;
                param_wen[3] <= 0;
                param_wen[4] <= 0;
            end
        end
    end
    
    assign p_wen_sync = (cnt_wait_next_core == 2) ? 1
                        : param_wen_fifo ? 0
                        : p_wen_sync;

    wire  [2:0] grid_state_reg [NUM_CORES - 2:0];
    wire [NUM_CORES -2 :0] forward_north_local_buffer_empty ;
    assign grid_state = grid_state_reg[NUM_CORES - 2];
    genvar curr_core;
    
    assign grid_controller_error = | grid_controller_errors;  // OR all TC errors to get final grid_controller_error
    assign scheduler_error = | scheduler_errors;                // OR all SCH errors to get final scheduler error
    assign ren_to_input_buffer = ren_west_bus[0];               // Read enable to the buffer that stores the input packets
    assign forward_north_local_buffer_empty_all = & forward_north_local_buffer_empty;

////////////////////////////////////////
/*    Synchrounous param              */
////////////////////////////////////////
    load_param_fifo #(
        .DSIZE (2)
    ) load_neuron_inst_fifo(
        .wclk     (sys_clk              ),
        .wrst_n   (sys_reset_n          ),
        .winc     (neuron_inst_winc     ),
        .wdata    (neuron_inst_wdata    ),
        .wfull    (neuron_inst_wfull    ),
        .rclk     (clk                  ),
        .rrst_n   (reset_n              ),
        .write_en (neuron_inst_wen      ),
        .address  (neuron_inst_address  ),
        .data_in  (neuron_inst_data_in  )
    );

    load_param_fifo #(
        .DSIZE (32)
    ) load_param(
        .wclk     (sys_clk                  ),
        .wrst_n   (sys_reset_n              ),
        .winc     (param_winc               ),
        .wdata    (parameter_in             ),
        .wfull    (param_wfull_fifo         ),
        .rclk     (clk                      ),
        .rrst_n   (reset_n                  ),
        .write_en (param_wen_fifo           ),
        .data_in  (param_data_in_fifo       )
    );
    sync_2ff  #(
        .ASIZE  (1)
    ) param_wen_sync(
        .dest_clk   (sys_clk),
        .dest_rst_n (sys_reset_n),
        .src_ptr    (p_wen_sync),
        .dest_ptr   (next_core_en)
    );

    for (curr_core = 0; curr_core < GRID_DIMENSION_X * GRID_DIMENSION_Y; curr_core = curr_core + 1) begin : gencore
        localparam right_edge = curr_core % GRID_DIMENSION_X == (GRID_DIMENSION_X - 1);
        localparam left_edge = curr_core % GRID_DIMENSION_X == 0;
        localparam top_edge = curr_core / GRID_DIMENSION_X == (GRID_DIMENSION_Y - 1);
        localparam bottom_edge = curr_core / GRID_DIMENSION_X == 0;
        
        if (curr_core != OUTPUT_CORE) begin
            Core_3x2 #(
                .CORE_NUMBER(curr_core)
            )
            Core (
                .clk                                (clk                                                                                    ),
                .tick                               (tick                                                                                   ),
                .reset_n                            (reset_n                                                                                ),
                .ren_in_west                        (left_edge ? 1'b0 : ren_east_bus[curr_core - 1]                                         ),
                .ren_in_east                        (right_edge ? 1'b0 : ren_west_bus[curr_core + 1]                                        ),
                .ren_in_north                       (top_edge ? 1'b0 : ren_south_bus[curr_core + GRID_DIMENSION_X]                          ),
                .ren_in_south                       (bottom_edge ? 1'b0 : ren_north_bus[curr_core - GRID_DIMENSION_X]                       ),
                .empty_in_west                      (curr_core == 0 ? input_buffer_empty : left_edge ? 1'b1 : empty_east_bus[curr_core - 1] ),
                .empty_in_east                      (right_edge ? 1'b1 : empty_west_bus[curr_core + 1]                                      ),
                .empty_in_north                     (top_edge ? 1'b1 : empty_south_bus[curr_core + GRID_DIMENSION_X]                        ),
                .empty_in_south                     (bottom_edge ? 1'b1 : empty_north_bus[curr_core - GRID_DIMENSION_X]                     ),
                .east_in                            (right_edge ? {30{1'b0}} : west_out_packets[curr_core + 1]                              ),
                .west_in                            (curr_core == 0 ? packet_in : left_edge ? {30{1'b0}} : east_out_packets[curr_core - 1]  ),
                .north_in                           (top_edge ? {21{1'b0}} : south_out_packets[curr_core + GRID_DIMENSION_X]                ),
                .south_in                           (bottom_edge ? {21{1'b0}}: north_out_packets[curr_core - GRID_DIMENSION_X]              ),
                .ren_out_west                       (ren_west_bus[curr_core]                                                                ),
                .ren_out_east                       (ren_east_bus[curr_core]                                                                ),
                .ren_out_north                      (ren_north_bus[curr_core]                                                               ),
                .ren_out_south                      (ren_south_bus[curr_core]                                                               ),
                .empty_out_west                     (empty_west_bus[curr_core]                                                              ),
                .empty_out_east                     (empty_east_bus[curr_core]                                                              ),
                .empty_out_north                    (empty_north_bus[curr_core]                                                             ),
                .empty_out_south                    (empty_south_bus[curr_core]                                                             ),
                .east_out                           (east_out_packets[curr_core]                                                            ),
                .west_out                           (west_out_packets[curr_core]                                                            ),
                .north_out                          (north_out_packets[curr_core]                                                           ),
                .south_out                          (south_out_packets[curr_core]                                                           ),
                .grid_controller_error              (grid_controller_errors[curr_core]                                                      ),
                .scheduler_error                    (scheduler_errors[curr_core]                                                            ),
                .grid_state                         (grid_state_reg[curr_core]                                                              ),
                .forward_north_local_buffer_empty   (forward_north_local_buffer_empty[curr_core]                                            ),
                .param_wen                          (param_wen[curr_core]                                                                   ),
                .param_data_in                      (param_data_in[curr_core]                                                               ),
                .neuron_inst_wen                    (neuron_inst_wen                                                                        ),
                .neuron_inst_address                (neuron_inst_address                                                                    ),
                .neuron_inst_data_in                (neuron_inst_data_in                                                                    )
            );
        end
        else begin
            OutputBus #(
                .NUM_OUTPUTS(250)
            ) OutputBus (
                .clk(clk),
                .reset_n(reset_n),
                .ren_in_west(left_edge ? 1'b0 : ren_east_bus[curr_core - 1]),
                .ren_in_east(right_edge ? 1'b0 : ren_west_bus[curr_core + 1]),
                .ren_in_north(top_edge ? 1'b0 : ren_south_bus[curr_core + GRID_DIMENSION_X]),
                .ren_in_south(bottom_edge ? 1'b0 : ren_north_bus[curr_core - GRID_DIMENSION_X]),
                .empty_in_west(curr_core == 0 ? input_buffer_empty : left_edge ? 1'b1 : empty_east_bus[curr_core - 1]),
                .empty_in_east(right_edge ? 1'b1 : empty_west_bus[curr_core + 1]),
                .empty_in_north(top_edge ? 1'b1 : empty_south_bus[curr_core + GRID_DIMENSION_X]),
                .empty_in_south(bottom_edge ? 1'b1 : empty_north_bus[curr_core - GRID_DIMENSION_X]),
                .ren_out_west(ren_west_bus[curr_core]),
                .ren_out_east(ren_east_bus[curr_core]),
                .ren_out_north(ren_north_bus[curr_core]),
                .ren_out_south(ren_south_bus[curr_core]),
                .empty_out_west(empty_west_bus[curr_core]),
                .empty_out_east(empty_east_bus[curr_core]),
                .empty_out_north(empty_north_bus[curr_core]),
                .empty_out_south(empty_south_bus[curr_core]),
                .east_in(right_edge ? {30{1'b0}} : west_out_packets[curr_core + 1]),
                .west_in(curr_core == 0 ? packet_in : left_edge ? {30{1'b0}} : east_out_packets[curr_core - 1]),
                .north_in(top_edge ? {21{1'b0}} : south_out_packets[curr_core + GRID_DIMENSION_X]),      // North In From Next North's South Out
                .south_in(bottom_edge ? {21{1'b0}} : north_out_packets[curr_core - GRID_DIMENSION_X]),      // South In From Next South's North Out
                .east_out(east_out_packets[curr_core]),     // East Out, Next East's West In
                .west_out(west_out_packets[curr_core]),     // West Out, Next West's East In
                .north_out(north_out_packets[curr_core]),    // North Out, Next North's South In
                .south_out(south_out_packets[curr_core]),    // South Out, Next South's North In
                .packet_out(packet_out),
                .packet_out_valid(packet_out_valid),
                .grid_controller_error(grid_controller_errors[curr_core]),
                .scheduler_error(scheduler_errors[curr_core])
            );
        end
    end 

    
endmodule