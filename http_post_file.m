//
//  HTTP POST file
//
//  Created by Rasmus Andersson on 2008-03-05.
//  Copyright Rasmus Andersson <http://hunch.se/> 2008. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
  id pool = [[NSAutoreleasePool alloc] init];
  
  NSString *filename = @"/mos.tiff";
  NSData *file = [NSData dataWithContentsOfFile:filename];
  NSURL *url = [NSURL URLWithString:@"http://localhost:8080/receive"];
  NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
  [req setHTTPMethod:@"POST"];
  [req setAllHTTPHeaderFields:[NSDictionary dictionaryWithObjectsAndKeys:
                               @"multipart/form-data; boundary=c4c58e7aebac3f0b665ff1ada63f0425", @"Content-Type",
                               NULL]];
  
  NSMutableData *data = [NSMutableData data];
  [data appendData:[[NSString stringWithFormat:@"--c4c58e7aebac3f0b665ff1ada63f0425\r\n"
                     @"Content-Disposition: form-data; name=\"FILE\"; filename=\"%@\"\r\n"
                     @"Content-Type: application/octet-stream\r\n"
                     @"Content-Transfer-Encoding: binary\r\n"
                     @"Content-Length: %d\r\n"
                     @"\r\n", [filename lastPathComponent], [file length]] dataUsingEncoding:NSUTF8StringEncoding]];
  [data appendData:file];
  [data appendData:[@"\r\n--c4c58e7aebac3f0b665ff1ada63f0425--\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
  [req setHTTPBody:data];
  
  NSURLResponse *rsp = nil;
  NSError *error;
  NSData *rsp_body = [NSURLConnection sendSynchronousRequest:req returningResponse:&rsp error:&error];
  
  if(rsp_body) {
    NSLog(@"Response length: %u", [rsp_body length]);
  } else {
    NSLog(@"Request failed: %@", [error description]);
  }
  
  [pool release];
  return 0;
}
