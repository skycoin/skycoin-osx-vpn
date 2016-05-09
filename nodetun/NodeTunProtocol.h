//
//  nodetunProtocol.h
//

#import <Foundation/Foundation.h>

@protocol NodeTunProtocol

- (void)getVersionWithReply:(void(^)(NSString * version))reply;
- (void)openTunFdWithReply:(void(^)(NSError * error, NSFileHandle *tunHandle, NSString *deviceName))reply;
- (void)configureInterface:(NSString *)interface localAddress:(NSString *)localIP remoteAddress:(NSString *)remoteIP subnetMask:(NSString *)subnetMask withReply:(void(^)(int status))reply;

@end
