#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
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
void load_neuron_parameter(void){
	FILE* fptr;
	//fptr = fopen("C:\Users\ailad\OneDrive\Desktop\Other\soc_snn3x2\soc_snn3x2_dat.nguyen\ranc_sequence\mem\neuron_param0.mem", "r");
	fptr = fopen("neuron_param0.mem", "r");
	//FRESULT op = f_open(fptr, "csram.mem", FA_READ);
	if (fptr == NULL){
		printf("Could not open file: %s\n", "neuron_param0.mem");
	}
	char param_string[94]={};
	// int line_index = 93;
	int index = 0;
	uint32_t param[256][12]={};
	int i = 0;
	int j = 0;
    int m = 0;
	char value[9]={};

	while (fgets((char*)param_string, 94, fptr) != NULL){
		for (j = 0; j < 12; j++){
			if(j == 0){
            	strncpy(value, param_string, 4);
            	value[4] = 0; 
        	} else{
            	strncpy(value, param_string + 4 + (j - 1) * 8, 8);
            	value[8] = 0; 
       		}	   
			param[i][j] = hexdec(value);
		}
		i++;
	}
    fclose(fptr);

	for(i = 0; i < 256; i++){
		printf("Parameter %3d: %08X %08X %08X %08X %08X %08X %08X %08X %08X %08X %08X %08X \n", i, param[i][0],param[i][1],param[i][2],param[i][3],param[i][4],param[i][5], param[i][6],param[i][7],param[i][8],param[i][9],param[i][10],param[i][11]);
	}

}


void load_packet_in(void){
	FILE* fptr_input;
	fptr_input = fopen("packet_input_4.mem", "r");
	if (fptr_input == NULL){
		printf("Could not open file: %s\n", "packet_input_4.mem");
	}

	char value[10]={};
	int line_index = 9;
	int index = 0;
	uint32_t packet_in[549];
	int i = 0;
	int n = 0;


	while (fgets(value,10, fptr_input) != NULL){
		// fgets((char*)param_string, 93, fptr);// read current line
		
        value[9] = 0;
		packet_in[i] = strtol(value, (char **)NULL, 16);
		i++;
	}
    fclose(fptr_input);

	for(int i = 0; i < 549; i++){
		printf("Packet in %3d: 0x%08X\n", i ,packet_in[i]);
	}	
}

void load_num_input(void){
	FILE* fptr_input;
	fptr_input = fopen("num_inputs_100.mem", "r");
	if (fptr_input == NULL){
		printf("Could not open file: %s\n", "num_inputs_100.mem");
	}

	char value[5]={};
	int line_index = 4;
	int index = 0;
	int num_input[100]={};
	int i = 0;
	int n = 0;


	while (fgets(value,5, fptr_input) != NULL){
		// fgets((char*)param_string, 93, fptr);// read current line
		
        value[4] = 0;
		num_input[i] = strtol(value, (char **)NULL, 16);
		i++;
	}
    fclose(fptr_input);

	for(int i = 0; i < 100; i++){
		printf("Num_input in %3d: 0x%03X\n", i ,num_input[i]);
	}	
}

int main (){
    // load_neuron_parameter();

    // char param_string[93] = "a8aaa68eaaa208fea5a48a51ca5a9d05c6211548832bd4277605a8acedf88c490000003ff00ffc00000000201000";
    // int param[12] = {};
    // int i = 0;
	// int j = 0;
    // char value[9]={};
	// int param_dsad[256][12]={};
    // for (j = 0; j < 12; j++){
	// 		if(j == 0){
    //         	strncpy(value, param_string, 4);
    //         	value[5] = '\0'; 
	// 			// printf("%s \n", value);
    //     	} else{
    //         	strncpy(value, param_string + 4 + (j - 1) * 8, 8);
    //         	value[9] = '\0';
	// 			// printf("%s \n", value);
    //    		}	   
	// 		param[j] = hexdec(value);
	// 	}

    // printf("Parameter %3d: %8X %8X %8X %8X %8X %8X %8X %8X %8X %8X %8X %8X \n", i, param[0],param[1],param[2],param[3],param[4],param[5], param[6],param[7],param[8],param[9],param[10],param[11]);

	// load_packet_in();
	// load_num_input();

	char text[10] = "abcdef";
	char *hex = text;
	long ret = 0; 
   	while (*hex && ret >= 0) {
      	ret = (ret << 4) | hextable[*hex++];
		printf("%X\n", ret);
   	}
    // system("pause");
    return 0;
}
