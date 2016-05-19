//
//  EstablishedRouteErrorMessage.h
//

#import <Foundation/Foundation.h>
#import "MeshMessage.h"

@interface EstablishedRouteErrorMessage : MeshMessage
@property NSString *routeID;
@property uint32_t hopIndex;
@property(strong) NSString *message;

@end
