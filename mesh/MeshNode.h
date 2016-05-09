//
//  MeshNode.h
//

#import <Foundation/Foundation.h>

@class MeshMessage;

@interface MeshNode : NSObject
@property (copy) void (^gotMessageHandler)(MeshMessage *message);

- (void)start;
- (void)stop;

- (void)sendMessage:(MeshMessage *)message;

@end
