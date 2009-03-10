#include <stdlib.h>
#include <string.h>
#include "base62.h"

char *base62_encode(char d[23], long long val, int min_digits) {
  static const char ABC[] = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
  long long m = 62;
  lldiv_t r;
  
  for(int i=0; i<22; i++) {
    r = lldiv(val, m);
    val = r.quot;
    d[21-i] = ABC[(int)r.rem];
    
    if ( (val == 0) && (min_digits <= i+1) ) {
      d[22] = 0;
      char *res = (char *)d;
      res += 21-i;
      return res;
    }
  }
  
  d[22] = 0;
  return d;
}

