#include <unistd.h>
static int file_exist(const char *fn) {
	return ((access(fn, R_OK) == 0) ? 1 : 0);
}