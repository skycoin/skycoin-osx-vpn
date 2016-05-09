//
//  MeshNode.m
//

#import "MeshNode.h"
#import "MeshMessage.h"

@interface MeshNode()
@property(strong) NSTask *nodeTask;
@property(strong) NSFileHandle *nodeWriter;
@property(strong) NSFileHandle *nodeReader;

@end

@implementation MeshNode

- (void)start {
    if(_nodeTask != nil) {
        return;
    }
    
    _nodeTask = [[NSTask alloc] init];
    _nodeTask.launchPath = [[NSBundle mainBundle] pathForResource:@"mesh" ofType:nil inDirectory:@"node-package"];
    _nodeTask.arguments = @[@"-config", [[NSBundle mainBundle] pathForResource:@"config" ofType:@"json" inDirectory:@"node-package"]];
    
    _nodeTask.terminationHandler = ^(NSTask *task) {
        _nodeWriter = nil;
        _nodeReader = nil;
        
        NSLog(@"Node exited");
    };
    
    NSPipe *stdErrPipe = [NSPipe pipe];
    
    stdErrPipe.fileHandleForReading.readabilityHandler = ^(NSFileHandle *readableHandle) {
        NSLog(@"----- Node output: %@", [[NSString alloc] initWithData:readableHandle.availableData encoding:NSASCIIStringEncoding]);
    };
    
    NSPipe *stdOutPipe = [NSPipe pipe];
    _nodeReader = stdOutPipe.fileHandleForReading;
    
    NSPipe *stdInPipe = [NSPipe pipe];
    _nodeWriter = stdInPipe.fileHandleForWriting;
    
    _nodeTask.standardError = stdErrPipe;
    _nodeTask.standardOutput = stdOutPipe;
    _nodeTask.standardInput = stdInPipe;
    
    [self processIncomingMessages];
    
    [_nodeTask launch];
}

- (void)stop {
    if(_nodeTask == nil) {
        return;
    }
    
    [_nodeTask terminate];
    _nodeTask = nil;
}

- (void)processIncomingMessages {
    dispatch_read(_nodeReader.fileDescriptor, 4, dispatch_get_main_queue(), ^(dispatch_data_t data, int error) {
        if(error != 0) {
            NSLog(@"Error reading from node: %s", strerror(error));
            return;
        }
        
        if(dispatch_data_get_size(data) == 0) {
            NSLog(@"EOF reading from node");
            return;
        }
        
        NSData *lengthData = (NSData *)data;
        
        int length = *(uint32_t *)[lengthData bytes];
        NSLog(@"Incoming message length: %i", length);
        
        dispatch_read(_nodeReader.fileDescriptor, length, dispatch_get_main_queue(), ^(dispatch_data_t data, int error) {
            if(error != 0) {
                NSLog(@"Error reading from node: %s", strerror(error));
                return;
            }
            
            if(dispatch_data_get_size(data) == 0) {
                NSLog(@"EOF reading from node");
                return;
            }
            
            NSData *messageContent = (NSData *)data;
            NSLog(@"Received message: %@", messageContent);
            
            MeshMessage *message = [MeshMessage messageWithData:messageContent];
            
            if(message != nil && _gotMessageHandler != nil) {
                NSLog(@"Handling message: %@", message);
                
                _gotMessageHandler(message);
            } else {
                NSLog(@"Ignoring message: %@", message);
            }
            
            [self performSelectorOnMainThread:@selector(processIncomingMessages) withObject:nil waitUntilDone:NO];
        });
    });
}

- (void)sendMessage:(MeshMessage *)message {
    if(_nodeWriter == nil) {
        NSLog(@"Dropping outgoing node message: %@", message);
        return;
    }
    
    NSData *serialized = [message serializedData];
    
    uint32_t length = (uint32_t)[serialized length];
    NSData *lengthData = [NSData dataWithBytes:&length length:sizeof(length)];
    NSLog(@"Sending message to node: %@%@", lengthData, serialized);
    [_nodeWriter writeData:lengthData];
    [_nodeWriter writeData:serialized];
}

@end
