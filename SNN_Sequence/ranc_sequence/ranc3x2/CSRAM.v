// module CSRAM #(
//     parameter FILENAME = "csram_000.mem",
//     parameter NUM_NEURONS = 256,
//     parameter WIDTH = 368,
//     parameter WRITE_INDEX = 103,
//     parameter WRITE_WIDTH = 9
// )(
//     input                                   clk,
//     input                                   wen,  
//     input       [$clog2(NUM_NEURONS)-1:0]   address,
//     input       [WRITE_WIDTH-1:0]           data_in,
//     output reg  [WIDTH-1:0]                 data_out
// ); 

//     reg [WIDTH-1:0] memory [0:NUM_NEURONS-1];

//     initial begin
//         $readmemb(FILENAME, memory);
//         data_out <= 0;
//     end
    
//     always@(negedge clk) begin
//         if (wen) begin
//             memory[address][WRITE_INDEX +: WRITE_WIDTH] <= data_in;
//         end
//         else begin
//             data_out <= memory[address];
//         end
//     end
// endmodule

module CSRAM #(
    parameter NUM_ELEMENT = 256,
    parameter WIDTH = 368
)(
    input                               clk, 
    input                               we, 
    input                               en,
    input   [$clog2(NUM_ELEMENT)-1:0]   addr, 
    input   [WIDTH-1:0]                 di, 
    output reg [WIDTH-1:0]                 dout
);   

reg [WIDTH-1:0] RAM [0:NUM_ELEMENT-1];
integer i;

always @(posedge clk)
begin
    if (en)
    begin
        if (we)
        begin
            RAM[addr] <= di;
            dout <= di;
        end
        else
            dout <= RAM[addr];
    end
end
endmodule