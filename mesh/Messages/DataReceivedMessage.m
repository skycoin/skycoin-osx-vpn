//
//  DataReceivedMessage.m
//

#import "DataReceivedMessage.h"

@implementation DataReceivedMessage

+ (void)load {
    [MeshMessage registerMessageClass:[DataReceivedMessage class] forCode:3];
}

- (instancetype)initWithData:(NSData *)data {
    if(self = [super initWithData:data]) {
        if([data length] >= [super serializedLength] + sizeof(uint32_t) + 33 + sizeof(uint32_t))
        {
            const void *byteData = [data bytes] + [super serializedLength];
            
            _sendId = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
            
            _publicKey = [NSData dataWithBytes:byteData length:33];
            byteData += 33;
            
            uint32_t contentLength = *(uint32_t *)byteData;
            byteData += sizeof(uint32_t);
            
            unsigned long readLength = MIN(contentLength, [data length] - (byteData - [data bytes]));
            
            if(contentLength != readLength) {
                NSLog(@"Malformed DataReceivedMessage, too short");
                return nil;
            }
            
            _contentData = [NSData dataWithBytes:byteData length:readLength];
        }
        else
        {
            NSLog(@"Malformed DataReceivedMessage, too short");
            return nil;
        }
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<DataReceivedMessage sendId:%u publicKey:%@ contentData:%@>", _sendId, _publicKey, _contentData];
}

@end
