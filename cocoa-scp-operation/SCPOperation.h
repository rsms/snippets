@class SCPOperationMonitor;

@interface SCPOperation : NSOperation {
	NSString *srcPath;
	NSString *dstHost; ///< Destination host i.e. "user@bar.host" or "bar.host"
	NSString *dstPath;
	NSTask *task;
	SCPOperationMonitor *monitor;
	id delegate;
	BOOL didInterruptTaskOnPurpose;
}
@property(assign) id delegate;
-(id)initWithSourcePath:(NSString *)s dstHost:(NSString *)dh dstPath:(NSString *)dp delegate:(id)de;
-(int)executeRemoteShellCommand:(NSString *)cmd;
@end

@protocol SCPOperationDelegate
-(void)fileTransmission:(SCPOperation *)op didSucceedForPath:(NSString *)path remoteURI:(NSString *)hostpath;
-(void)fileTransmission:(SCPOperation *)op didAbortForPath:(NSString *)path;
-(void)fileTransmission:(SCPOperation *)op didFailForPath:(NSString *)path reason:(NSError *)error;
@end

@interface SCPOperationMonitor : NSOperation {
	NSString *path; ///< Local path to watch
	NSTimeInterval ival;
	id delegate;
	BOOL initiallyExisted;
}
-(id)initWithPath:(NSString *)path checkInterval:(NSTimeInterval)ival delegate:(id)delegate;
-(BOOL)checkExistence;
@end

@protocol SCPOperationMonitorDelegate
-(void)fileDidDisappear:(NSString *)path;
-(void)fileDidAppear:(NSString *)path;
@end
