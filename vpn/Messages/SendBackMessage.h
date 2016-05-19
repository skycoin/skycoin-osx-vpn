//
//  SendBackMessage.h
//

#import "MeshMessage.h"

@interface SendBackMessage : MeshMessage
@property uint32_t sendId;
@property NSData *publicKey;
@property NSData *contentData;

- (instancetype)initWithSendId:(uint32_t)sendId publicKey:(NSData *)publicKey contentData:(NSData *)contentData;

@end
