module neuron_grid_3x2 #(
    parameter CORE_NUMBER = 0
)(
    input local_buffers_full,
    input clk,
    input reset_n,
    input tick,
    input [255:0] axon_spikes,
    output error,
    output scheduler_set,
    output scheduler_clr,
    output done,
    output [29:0] packet_out,
    output spike_out_valid,
    output [2:0] grid_state,

     //new param load
    input                       param_wen           ,
    input   [367:0]             param_data_in       ,
    input   [7:0]               param_address       ,
    input                       neuron_inst_wen     ,
    input   [$clog2(256)-1:0]   neuron_inst_address ,
    input   [1:0]               neuron_inst_data_in  
);


neuron_grid_controller controller(
    .tick(tick),
    .done_neuron(done_neuron), .done_axon(done_axon),
    .clk(clk),
    .reset_n(reset_n),
    .process_spike(process_spike),
    .scheduler_clr(scheduler_clr),
    .scheduler_set(scheduler_set),
    .inc_neuron_num(inc_neuron_num),
    .initial_neuron_num(initial_neuron_num),
    .initial_axon_num(initial_axon_num),
    .inc_axon_num(inc_axon_num),
    .new_neuron(new_neuron),
    .update_potential(update_potential),
    .done(done),
    .error(error),
    .grid_state(grid_state)
);

neuron_grid_datapath_3x2 #(
    .CORE_NUMBER(CORE_NUMBER)
) datapath(
    .local_buffers_full(local_buffers_full),
    .axon_spikes(axon_spikes),
    .clk(clk),
    .reset_n(reset_n),
    .initial_axon_num(initial_axon_num),
    .inc_axon_num(inc_axon_num),
    .initial_neuron_num(initial_neuron_num),
    .inc_neuron_num(inc_neuron_num),
    .new_neuron(new_neuron),
    .process_spike(process_spike),
    .done_neuron(done_neuron),
    .done_axon(done_axon),
    .packet_out(packet_out),
    .spike_out_valid(spike_out_valid),
    .update_potential(update_potential),

    .param_wen(param_wen),
    .param_data_in(param_data_in),
    .param_address(param_address),
    .neuron_inst_wen(neuron_inst_wen),
    .neuron_inst_address(neuron_inst_address),
    .neuron_inst_data_in(neuron_inst_data_in)
);

endmodule

