//
//  AppDelegate.m
//

#import "AppDelegate.h"

#import "NodeTunProtocol.h"
#import "PacketForwarder.h"

#import "MeshNode.h"
#import "SendDataMessage.h"
#import "DataReceivedMessage.h"

#include <ServiceManagement/ServiceManagement.h>

@interface AppDelegate ()
@property(strong) NSStatusItem *statusItem;
@property(strong) NSXPCConnection *connectionToService;
@property(strong) PacketForwarder *packetForwarder;
@property(strong) MeshNode *meshNode;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    _statusItem.menu = _statusMenu;
    _statusItem.image = [NSImage imageNamed:@"StatusBarIcon"];
    _statusItem.highlightMode = YES;
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_connectionToService invalidate];
    [_packetForwarder stop];
    [_meshNode stop];
    
    _statusItem = nil;
}

- (IBAction)installHelper:(id)sender {
    OSStatus                    err;
    
    AuthorizationRef authRef;
    AuthorizationItem authItem = { kSMRightBlessPrivilegedHelper, 0, NULL, 0 };
    AuthorizationRights authRights = { 1, &authItem };
    AuthorizationFlags flags = kAuthorizationFlagDefaults | kAuthorizationFlagInteractionAllowed | kAuthorizationFlagPreAuthorize | kAuthorizationFlagExtendRights;
    
    err = AuthorizationCreate(&authRights, kAuthorizationEmptyEnvironment, flags, &authRef);
    if(err != errAuthorizationSuccess)
    {
        NSLog(@"Not authorized to install helper");
        return;
    }
    
    Boolean success;
    CFErrorRef cfError;
    
    success = SMJobBless(kSMDomainSystemLaunchd, CFSTR("skycoin.nodetun"), authRef, &cfError);
    if(!success) {
        NSError *error = (__bridge NSError *) cfError;
        
        NSLog(@"Couldn't install helper: %@ %i (%@)", [error domain], (int)[error code], error);
    } else {
        NSLog(@"Helper installed");
        
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Installation successful";
        alert.informativeText = @"Mesh client installed successfully. Ready to connect.";
        [alert runModal];
    }
    
}

- (IBAction)connectOrDisconnect:(id)sender {
    if(_packetForwarder != nil) {
        // connected - disconnect here
        [_packetForwarder stop];
        _packetForwarder = nil;
        
        _connectOrDisconnectMenuItem.title = @"Connect";
        
        return;
    }
    
    _connectOrDisconnectMenuItem.title = @"Connecting...";
    
    if(_connectionToService == nil) {
        _connectionToService = [[NSXPCConnection alloc] initWithMachServiceName:@"skycoin.nodetun" options:NSXPCConnectionPrivileged];
        _connectionToService.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(NodeTunProtocol)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-retain-cycles"
        // We can ignore the retain cycle warning because a) the retain taken by the
        // invalidation handler block is released by us setting it to nil when the block
        // actually runs, and b) the retain taken by the block passed to -addOperationWithBlock:
        // will be released when that operation completes and the operation itself is deallocated
        // (notably self does not have a reference to the NSBlockOperation).
        _connectionToService.invalidationHandler = ^{
            NSLog(@"Lost connection to service");
            _connectionToService.invalidationHandler = nil;
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                _connectionToService = nil;
            }];
        };
#pragma clang diagnostic pop
        
        [_connectionToService resume];
    }
    
    id<NodeTunProtocol> proxy = [_connectionToService remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error connecting to XPC service: %@", error);
    }];
    
    [proxy getVersionWithReply:^(NSString *versionString) {
        NSLog(@"Connected to service version: %@", versionString);
    }];
    
    [proxy openTunFdWithReply:^(NSError *error, NSFileHandle *tunHandle, NSString *deviceName) {
        if(error != nil || tunHandle == nil) {
            NSLog(@"Couldn't open TUN device: %@", error);
            return;
        }
        
        NSLog(@"Created utun device %@", deviceName);
        
        _packetForwarder = [[PacketForwarder alloc] initWithFileHandle:tunHandle];
        _packetForwarder.gotPacketHandler = ^(NSData *packet) {
            NSLog(@"Got packet, sending to mesh node: %@", packet);
            [_meshNode sendMessage:[[SendDataMessage alloc] initWithRouteIndex:0 data:packet]];
        };
        
        [_packetForwarder start];
        
        [proxy configureInterface:deviceName localAddress:@"10.200.200.5" remoteAddress:@"10.200.200.1" subnetMask:@"255.255.255.0" withReply:^(int status) {
            if(status == 0) {
                NSLog(@"Assigned IP addresss");
            }
        }];
        
        _connectOrDisconnectMenuItem.title = @"Disconnect";
    }];
}

- (IBAction)startOrStopNode:(id)sender {
    if(_meshNode != nil) {
        [_meshNode stop];
        _meshNode = nil;
        
        _startOrStopMenuItem.title = @"Start mesh node";
        return;
    }
    
    _startOrStopMenuItem.title = @"Stop mesh node";
    
    _meshNode = [[MeshNode alloc] init];
    [_meshNode start];
    
    _meshNode.gotMessageHandler = ^(MeshMessage *message) {
        if([message isKindOfClass:[DataReceivedMessage class]]) {
            DataReceivedMessage *dataReceivedMessage = (DataReceivedMessage *)message;
            
            NSLog(@"Got data message, sending packet %@", dataReceivedMessage.contentData);
            [_packetForwarder sendPacketData:dataReceivedMessage.contentData];
        }
    };
}

@end
