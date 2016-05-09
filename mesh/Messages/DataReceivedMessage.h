//
//  DataReceivedMessage.h
//

#import <Foundation/Foundation.h>
#import "MeshMessage.h"

@interface DataReceivedMessage : MeshMessage
@property uint32_t sendId;
@property(strong) NSData *publicKey;
@property(strong) NSData *contentData;

@end
