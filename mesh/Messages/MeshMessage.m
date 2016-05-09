//
//  MeshMessage.m
//

#import "MeshMessage.h"

static NSMutableDictionary *messageClasses;

@implementation MeshMessage

+ (void)registerMessageClass:(Class)clazz forCode:(uint8_t)typeCode {
    if(messageClasses == nil) {
        messageClasses = [[NSMutableDictionary alloc] init];
    }
    
    [messageClasses setObject:clazz forKey:[NSNumber numberWithUnsignedChar:typeCode]];
}

+ (instancetype)messageWithData:(NSData *)data {
    uint8_t typeCode = *(uint8_t *)[data bytes];
    
    Class messageClass = [messageClasses objectForKey:[NSNumber numberWithUnsignedChar:typeCode]];
    if(messageClass == nil) {
        NSLog(@"Don't understand message type %i", (int)typeCode);
        return nil;
    }
    
    NSLog(@"Parsing %@", messageClass);
    
    return [[messageClass alloc] initWithData:data];
}

- (instancetype)init {
    if(self = [self initWithData:nil]) {
    }
    return self;
}

- (instancetype)initWithData:(NSData *)data {
    if(self = [super init]) {
        if([data length] >= 1) {
            _typeCode = *(uint8_t *)[data bytes];
            NSLog(@"MeshMessage type: %i", (int)_typeCode);
        }
    }
    
    return self;
}

- (size_t)serializedLength {
    return sizeof(uint8_t);
}

- (void)serializeIntoBuffer:(void *)buffer {
    *(uint8_t *)buffer = _typeCode;
}

- (NSData *)serializedData {
    NSMutableData *data = [NSMutableData dataWithLength:[self serializedLength]];
    [self serializeIntoBuffer:[data mutableBytes]];
    return [NSData dataWithData:data];
}

@end
