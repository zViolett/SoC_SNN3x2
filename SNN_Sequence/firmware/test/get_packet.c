#include <stdio.h>
#include <stdlib.h>

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

int main()
{
	int i = 0;
   char pack[10];
   FILE *fptr;
   int value=0;

   // use appropriate location if you are using MacOS or Linux
   fptr = fopen("packet_input_4.mem","r");
//   fptr = fopen("/home/riolet/Desktop/num_pic.txt","r");

   if(fptr == NULL)
   {
      printf("Error!");   
      exit(1);             
   }

//   for (int i = 0 ; i<30; i++){
//   	fgets(pack, 30, fptr);
//   	printf("%s", pack);
//   }

	while(!feof(fptr)){
		fgets(pack, 10, fptr);
      // value = hexdec(pack);
		printf("mem[%d] <= 30'b%s;\n", i, pack);
		i++;
	}
   fclose(fptr);
   return 0;
}

