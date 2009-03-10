static FILE *_open_exclusive(char *filename) {
#if defined(O_EXCL)&&defined(O_CREAT)&&defined(O_WRONLY)&&defined(O_TRUNC)
	/* Use O_EXCL to avoid a race condition when another process tries to
	   write the same file.  When that happens, our open() call fails,
	   which is just fine (since it's only a cache).
	   XXX If the file exists and is writable but the directory is not
	   writable, the file will never be written.  Oh well.
	*/
	int fd;
	(void) unlink(filename);
	fd = open(filename, O_EXCL|O_CREAT|O_WRONLY|O_TRUNC
#ifdef O_BINARY
				|O_BINARY   /* necessary for Windows */
#endif
#ifdef __VMS
                        , 0666, "ctxt=bin", "shr=nil"
#else
                        , 0666
#endif
		  );
	if (fd < 0)
		return NULL;
	return fdopen(fd, "wb");
#else
	/* Best we can do -- on Windows this can't happen anyway */
	return fopen(filename, "wb");
#endif
}