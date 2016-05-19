//
//  RoutesChangedMessage.m
//

#import "RoutesChangedMessage.h"

@implementation RoutesChangedMessage

+ (void)load {
    [MeshMessage registerMessageClass:[RoutesChangedMessage class] forCode:8];
}

- (instancetype)initWithData:(NSData *)data {
    if(self = [super initWithData:data]) {
        if([data length] >= [super serializedLength] + sizeof(uint32_t) + sizeof(uint32_t))
        {
            const void *byteData = [data bytes] + [super serializedLength];
            
            uint32_t numNameStrings = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
            
            NSMutableArray *nameStringsArray = [NSMutableArray arrayWithCapacity:numNameStrings];
            
            for(uint32_t i = 0; i < numNameStrings; i++) {
                uint32_t stringLength = *(uint32_t *)byteData;
                byteData += sizeof(uint32_t);

                unsigned long readLength = MIN(stringLength, [data length] - (byteData - [data bytes]));
                if(stringLength != readLength) {
                    NSLog(@"Malformed RoutesChangedMessage, too short");
                    return nil;
                }
                
                [nameStringsArray addObject:[[NSString alloc] initWithBytes:byteData length:readLength encoding:NSUTF8StringEncoding]];
                byteData += readLength;
            }
            
            if(([data length] - (byteData - [data bytes])) < sizeof(uint32_t)) {
                NSLog(@"Malformed RoutesChangedMessage, too short");
                return nil;
            }
               
            uint32_t numRouteIDs = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
            
            NSMutableArray *routeIDStringsArray = [NSMutableArray arrayWithCapacity:numNameStrings];
            
            for(uint32_t i = 0; i < numRouteIDs; i++) {
                if(([data length] - (byteData - [data bytes])) < MeshMessageRouteIDLength) {
                    NSLog(@"Malformed RoutesChangedMessage, too short");
                    return nil;
                }
                
                [routeIDStringsArray addObject:[self decodeHexStringFromBuffer:byteData fixedLengthInBytes:MeshMessageRouteIDLength]];
                
                byteData += MeshMessageRouteIDLength;
            }
            
            if(numRouteIDs != numNameStrings) {
                NSLog(@"Malformed RoutesChangedMessage, not equal number of names and route ids");
                return nil;
            }
            
            _routeIDsToNames = [NSMutableDictionary dictionary];
            
            for (NSUInteger i = 0; i < [nameStringsArray count]; i++) {
                [_routeIDsToNames setValue:[nameStringsArray objectAtIndex:i] forKey:[routeIDStringsArray objectAtIndex:i]];
            }
        }
        else
        {
            NSLog(@"Malformed RoutesChangedMessage, too short");
            return nil;
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<RoutesChangedMessage routeIDsToNames:%@>", _routeIDsToNames];
}

@end
