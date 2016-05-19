//
//  SendDataMessage.m
//

#import "SendDataMessage.h"

@implementation SendDataMessage

- (instancetype)initWithRouteID:(NSString *)routeID data:(NSData *)data {
    if(self = [super init]) {
        self.typeCode = 1;
        _routeID = routeID;
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
    
    [self encodeHexString:_routeID intoBuffer:outBytes fixedLengthInBytes:MeshMessageRouteIDLength];
    outBytes += MeshMessageRouteIDLength;
    
    *(uint32_t *)outBytes = (uint32_t)[_contentData length];
    outBytes += sizeof(uint32_t);
    
    [_contentData getBytes:outBytes length:[_contentData length]];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<SendDataMessage routeID:%@ contentData:%@>", _routeID, _contentData];
}

@end
