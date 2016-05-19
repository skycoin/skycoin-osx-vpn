//
//  SendDataMessage.h
//

#import "MeshMessage.h"

@interface SendDataMessage : MeshMessage
@property NSString *routeID;
@property NSData *contentData;

- (instancetype)initWithRouteID:(NSString *)routeID data:(NSData *)data;

@end
