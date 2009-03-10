#include <stdlib.h>
#include <string.h>
int main (int argc, char const *argv[]) {
  char *ss = "/tmp/fileXXXXXX";
  char *s = (char *)malloc(strlen(ss));
  strcpy(s, ss);
  puts(mktemp(s));
  free(s);
  return 0;
}