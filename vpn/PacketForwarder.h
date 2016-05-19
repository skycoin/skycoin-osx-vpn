//
//  PacketForwarder.h
//

#import <Foundation/Foundation.h>

@interface PacketForwarder : NSObject
@property (copy) void (^gotPacketHandler)(NSData * packetData);

- (instancetype)initWithFileHandle:(NSFileHandle *)utunFh;

- (void)start;
- (void)stop;

- (void)sendPacketData:(NSData *)packetData;

@end
