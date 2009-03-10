// Return 0 on success
int smisk_file_write(const char *fn, const char *data, size_t len, int flags) {
  log_debug("ENTER smisk_file_write  fn='%s'  len=%lu", fn, len);
  FILE *f;
  
  if(len == 0) {
    return 0;
  }
  
  if((f = fopen(fn, (flags & SMISK_FILE_APPEND) ? "a" : "w")) == NULL) {
    PyErr_SetFromErrnoWithFilename(PyExc_IOError, __FILE__);
    return -1;
  }
  
  if(fwrite((const void *)data, 1, len, f) < len) {
    PyErr_SetFromErrnoWithFilename(PyExc_IOError, __FILE__);
    fclose(f);
    return -1;
  }
  
  fclose(f);
  return 0;
}
