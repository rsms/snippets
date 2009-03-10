/**
 * Spotify uses a non-standard base-62 alphabet for encoding/decoding object
 * identifiers. Since these identifiers are exposed both in a base-16 and a
 * base-62 form, you sometimes need to convert between these two
 * representations. This code provides the means of converting between the two
 * respresentations. If uses libtommath to aid with the 128-bit integer
 * (BigInt) calculations. (i.e. you need libtommath to run this example
 * program).
 *
 * Author: Rasmus Andersson
 *
 * This code is released in the Public Domain (no restrictions, no support
 * 100% free).
 *
 * Compile:
 * cc -ltommath -o spidconvert spidconvert.c
 *
 * If you have libtommath from ports:
 * cc -ltommath -o spidconvert -I/opt/local/include \
 *  -I/opt/local/include/libtommath -L/opt/local/lib spidconvert.c
 */
#include <string.h>
#include <stdio.h>
#include <libtommath/tommath.h>
#include <assert.h>

/* for simplicitys' sake we reuse these buffers */
static char _b62buf[23];
static char _hexbuf[33];

/* read 0-9a-zA-Z */
int read_radix_spb62(mp_int *r, const char *s) {
  int i;
  for(i=0; i<22; i++) {
    mp_mul_d(r, 62, r);
    int v = s[i];
    if (v >= '0' && v <= '9')
      v = (v - '0');
    else if (v >= 'a' && v <= 'z')
      v = (v - 'a')+10;
    else if (v >= 'A' && v <= 'Z')
      v = (v - 'A')+10+26;
    else
      return -1;
    mp_add_d(r, v, r);
  }
  if (s[22] != 0)
    return -1;
  return 0;
}

/* write 0-9a-zA-Z */
int toradix_spb62(mp_int *val, char *buf) {
  mp_int m[1], r[1];
  int i;
  mp_init(m);
  mp_init(r);
  mp_set_int(m, 62);
  static const char abc[] = 
  "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";
  for(i=0; i<22; i++) {
    mp_div(val, m, val, r);
    buf[21-i] = abc[mp_get_int(r)];
  }
  buf[22] = 0;
  mp_clear(m);
  mp_clear(r);
  return 0;
}

/* convert standard base-16 string s to spotify-style base-62 */
const char *hex_to_spb62(const char *s) {
  mp_int val[1];
  mp_init(val);
  mp_read_radix(val, s, 16);
  memset(_b62buf, 0, 23);
  /* replaces mp_toradix_n(val, _hexbuf, 62, 23) */
  toradix_spb62(val, _b62buf);
  mp_clear(val);
  return _b62buf;
}

/* convert spotify-style base-62 string s to standard base-16 */
const char *spb62_to_hex(const char *s) {
  mp_int val[1];
  mp_init(val);
  /* replaces mp_read_radix(val, b62, 62) */
  read_radix_spb62(val, s);
  memset(_hexbuf, 0, 23);
  mp_toradix_n(val, _hexbuf, 16, 33);
  mp_clear(val);
  /* Note: mp_toradix_n use 0-9A-F (capital letters A-F) */
  return _hexbuf;
}

/* Simple test program */
void test(void) {
  /* Known counterparts used as test substance */
  static char *hex_id = "BFE8CF67DF8F46AE999A341ADD9F100B";
  static char *b62_id = "5Q7VB5xRIqhGgp3CCsnRF1";
  
  /* Conversion */
  const char *b62_from_hex = hex_to_spb62(hex_id);
  const char *hex_from_b62 = spb62_to_hex(b62_id);
  
  /* Print it baby */
  printf("%s = %s\n", hex_id, b62_from_hex);
  printf("%s = %s\n", b62_id, hex_from_b62);
  
  /* The machine tells us if we did something wrong */
  assert(strcmp(b62_from_hex, b62_id)==0);
  assert(strcmp(hex_from_b62, hex_id)==0);
}

/* usage: program [identifier ..] */
int main (int argc, const char * argv[]) {
  if (argc < 2) {
    test();
  }
  else {
    int i;
    size_t len;
    for (i=1;i<argc;i++) {
      len = strlen(argv[i]);
      if (len == 22)
        printf("%s = %s\n", argv[i], spb62_to_hex(argv[i]));
      else if (len == 32)
        printf("%s = %s\n", argv[i], hex_to_spb62(argv[i]));
      else {
        fprintf(stderr, "argument %d is neither base-62 not base-16 or it has"
        " been truncated. Length\nshould be either 22 or 32 characters.\n", i);
        return 1;
      }
    }
  }
  return 0;
}
