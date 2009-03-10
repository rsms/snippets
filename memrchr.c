void *memrchr(const void *buf, unsigned char c, size_t length) {
  unsigned char *p = (unsigned char *) buf;
  if(length == 0) {
    return NULL;
  }
  for (;;) {
    if (*p-- == c) {
      break;
    }
    if (length-- == 0) {
      return NULL;
    }
  }
  return (void *) (p + 1);
}