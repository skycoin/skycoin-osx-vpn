//
//  main.m
//

#import <Foundation/Foundation.h>
#import "NodeTun.h"

@interface ServiceDelegate : NSObject <NSXPCListenerDelegate>
@end

@implementation ServiceDelegate

- (BOOL)listener:(NSXPCListener *)listener shouldAcceptNewConnection:(NSXPCConnection *)newConnection {
    NSLog(@"Skycoin utun host process accepted connect");
    
    // This method is where the NSXPCListener configures, accepts, and resumes a new incoming NSXPCConnection.
    
    // Configure the connection.
    // First, set the interface that the exported object implements.
    newConnection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(NodeTunProtocol)];
    
    // Next, set the object that the connection exports. All messages sent on the connection to this service will be sent to the exported object to handle. The connection retains the exported object.
    NodeTun *exportedObject = [NodeTun new];
    newConnection.exportedObject = exportedObject;
    
    // Resuming the connection allows the system to deliver more incoming messages.
    [newConnection resume];
    
    // Returning YES from this method tells the system that you have accepted this connection. If you want to reject the connection for some reason, call -invalidate on the connection and return NO.
    return YES;
}

@end

int main(int argc, const char *argv[])
{
    @autoreleasepool {
        NSLog(@"Skycoin utun host process created");
        
        // Create the delegate for the service.
        ServiceDelegate *delegate = [ServiceDelegate new];
        
        // Set up the one NSXPCListener for this service. It will handle all incoming connections.
        NSXPCListener *listener = [[NSXPCListener alloc] initWithMachServiceName:@"skycoin.nodetun"];
        listener.delegate = delegate;
        
        // Resuming the serviceListener starts this service. This method does not return.
        [listener resume];
        [[NSRunLoop currentRunLoop] run];
        
        NSLog(@"Skycoin utun host process clean exit");
    }
    return 0;
}
