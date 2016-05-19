//
//  EstablishedRouteMessage.m
//

#import "EstablishedRouteMessage.h"

@implementation EstablishedRouteMessage

+ (void)load {
    [MeshMessage registerMessageClass:[EstablishedRouteMessage class] forCode:5];
}

- (instancetype)initWithData:(NSData *)data {
    if(self = [super initWithData:data]) {
        if([data length] >= [super serializedLength] + MeshMessageRouteIDLength)
        {
            const void *byteData = [data bytes] + [super serializedLength];
            _routeID = [self decodeHexStringFromBuffer:byteData fixedLengthInBytes:MeshMessageRouteIDLength];
            byteData += MeshMessageRouteIDLength;
        }
        else
        {
            NSLog(@"Malformed EstablishedRouteMessage, too short");
            return nil;
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<EstablishedRouteMessage routeID:%@>", _routeID];
}

@end
