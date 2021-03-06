#import "SCPOperation.h"

#include <stdlib.h> /* system() */

@implementation SCPOperation

@synthesize delegate;


-(id)initWithSourcePath:(NSString *)s dstHost:(NSString *)dh dstPath:(NSString *)dp delegate:(id)de {
	self = [super init];
	src = s;
	dst = d;
	delegate = de;
	task = nil;
	didInterruptTaskOnPurpose = NO;
	monitor = [[DSFileExistenceMonitor alloc] initWithPath:src checkInterval:1.0 delegate:self];
	return self;
}

- (void)fileDidDisappear:(NSString *)path {
	NSLog(@"[%@] cancelling because %@ seized to exist", self, name);
	[self cancel];
}

- (void)cancel {
	NSLog(@"[%@] cancelling (task=%@)", self, task);
	if (task) {
		#if DEBUG
		NSLog(@"[%@] sending SIGINT to scp process %d", self, [task processIdentifier]);
		#endif
		didInterruptTaskOnPurpose = YES;
		kill([task processIdentifier], SIGINT);
	}
	if (fexmon && [fexmon respondsToSelector:@selector(cancel)])
		[fexmon cancel];
	[super cancel];
}


- (int)executeRemoteShellCommand:(NSString *)cmd {
	NSString *dstHost = [conf objectForKey:@"remoteHost"];
	if (!dstHost || ![dstHost length]) {
		// unlikely
		NSLog(@"[%@] executeRemoteShellCommand: missing 'remoteHost' (or it's empty) in config", self);
		return -1;
	}
	cmd = [cmd stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	cmd = [NSString stringWithFormat:@"ssh -n '%@' -- \"%@\"", dstHost, cmd];
	return system([cmd UTF8String]);
}


- (void)main {
	NSString *dstHost, *dstPath, *dstPathFinal, *scpPath, *tempName;
	NSArray *args;
	NSError *error = nil;
	int status;
	
	scpPath = [[NSUserDefaults standardUserDefaults] stringForKey:@"scpPath"];
	if (!scpPath || [[NSFileManager defaultManager] fileExistsAtPath:scpPath])
		scpPath = @"/usr/bin/scp";
	
	#if DEBUG
	NSLog(@"[%@] starting with conf %@", self, conf);
	#endif
	
	if (!(dstHost = [conf objectForKey:@"remoteHost"])) {
		#if DEBUG
		NSLog(@"[%@] missing 'remoteHost' in config -- aborting", self);
		#endif
		error = [NSError droPubErrorWithDescription:@"missing 'remoteHost' in config"];
		goto fail;
	}
	if ([dstHost length] < 1) {
		#if DEBUG
		NSLog(@"[%@] empty 'remoteHost' in config -- aborting", self);
		#endif
		error = [NSError droPubErrorWithDescription:@"empty 'remoteHost' in config"];
		goto fail;
	}
	
	tempName = [@".dpupload_" stringByAppendingString:name];
	
	if (!(dstPath = [conf objectForKey:@"remotePath"])) {
		dstPath = tempName;
		dstPathFinal = name;
	}
	else {
		dstPathFinal = [dstPath stringByAppendingPathComponent:name];
		dstPath = [dstPath stringByAppendingPathComponent:tempName];
	}
	
	args = [NSArray arrayWithObjects:
			@"-o", @"ConnectTimeout=10",
			@"-o", @"ServerAliveCountMax=30",
			@"-o", @"ServerAliveInterval=30",
			@"-pCB",
			path,
			[NSString stringWithFormat:@"%@:'%@'", dstHost, dstPath],
	nil];
	
	
	/*
	 
	 Todo: look at password auth using simulated TTY. Maybe by using
	       termios.h or simply ioctl:
	 
	 #include <stdio.h>
	 #include <stdlib.h>
	 #include <fcntl.h>
	 #include <sys/ioctl.h>
	 int main (int argc, char *argv[]) {
		 char *cmd, *nl = "\n";
		 int i, fd = 0;
		 if (argc > 1) { cmd = argv[1]; } else { cmd = "ls"; }
		 for (i = 0; cmd[i]; i++)
			ioctl (fd, TIOCSTI, cmd+i);
		 ioctl (fd, TIOCSTI, nl);
		 exit (0);
	 }
	 
	*/
	
	#if DEBUG
	NSLog(@"[%@] sending %@ --> %@:%@", self, path, dstHost, dstPath);
	NSLog(@"[%@] starting task: %@ %@", self, scpPath, [[args description] stringByReplacingOccurrencesOfString:@"\n" withString:@" "]);
	#endif
	
	// todo use popen or NSTask so we can send cancel signal to our child process
	task = [[NSTask alloc] init];
	[task setLaunchPath:scpPath];
	[task setArguments:args];
	
	// start monitor
	[g_opq addOperation:monitor];
	
	NSPipe *pipe = [NSPipe pipe];
	NSFileHandle* readHandle = [pipe fileHandleForReading];
	[readHandle readInBackgroundAndNotify];
	[task setStandardError:pipe];
	NSMutableString *stderrStr = [NSMutableString string];
	
	[task setCurrentDirectoryPath:path];
	[task launch];
	if (!task) {
		NSLog(@"[%@] failed to start scp with arguments %@", self, args);
		error = [NSError droPubErrorWithFormat:@"failed to launch %@ with arguments '%@'",
			scpPath, [args componentsJoinedByString:@"' '"]];
		goto fail;
	}
	
	// wait for scp to exit
	#if DEBUG
	NSLog(@"[%@] SCP %@ started with PID %d", self, task, [task processIdentifier]);
	#endif
	
	// read stderr until scp exists
	while ([task isRunning]) {
		NSData *data = [readHandle availableData];
		if (data && [data length])
			[stderrStr appendString:[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]];
	}
	
	status = [task terminationStatus];
	task = nil;
	
	// cancel file existence monitor
	[fexmon cancel];
	fexmon = nil;
	
	// handle status
	if (status != 0) {
		if (didInterruptTaskOnPurpose) {
			#if DEBUG
			NSLog(@"[%@] aborted", self);
			#endif
			
			// try to remove remote temp file
			NSString *cmd = [NSString stringWithFormat:@"rm -f %@", [dstPath shellArgumentRepresentation]];
			if ([self executeRemoteShellCommand:cmd] != 0) {
				NSLog(@"[%@] notice: failed to remove remote temp file %@", self, dstPath);
			}
			#if DEBUG
			else {
				NSLog(@"[%@] successfully removed remote tempfile %@ after abortion", self, dstPath);
			}
			#endif
			
			// inform delegate
			if (delegate && [delegate respondsToSelector:@selector(fileTransmission:didAbortForPath:)])
				[delegate fileTransmission:self didAbortForPath:path];
			#if DEBUG
			else if (delegate)
				NSLog(@"[%@] warn: delegate not responding to fileTransmission:didAbortForPath:", self);
			#endif
		}
		else {
			NSLog(@"[%@] failed with status %d", self, status);
			if ([name rangeOfString:@"/"].length && [stderrStr rangeOfString:@"No such file or directory"].length) {
				// oh, target directory need to be created. Let's try ssh mkdir -p:
				NSString *rmkdir = [NSString stringWithFormat:@"mkdir -p %@", [[dstPath stringByDeletingLastPathComponent] shellArgumentRepresentation]];
				if ([self executeRemoteShellCommand:rmkdir] == 0) {
					NSLog(@"[%@] created remote directory %@:%@", self, dstHost, dstPath);
				}
				else {
					NSLog(@"[%@] failed to create remote directory (%@) => !0", self, rmkdir);
				}
			}
			error = [NSError droPubErrorWithDescription:[stderrStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] code:status];
			goto fail;
		}
	}
	else {
		#if DEBUG
		NSLog(@"[%@] done", self);
		#endif
		
		// try to move remote temp file
		NSString *cmd = [NSString stringWithFormat:@"mv -f %@ %@", [dstPath shellArgumentRepresentation], [dstPathFinal shellArgumentRepresentation]];
		if ([self executeRemoteShellCommand:cmd] != 0) {
			NSLog(@"[%@] failed to move remote temp file %@ --> %@", self, dstPath, dstPathFinal);
			error = [NSError droPubErrorWithFormat:@"failed to move remote temp file %@ --> %@", dstPath, dstPathFinal];
			goto fail;
		}
		#if DEBUG
		else {
			NSLog(@"[%@] successfully moved remote %@ --> %@", self, dstPath, dstPathFinal);
		}
		#endif
		
		// inform delegate
		if (delegate && [delegate respondsToSelector:@selector(fileTransmission:didSucceedForPath:remoteURI:)])
			[delegate fileTransmission:self didSucceedForPath:path remoteURI:[NSString stringWithFormat:@"%@:%@", dstHost, dstPath]];
		#if DEBUG
		else if (delegate)
			NSLog(@"[%@] warn: delegate not responding to fileTransmission:didSucceedForPath:", self);
		#endif
	}
	
	return;
	
fail:
	// inform delegate
	if (delegate && [delegate respondsToSelector:@selector(fileTransmission:didFailForPath:reason:)])
		[delegate fileTransmission:self didFailForPath:path reason:error];
	#if DEBUG
	else if (delegate)
		NSLog(@"[%@] warn: delegate not responding to fileTransmission:didSucceedForPath:", self);
	#endif
}

@end


@implementation SCPOperationMonitor

-(id)initWithPath:(NSString *)p checkInterval:(NSTimeInterval)iv delegate:(id)d {
	self = [super init];
	path = p;
	ival = iv;
	delegate = d;
	initiallyExisted = [self checkExistence];
	return self;
}

-(BOOL)checkExistence {
	return [[NSFileManager defaultManager] fileExistsAtPath:path];
}

- (void)main {
	BOOL b, exists = initiallyExisted;
	while (!self.isCancelled) {
		b = [self checkExistence];
		if (b && !exists) {
			exists = YES;
			if (delegate && [delegate respondsToSelector:@selector(fileDidAppear:)])
				[delegate fileDidAppear:path];
			break;
		}
		else if (!b && exists) {
			exists = NO;
			if (delegate && [delegate respondsToSelector:@selector(fileDidDisappear:)])
				[delegate fileDidDisappear:path];
			break;
		}
		[NSThread sleepForTimeInterval:ival];
	}
}


@end