//
//  RoutesChangedMessage.h
//

#import "MeshMessage.h"

@interface RoutesChangedMessage : MeshMessage
@property NSDictionary *routeIDsToNames;

@end
