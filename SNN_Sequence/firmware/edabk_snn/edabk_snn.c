#include "edabk_snn.h"
#include "../sd/sd.h"
#include <generated/csr.h>
#include <stdlib.h>
#include <string.h>
#include <liblitesdcard/sdcard.h>
#include <libfatfs/ff.h>			
#include <libfatfs/diskio.h>

static const long hextable[] = {
   [0 ... 255] = -1, // bit aligned access into this table is considerably
   ['0'] = 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, // faster for most modern processors,
   ['A'] = 10, 11, 12, 13, 14, 15,       // for the space conscious, reduce to
   ['a'] = 10, 11, 12, 13, 14, 15        // signed char.
};

long hexdec(unsigned const char *hex) {
   long ret = 0; 
   while (*hex && ret >= 0) {
      ret = (ret << 4) | hextable[*hex++];
   }
   return ret; 
}

void load_neuron_parameter(const char* path){
	FIL fptr[1];
	FRESULT op = f_open(fptr, path, FA_READ);
	if (op != FR_OK){
		printf("Could not open file: %s\n", "csram.mem");
	}
	char param_string[93];
	int line_index = 93;
	uint16_t index = 0;
	int param[256][12]={};
	int i = 0;

	printf("Assigning parameter...\n");
	while ((f_eof(fptr) == 0)){
		f_gets((char*)param_string, 93, fptr);// read current line
		f_lseek(fptr, line_index);// move to the next line
		// printf("param: %s\n", param_string);
		line_index = line_index + 93;
		char value[9];
		for (int j = 0; j < 12; j++){
			if(j == 0){
            	strncpy(value, param_string, 4);
            	value[5] = 0; 
        	} else{
            	strncpy(value, param_string + 4 + (j - 1) * 8, 8);
            	value[9] = 0; 
       		}	   
			param[i][j] = hexdec(value);
		}
		i++;
	}
	
	// #ifdef DEBUG
	for(int i = 0; i < 256; i++){
		printf("Parameter %3d: %8X %8X %8X %8X %8X %8X %8X %8X %8X %8X %8X %8X \n", i, \
		param[i][0],param[i][1],param[i][2],param[i][3],param[i][4],param[i][5], param[i][6] \
		,param[i][7],param[i][8],param[i][9],param[i][10],param[i][11]);
	}
	// #endif

	printf("Loading parameter...\n");
    do {
		if (!snn_3x2_snn_status_param_wfull_read()) {
			snn_3x2_param_wdata0_write  (param[index][11]);
			snn_3x2_param_wdata1_write  (param[index][10]);			
			snn_3x2_param_wdata2_write  (param[index][9]) ;			
			snn_3x2_param_wdata3_write  (param[index][8]) ;			
			snn_3x2_param_wdata4_write  (param[index][7]) ;			
			snn_3x2_param_wdata5_write  (param[index][6]) ;			
			snn_3x2_param_wdata6_write  (param[index][5]) ;			
			snn_3x2_param_wdata7_write  (param[index][4]) ;			
			snn_3x2_param_wdata8_write  (param[index][3]) ;			
			snn_3x2_param_wdata9_write  (param[index][2]) ;			
			snn_3x2_param_wdata10_write (param[index][1]) ;			
			snn_3x2_param_wdata11_write (param[index][0]) ;			
			index++;
		}
	} while (index < 256);

	// printf("Parameter load successful!!!\n\n");

}

void load_neuron_inst(const char* path){
	FIL fptr[1];
	FRESULT op = f_open(fptr, path, FA_READ);
	if (op != FR_OK){
		printf("Could not open file: %s\n", path);
	}

	char neuron_inst_string[3]={};
	int line_index = 3;
	uint16_t index = 0;
	uint8_t neuron_inst[256]={};
	int i = 0;

	while ((f_eof(fptr) == 0)){
		f_gets((char*)neuron_inst_string, sizeof(neuron_inst_string), fptr);
		f_lseek(fptr, line_index);
		line_index = line_index + 3;
		neuron_inst_string[3] = 0;
		neuron_inst[i] = strtol(neuron_inst_string, (char **)NULL, 16);
		i++;
	}

	// #ifdef DEBUG
	for(int i = 0; i < 256; i++){
		printf("Neuron instructions %3d: 0x%x\n", i, neuron_inst[i]);
	}
	// #endif
	
    do {
		if (!snn_3x2_snn_status_neuron_inst_wfull_read()) {
			snn_3x2_neuron_inst_wdata_write (neuron_inst[index]);		
			index++;
		}
	} while (index < 256);
	printf("Neuron instructions successful!!!\n\n");

}


void load_packet_in(uint32_t num_packet, uint16_t num_pic){
	FIL fptr_input[1];
	FRESULT op1 = f_open(fptr_input, "packet_input.mem", FA_READ);

	FIL fptr_num_inputs[1];
	FRESULT op2 = f_open(fptr_num_inputs, "num_inputs.mem", FA_READ);

	if (op1 != FR_OK){
		printf("Could not open file : %s\n", "packet_input.mem");
	}
	if (op2 != FR_OK){
		printf("Could not open file : %s\n", "num_inputs.mem");
	}

	char packet_string[9]={};
	char num_input_string[4]={};
	// int num_packet = f_size(fptr_input);
	// int num_pic = f_size(fptr_num_inputs);
	int packet_in[num_packet];
	int num_input[num_pic];
	int index = 0;
	int begin_address = 0;
	int pic_index = 0;
	int i = 0;
	int n = 0;

	printf("Assigning packet...\n");
	int line_index = 9;
	while ((f_eof(fptr_input) == 0)){
		f_gets((char*)packet_string, sizeof(packet_string), fptr_input);
		f_lseek(fptr_input, line_index);
		line_index = line_index + 9;
		packet_string[9] = 0;
		packet_in[i] = strtol(packet_string, (char **)NULL, 16);
		i++;
	}
	line_index = 4;
	while ((f_eof(fptr_num_inputs) == 0)){
		f_gets((char*)num_input_string, sizeof(num_input_string), fptr_num_inputs);
		f_lseek(fptr_num_inputs, line_index);
		line_index = line_index + 4;
		num_input_string[4] = 0;
		num_input[n] = strtol(num_input_string, (char **)NULL, 16);
		n++;
	}
	

	// #ifdef DEBUG
	for(int i = 0; i < num_packet; i++){
		printf("Packet in %3d: 0x%X\n", i ,packet_in[i]);
	}
	// #endif

	printf("Handling packet...!\n");
	for ( pic_index = 0; pic_index < num_pic; pic_index++)
	{
		if (pic_index >1)
		{
			snn_3x2_spike_en_write(1);
		}
		index = 0;
		do {
			if (!snn_3x2_snn_status_packet_wfull_read()) {
				snn_3x2_packet_wdata_write (packet_in[begin_address + index]) ;		
				index++;
			}
		} while (index < num_input[pic_index]);
		begin_address = begin_address + num_input[pic_index];
		while (1)
		{
			if (snn_3x2_grid_state_read() != 0) break;			
		}
		printf("Waiting for computation done!");
		while (1) {
			if (snn_3x2_grid_state_read() == 0) break;
		}
	}
	snn_3x2_load_end_write(1);
}

// void handling_packets(const char* path, uint8_t num_inputs){

// 	load_packet_in(path, num_inputs);

// 	while (!edabk_snn_tick_ready_read()){
// 		printf("Waiting tick_ready!!!!!!!!\n");
// 	}

// 	edabk_snn_tick_ready_write(0);
// 	printf("\nTick ready!!!!!!!!\n");
	
// 	edabk_snn_tick_write(1);

// 	while(!edabk_snn_snn_status_wait_packets_read()){
// 		printf("Waiting!!!!!!!!\n");
// 	}
// 	printf("\nRead packet out!!!!!!!!\n");

// 	while (1)
// 	{
// 		if(!edabk_snn_snn_status_packet_out_rempty_read()){
// 			printf("Packet out: 0x%X\n", edabk_snn_packet_out_read());
// 			edabk_snn_packet_out_rinc_write(1);
// 		}

// 		if (readchar_nonblock()) {
//   			getchar();
//   			break;
//   		}
// 	}
// }

void test_function(void){

	printf("Begin handler parameter into each core.\n Start Core 0...\n");
	snn_3x2_next_core_write(0);
	load_neuron_parameter("neuron_param0.mem");
	while (1)
	{
		if (snn_3x2_next_core_en_read()) break;
	}
	snn_3x2_next_core_write(1);
	printf("Loading param for core 0 done!");
	load_neuron_parameter("neuron_param1.mem");
	while (1)
	{
		if (snn_3x2_next_core_en_read()) break;
	}
	snn_3x2_next_core_write(2);
	printf("Loading param for core 1 done!");
	load_neuron_parameter("neuron_param2.mem");
	while (1)
	{
		if (snn_3x2_next_core_en_read()) break;
	}
	snn_3x2_next_core_write(3);
	printf("Loading param for core 2 done!");
	load_neuron_parameter("neuron_param3.mem");
	while (1)
	{
		if (snn_3x2_next_core_en_read()) break;
	}
	snn_3x2_next_core_write(4);
	printf("Loading param for core 3 done!");
	load_neuron_parameter("neuron_param4.mem");
	while (1)
	{
		if (snn_3x2_next_core_en_read()) break;
	}
	snn_3x2_next_core_write(5);
	printf("Loading param for core 4 done!");

	load_neuron_inst("neuron_inst.mem");

	printf("Start transfer packet into SNN...");
	load_packet_in(549,4);
	printf("Waiting processing end!\n");
	while (1)
	{
		if (snn_3x2_complete_read())
		{
			printf("Complete SNN");
			break;
		}
	}
}

void change_while(void){

	printf("Begin handler parameter into each core.\n Start Core 0...\n");
	snn_3x2_next_core_write(0);
	load_neuron_parameter("neuron_param0.mem");
	while (!snn_3x2_next_core_en_read())
	{
		printf("Wait next core...");
	}
	snn_3x2_next_core_write(1);
	printf("Loading param for core 0 done!");
	load_neuron_parameter("neuron_param1.mem");
	while (!snn_3x2_next_core_en_read())
	{
		printf("Wait next core...");
	}
	snn_3x2_next_core_write(2);
	printf("Loading param for core 1 done!");
	load_neuron_parameter("neuron_param2.mem");
	while (!snn_3x2_next_core_en_read())
	{
		printf("Wait next core...");
	}
	snn_3x2_next_core_write(3);
	printf("Loading param for core 2 done!");
	load_neuron_parameter("neuron_param3.mem");
	while (!snn_3x2_next_core_en_read())
	{
		printf("Wait next core...");
	}
	snn_3x2_next_core_write(4);
	printf("Loading param for core 3 done!");
	load_neuron_parameter("neuron_param4.mem");
	while (!snn_3x2_next_core_en_read())
	{
		printf("Wait next core...");
	}
	snn_3x2_next_core_write(5);
	printf("Loading param for core 4 done!");

	load_neuron_inst("neuron_inst.mem");

	printf("Start transfer packet into SNN...");
	load_packet_in(549,4);
	printf("Waiting processing end!\n");
	while (!snn_3x2_complete_read())
	{
		printf("Waiting...\n");
	}
	printf("Complete SNN");
}
