module neuron_grid_datapath_3x2 #(
    parameter CORE_NUMBER = 0
)(
    input [255:0] axon_spikes,
    input clk,
    input reset_n,
    input sys_clk,
    input sys_reset_n,
    input initial_axon_num,
    input inc_axon_num,
    input new_neuron,
    input process_spike,
    input update_potential,
    
    output done_axon,

    output reg [29:0] packet_out,
    output reg spike_out_valid,

    input inc_neuron_num, init_neuron_num, shot, local_buffers_full,
    output nb_finish_spike,

    //*new* param loader
    input                       param_wen           ,
    input   [31:0]              param_data_in       ,
    input                       neuron_inst_wen     ,
    input   [$clog2(256)-1:0]   neuron_inst_address ,
    input   [1:0]               neuron_inst_data_in           
);
reg [367:0] neuron_parameter [0:255];
reg [1:0] neuron_instructions[0:255];

wire [255:0] spike;
reg [7:0] neuron_num_shot, axon_num;
assign nb_finish_spike = neuron_num_shot == 255;



always @(negedge clk, negedge reset_n) begin
    if(~reset_n) begin
        neuron_num_shot <= 0;
    end
    else begin
        if(init_neuron_num) neuron_num_shot <= 0;
        if(inc_neuron_num) neuron_num_shot <= neuron_num_shot + 1;
    end
end
always @(negedge clk, negedge reset_n) begin
    if(~reset_n) begin
        packet_out <= 30'd0;
        spike_out_valid <= 0;
    end
    else begin
        packet_out <= (shot & spike[neuron_num_shot]) ? neuron_parameter[neuron_num_shot][29:0] : {30{1'b0}};
        spike_out_valid <= (~local_buffers_full) & shot & spike[neuron_num_shot];
    end
end

assign done_axon = (axon_num == 255);

always @(negedge clk, negedge reset_n) begin
    if(~reset_n) axon_num <= 8'd0;
    else if(initial_axon_num) axon_num <= 8'd0;
    else if(inc_axon_num) axon_num <= axon_num + 1'b1;
    else axon_num <= axon_num;
end


wire [8:0] potential_out [0:255];
genvar neuron_num;
for(neuron_num = 0; neuron_num < 256; neuron_num = neuron_num + 1) begin: gen_block
    wire reg_en;
    assign reg_en = (neuron_parameter[neuron_num][112 + axon_num] & axon_spikes[axon_num]);
    neuron_block neuron_block(
        .clk(clk),
        .reset_n(reset_n),
        .leak(neuron_parameter[neuron_num][57:49]),
        .weights(neuron_parameter[neuron_num][93:58]),
        .positive_threshold(neuron_parameter[neuron_num][48:40]),
        .negative_threshold(neuron_parameter[neuron_num][39:31]),
        .reset_potential(neuron_parameter[neuron_num][102:94]),
        .current_potential(neuron_parameter[neuron_num][111:103]),
        .neuron_instruction(neuron_instructions[axon_num]),
        .reset_mode(neuron_parameter[neuron_num][30]),
        .new_neuron(new_neuron),
        .process_spike(process_spike),
        .reg_en(reg_en),
        .potential_out(potential_out[neuron_num]),
        .spike_out(spike[neuron_num])
    );
end

integer i;
localparam  LOAD	    = 1'b0;
localparam  END_LINE    = 1'b1;
reg                     state_reg, state_next;
reg [4:0]               cnt_line_param_reg, cnt_line_param_next;
reg [$clog2(256)-1:0]   param_address_reg, param_address_next;
always @(posedge clk, negedge reset_n) begin
    if(~reset_n) begin
        if (CORE_NUMBER == 5) begin
            for (i = 0; i < 256; i = i + 1) begin
                neuron_parameter[i] <=  368'b00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000;
            end
        end
        else begin
            state_reg           <= LOAD;
            cnt_line_param_reg             <= 0;
            param_address_reg   <= 0;
        end
    end
    else if (param_wen) begin
        state_reg           <= state_next;
        cnt_line_param_reg             <= cnt_line_param_next;
        param_address_reg   <= param_address_next;
        if (state_reg == LOAD ) begin
            neuron_parameter[param_address_reg][(cnt_line_param_reg)*32 +: 32] <= param_data_in;
        end
        else if (state_reg == END_LINE) begin
            neuron_parameter[param_address_reg][(cnt_line_param_reg)*32 +: 16] <= param_data_in[15:0];
        end
    end
    else if(update_potential) begin
        for(i = 0; i<256; i = i + 1) neuron_parameter[i][111:103] <= potential_out[i];
    end
    else begin
        for(i = 0; i<256; i = i + 1) neuron_parameter[i] <= neuron_parameter[i];
    end
end

always @(*) begin
    state_next = state_reg;
    cnt_line_param_next = cnt_line_param_reg;
    param_address_next = param_address_reg;
    case (state_reg)
        LOAD: begin
            if(param_wen) begin
                cnt_line_param_next    = cnt_line_param_reg + 1'b1;
            end
            if(cnt_line_param_reg == 10) begin
                state_next  = END_LINE;
            end
            else begin
                state_next  = LOAD;
            end
        end
        END_LINE: begin     
            if (cnt_line_param_reg == 11) begin
                cnt_line_param_next    = 0;
                state_next  = LOAD;
                param_address_next = param_address_reg + 1'b1;
                if (param_address_reg != 8'b11111111) begin
                    param_address_next = param_address_reg + 1'b1;
                end
            end
            else begin
                state_next = END_LINE;
            end
        end
    endcase
end

always @(posedge clk) begin
    if (neuron_inst_wen) begin
        neuron_instructions[neuron_inst_address] <= neuron_inst_data_in;
    end
end

endmodule

