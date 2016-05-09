//
//  MeshMessage.h
//

#import <Foundation/Foundation.h>

@interface MeshMessage : NSObject
@property uint8_t typeCode;

+ (void)registerMessageClass:(Class)clazz forCode:(uint8_t)typeCode;

+ (MeshMessage *)messageWithData:(NSData *)data;

- (instancetype)initWithData:(NSData *)data;
- (instancetype)init;

- (NSData *)serializedData;

- (size_t)serializedLength;
- (void)serializeIntoBuffer:(void *)buffer;

@end
