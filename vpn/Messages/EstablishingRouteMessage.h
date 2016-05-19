//
//  EstablishingRouteMessage.h
//

#import <Foundation/Foundation.h>
#import "MeshMessage.h"

@interface EstablishingRouteMessage : MeshMessage
@property NSString *routeID;
@property uint32_t hopIndex;

@end
