//
//  PacketForwarder.m
//

#import <Foundation/Foundation.h>

#import "PacketForwarder.h"

@interface PacketForwarder()
@property(strong) NSFileHandle *utunFh;

@end

@implementation PacketForwarder

- (instancetype)initWithFileHandle:(NSFileHandle *)utunFh {
    if(self = [super init]) {
        _utunFh = utunFh;
    }
    return self;
}

- (void)start {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
    // we can ignore the retain cycle because it will be broken when -stop is called
    _utunFh.readabilityHandler = ^(NSFileHandle *fh) {
        NSData *packetData = [fh availableData];
        
        if(_gotPacketHandler != nil) {
            _gotPacketHandler(packetData);
        } else {
            NSLog(@"Dropped packet: %@", packetData);
        }
    };
#pragma clang diagnostic pop
}

- (void)stop {
    _utunFh.readabilityHandler = nil;
}

- (void)sendPacketData:(NSData *)packetData {
    [_utunFh writeData:packetData];
}

- (void)dealloc {
    [self stop];
}

@end