module load_param_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4 //depth = 1 << 8
)(
    input                     wclk    ,
    input                     wrst_n  ,
    input                     winc    ,
    input   [DSIZE-1:0]       wdata   ,
    output                    wfull   ,
    input                     rclk    ,
    input                     rrst_n  ,
    output                    write_en,	
    output  [$clog2(256)-1:0] address ,
    output  [DSIZE - 1:0]     data_in  
);

    wire [DSIZE-1:0] rdata  ;
    wire             rempty ;

    reg [$clog2(256)-1:0] count;

	assign write_en = ~rempty;
	assign data_in  = rdata  ;
	assign address  = count  ;

	always @(posedge rclk or negedge rrst_n) begin 
		if(~rrst_n ) begin
			count <= 0;
		end 
		else if(~rempty) begin 
			count <= count + 1;
		end
	end

	async_fifo #(
		.DSIZE (DSIZE),
		.ASIZE (ASIZE)
	) async_fifo_ins(
		.wclk   (wclk   ),
		.wrst_n (wrst_n ),
		.winc   (winc   ),
		.wdata  (wdata  ),
		.wfull  (wfull  ),
		.awfull (       ),
		.rclk   (rclk   ),
		.rrst_n (rrst_n ),
		.rinc   (1'b1   ),
		.rdata  (rdata  ),
		.rempty (rempty ),
		.arempty(       )
	);

endmodule