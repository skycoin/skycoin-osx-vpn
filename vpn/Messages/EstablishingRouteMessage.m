//
//  EstablishingRouteMessage.m
//

#import "EstablishingRouteMessage.h"

@implementation EstablishingRouteMessage

+ (void)load {
    [MeshMessage registerMessageClass:[EstablishingRouteMessage class] forCode:4];
}

- (instancetype)initWithData:(NSData *)data {
    if(self = [super initWithData:data]) {
        if([data length] >= [super serializedLength] + MeshMessageRouteIDLength + sizeof(uint32_t))
        {
            const void *byteData = [data bytes] + [super serializedLength];
            _routeID = [self decodeHexStringFromBuffer:byteData fixedLengthInBytes:MeshMessageRouteIDLength];
            byteData += MeshMessageRouteIDLength;
            
            _hopIndex = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
        }
        else
        {
            NSLog(@"Malformed EstablishingRouteMessage, too short");
            return nil;
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<EstablishingRouteMessage routeID:%@ hopIndex:%u>", _routeID, _hopIndex];
}

@end
