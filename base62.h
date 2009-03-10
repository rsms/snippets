#ifndef BASE62_H
#define BASE62_H

/**
 * @param min_digits 0-62
 */
char *base62_encode(char d[23], long long val, int min_digits);

/*
 Example:
 char d[23];
 char *dd = base62_encode(d, 12345678LL, 15);
*/

#endif
