//
//  EstablishedRouteErrorMessage.h
//

#import <Foundation/Foundation.h>
#import "MeshMessage.h"

@interface EstablishedRouteErrorMessage : MeshMessage
@property uint32_t routeIndex;
@property uint8_t hopIndex;
@property(strong) NSString *message;

@end
