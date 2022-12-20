#include "sd.h"
#include <stdio.h>
#include <liblitesdcard/sdcard.h>
#include <libfatfs/ff.h>			
#include <libfatfs/diskio.h>
#define SDCARD_DEBUG

static FATFS  fatfs;

int sd_init(void){
	FRESULT rc;
	TCHAR *Path = "0:/";
	rc = f_mount(&fatfs,Path,0);
	if (rc) {
		printf(" ERROR : f_mount returned %d\r\n", rc);
		return 0;
	}
	return 1;
}

int sd_eject(void){
	FRESULT rc;
	TCHAR *Path = "0:/";
	rc = f_mount(0,Path,1);
	if (rc){
		printf(" ERROR : f_mount returned %d\r\n", rc);
		return 0;
	}
	return 1;
}

void show_SD_info(void){
  sdcard_decode_cid();
  sdcard_decode_csd();
}

int read_file(const char* path, char* data) {
	UINT* br;
	FIL fptr[1];
	FRESULT op = f_open(fptr, path, FA_READ);
	printf("%d", fptr->obj.objsize);

	if (op != FR_OK){
		printf("Could not open file: %s\n", path);
		return 0;
	}

	if (fptr->obj.objsize == 0){
		return 0;
	}

	char buff[fptr->obj.objsize + 1];

	f_read(fptr, (void*) buff, fptr->obj.objsize, br);

 	printf("Successfully read file: %s\n", path);
	f_close(fptr);

  	data = buff;
  
	return 1;
}
