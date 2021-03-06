//
//  EstablishedRouteErrorMessage.m
//

#import "EstablishedRouteErrorMessage.h"

@implementation EstablishedRouteErrorMessage

+ (void)load {
    [MeshMessage registerMessageClass:[EstablishedRouteErrorMessage class] forCode:6];
}

- (instancetype)initWithData:(NSData *)data {
    if(self = [super initWithData:data]) {
        if([data length] >= [super serializedLength] + sizeof(uint32_t) + sizeof(uint32_t) + sizeof(uint32_t))
        {
            const void *byteData = [data bytes] + [super serializedLength];

            _routeID = [self decodeHexStringFromBuffer:byteData fixedLengthInBytes:MeshMessageRouteIDLength];
            byteData += MeshMessageRouteIDLength;
            
            _hopIndex = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
            
            uint32_t errorMessageLength = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
            
            unsigned long stringLength = MIN(errorMessageLength, [data length] - (byteData - [data bytes]));
            
            if(stringLength != errorMessageLength) {
                NSLog(@"Malformed EstablishedRouteErrorMessage, too short");
                return nil;
            }
            
            _message = [[NSString alloc] initWithData:[NSData dataWithBytes:byteData length:stringLength] encoding:NSUTF8StringEncoding];
        }
        else
        {
            NSLog(@"Malformed EstablishedRouteErrorMessage, too short");
            return nil;            
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<EstablishedRouteErrorMessage routeID:%@ hop:%u message:'%@'>", _routeID, (unsigned)_hopIndex, _message];
}

@end
