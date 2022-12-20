#ifndef __SD
#define __SD

int sd_init(void);
int sd_eject(void);
int read_file(const char* path, char* data);
void show_SD_info(void);
void read_line(const char* path);
#endif 