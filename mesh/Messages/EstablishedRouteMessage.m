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
        if([data length] >= [super serializedLength] + sizeof(uint32_t))
        {
            const void *byteData = [data bytes] + [super serializedLength];
            _routeIndex = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
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
    return [NSString stringWithFormat:@"<EstablishedRouteMessage routeIndex:%u>", _routeIndex];
}

@end
