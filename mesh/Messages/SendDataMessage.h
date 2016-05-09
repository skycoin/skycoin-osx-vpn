//
//  SendDataMessage.h
//

#import "MeshMessage.h"

@interface SendDataMessage : MeshMessage
@property uint32_t routeIndex;
@property NSData *contentData;

- (instancetype)initWithRouteIndex:(uint32_t)routeIndex data:(NSData *)data;

@end
