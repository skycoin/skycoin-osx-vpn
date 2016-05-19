//
//  GeneralErrorMessage.m
//

#import "GeneralErrorMessage.h"

@implementation GeneralErrorMessage

+ (void)load {
    [MeshMessage registerMessageClass:[GeneralErrorMessage class] forCode:7];
}

- (instancetype)initWithData:(NSData *)data {
    if(self = [super initWithData:data]) { // will parse the front type byte
        if([data length] >= [super serializedLength] + sizeof(uint32_t)) // now our bytes
        {
            const void *byteData = [data bytes] + [super serializedLength];
            uint32_t errorMessageLength = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
            unsigned long stringLength = MIN(errorMessageLength, [data length] - (byteData - [data bytes]));
            
            if(stringLength != errorMessageLength) {
                NSLog(@"Malformed GeneralErrorMessage, too short");
                return nil;
            }
            
            _message = [[NSString alloc] initWithData:[NSData dataWithBytes:byteData length:stringLength] encoding:NSUTF8StringEncoding];
        }
        else
        {
            NSLog(@"Malformed GeneralErrorMessage, too short");
            return nil;            
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<GeneralErrorMessage message:'%@'>", _message];
}

@end
