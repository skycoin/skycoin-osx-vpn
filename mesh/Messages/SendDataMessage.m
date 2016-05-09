//
//  SendDataMessage.m
//

#import "SendDataMessage.h"

@implementation SendDataMessage

- (instancetype)initWithRouteIndex:(uint32_t)routeIndex data:(NSData *)data {
    if(self = [super init]) {
        self.typeCode = 1;
        _routeIndex = routeIndex;
        _contentData = data;
    }
    return self;
}

- (size_t)serializedLength {
    return [super serializedLength] + sizeof(uint32_t) + sizeof(uint32_t) + [_contentData length];
}

- (void)serializeIntoBuffer:(void *)buffer {
    [super serializeIntoBuffer:buffer];
    
    void *outBytes = buffer + [super serializedLength];
    
    *(uint32_t *)outBytes = _routeIndex;
    outBytes += sizeof(uint32_t);
    
    *(uint32_t *)outBytes = (uint32_t)[_contentData length];
    outBytes += sizeof(uint32_t);
    
    [_contentData getBytes:outBytes length:[_contentData length]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<SendDataMessage routeIndex:%u contentData:%@>", _routeIndex, _contentData];
}

@end
