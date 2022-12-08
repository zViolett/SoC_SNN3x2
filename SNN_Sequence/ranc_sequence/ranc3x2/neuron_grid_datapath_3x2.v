module neuron_grid_datapath_3x2 #(
    parameter CORE_NUMBER = 0
)(
    input update_potential,
    input local_buffers_full,
    input [255:0] axon_spikes,
    input clk,
    input reset_n,
    input initial_axon_num,
    input inc_axon_num,
    input initial_neuron_num,
    input inc_neuron_num,
    input new_neuron,
    input process_spike,
    output reg done_neuron,
    output done_axon,
    output reg [29:0] packet_out,
    output reg spike_out_valid,

    //*new* param loader
    input                       param_wen           ,
    input   [$clog2(256)-1:0]   param_address       ,
    input   [367:0]             param_data_in       ,
    input                       neuron_inst_wen     ,
    input   [$clog2(256)-1:0]   neuron_inst_address ,
    input   [1:0]               neuron_inst_data_in
);
// reg [367:0] neuron_parameter [0:255];
reg [1:0] neuron_instructions[0:255];

wire spike_out;
reg [7:0] axon_num, neuron_num;
wire [8:0] potential_out;

reg     [367:0] csram_di;
reg             csram_wen;
reg     [7:0]   csram_addr;
wire    [367:0] csram_dout;

CSRAM CSRAM_inst(
    .clk    (clk),
    .we     (csram_wen),
    .en     (reset_n),
    .addr   (csram_addr),
    .di     (csram_di),
    .dout   (csram_dout)
);

always @(negedge clk, negedge reset_n) begin
    if(~reset_n) begin
        packet_out      <= 30'd0;
        spike_out_valid <= 0;
    end
    else begin
        // packet_out <= spike_out & update_potential ? neuron_parameter[neuron_num][29:0] : {30{1'b0}};
        spike_out_valid <= (~local_buffers_full) & spike_out & update_potential;
        if (spike_out & update_potential) begin
            packet_out  <=  csram_dout[29:0];
        end
        else
            packet_out  <=  {30{1'b0}};
    end
end

assign done_axon = (axon_num == 255);

always @(negedge clk, negedge reset_n) begin
    if(~reset_n) axon_num <= 8'd0;
    else if(initial_axon_num) axon_num <= 8'd0;
    else if(inc_axon_num) axon_num <= axon_num + 1'b1;
    else axon_num <= axon_num;
end

always @(negedge clk, negedge reset_n) begin
    if(~reset_n) neuron_num <= 8'd0;
    else if(initial_neuron_num) neuron_num <= 8'd0;
    else if(inc_neuron_num) neuron_num <= neuron_num + 1'b1;
    else neuron_num <= neuron_num;
end


always @(posedge clk, negedge reset_n) begin
    if(~reset_n) done_neuron <= 0;
    else if(neuron_num == 255) done_neuron <= 1;
    else done_neuron <= 0;
end

wire reg_en;
// assign reg_en = (neuron_parameter[neuron_num][112 + axon_num] & axon_spikes[axon_num]);
// neuron_block neuron_block(
//     .clk(clk),
//     .reset_n(reset_n),
//     .leak(neuron_parameter[neuron_num][57:49]),
//     .weights(neuron_parameter[neuron_num][93:58]),
//     .positive_threshold(neuron_parameter[neuron_num][48:40]),
//     .negative_threshold(neuron_parameter[neuron_num][39:31]),
//     .reset_potential(neuron_parameter[neuron_num][102:94]),
//     .current_potential(neuron_parameter[neuron_num][111:103]),
//     .neuron_instruction(neuron_instructions[axon_num]),
//     .reset_mode(neuron_parameter[neuron_num][30]),
//     .new_neuron(new_neuron),
//     .process_spike(process_spike),
//     .reg_en(reg_en),
//     .potential_out(potential_out),
//     .spike_out(spike_out)
// );

assign reg_en = (csram_dout[112 + axon_num] & axon_spikes[axon_num]);
neuron_block neuron_block(
    .clk(clk),
    .reset_n(reset_n),
    .leak(csram_dout[57:49]),
    .weights(csram_dout[93:58]),
    .positive_threshold(csram_dout[48:40]),
    .negative_threshold(csram_dout[39:31]),
    .reset_potential(csram_dout[102:94]),
    .current_potential(csram_dout[111:103]),
    .neuron_instruction(neuron_instructions[axon_num]),
    .reset_mode(csram_dout[30]),
    .new_neuron(new_neuron),
    .process_spike(process_spike),
    .reg_en(reg_en),
    .potential_out(potential_out),
    .spike_out(spike_out)
);

always @(*) begin
    if (param_wen) begin
        csram_wen       <= 1;
        csram_addr      <= param_address;
        csram_di        <= param_data_in;
    end
    else if(update_potential) begin
        csram_wen       <= 1;
        csram_addr      <= neuron_num;
        csram_di        <= {csram_dout[367:112],potential_out,csram_dout[102:0]};
    end
    else begin
        csram_wen       <= 0;
        csram_addr      <= neuron_num;
    end
end
///////Khởi tạo csram
integer i;
// always @(posedge clk, negedge reset_n) begin
//     if(~reset_n) begin
//         // if ((CORE_NUMBER != 0) && (CORE_NUMBER != 1) && (CORE_NUMBER != 2) && (CORE_NUMBER != 3) && (CORE_NUMBER != 4)) begin
//         //     for (i = 0; i < 256; i = i + 1) begin
//         //         neuron_parameter[i] <=  368'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000;
//         //     end
//         // end
//         csram_di        <= 0;
//         csram_wen       <= 0;
//         csram_addr      <= 0;
//     end
//     else if (param_wen) begin
//         csram_wen       <= 1;
//         csram_addr      <= param_address;
//         csram_di        <= param_data_in;
//         neuron_parameter[param_address] <= param_data_in;
//     end
//     else if(update_potential) begin
//         // param_update[111:103] <= {csram_dout[367:112],potential_out,csram_dout[102:0]};
//         csram_wen       <= 1;
//         csram_addr      <= neuron_num;
//         csram_di        <= {csram_dout[367:112],potential_out,csram_dout[102:0]};
//         neuron_parameter[neuron_num][111:103] <= potential_out;
//     end
//     else begin
//         csram_wen       <= 0;
//         csram_addr      <= neuron_num;
//     end
// end

always @(posedge clk) begin
    if (neuron_inst_wen) begin
        neuron_instructions[neuron_inst_address] <= neuron_inst_data_in;
    end
end

endmodule
