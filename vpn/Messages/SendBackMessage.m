//
//  SendBackMessage.m
//

#import "SendBackMessage.h"

@implementation SendBackMessage

- (instancetype)initWithSendId:(uint32_t)sendId publicKey:(NSData *)publicKey contentData:(NSData *)contentData {
    if(self = [super init]) {
        self.typeCode = 2;
        _sendId = sendId;
        _publicKey = publicKey;
        _contentData = contentData;
    }
    return self;
}

- (size_t)serializedLength {
    return [super serializedLength] + sizeof(uint32_t) + 33 + sizeof(uint32_t) + [_contentData length];
}

- (void)serializeIntoBuffer:(void *)buffer {
    [super serializeIntoBuffer:buffer];
    
    void *outBytes = buffer + [super serializedLength];
    
    *(uint32_t *)outBytes = _sendId;
    outBytes += sizeof(uint32_t);
    
    [_publicKey getBytes:outBytes length:33];
    outBytes += 33;
    
    *(uint32_t *)outBytes = ntohl((uint32_t)[_contentData length]);
    outBytes += sizeof(uint32_t);
    
    [_contentData getBytes:outBytes length:[_contentData length]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<SendBackMessage sendId:%u publicKey:%@ contentData:%@>", _sendId, _publicKey, _contentData];
}

@end
