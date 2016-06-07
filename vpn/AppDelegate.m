//
//  AppDelegate.m
//

#import "AppDelegate.h"

#import "NodeTunProtocol.h"
#import "PacketForwarder.h"

#import "MeshNode.h"
#import "SendDataMessage.h"
#import "DataReceivedMessage.h"
#import "ConfigURLMessage.h"
#import "RoutesChangedMessage.h"
#import "EstablishedRouteMessage.h"
#import "EstablishedRouteErrorMessage.h"
#import "EstablishingRouteMessage.h"

#include <ServiceManagement/ServiceManagement.h>

@interface AppDelegate ()
@property(strong) NSStatusItem *statusItem;
@property(strong) NSXPCConnection *connectionToService;
@property(strong) PacketForwarder *packetForwarder;
@property(strong) MeshNode *meshNode;
@property(strong) NSString *connectedToRouteID;
@property(strong) id<NodeTunProtocol> serviceProxy;
@property BOOL connectAfterInstall;
@property(strong) NSArray *menuRouteIDs;
@property(strong) NSDictionary *routeIDsToNames;

- (void)connected;
- (void)disconnected;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    _configURL = [NSURL URLWithString:@"https://github.com/skycoin/skycoin"];
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength];
    
    _statusItem.menu = _statusMenu;
    _statusItem.image = [NSImage imageNamed:@"StatusBarIcon"];
    _statusItem.highlightMode = YES;
    
    _meshNode = [[MeshNode alloc] init];
    [_meshNode start];
    
    _meshNode.gotMessageHandler = ^(MeshMessage *message) {
        if([message isKindOfClass:[DataReceivedMessage class]]) {
            DataReceivedMessage *dataReceivedMessage = (DataReceivedMessage *)message;
            
            if(_packetForwarder != nil) {
                NSLog(@"Got data message, sending packet %@", dataReceivedMessage.contentData);
                [_packetForwarder sendPacketData:dataReceivedMessage.contentData];
            } else {
                NSLog(@"Packet received without node connected, dropping.");
            }
        } else if([message isKindOfClass:[ConfigURLMessage class]]) {
            ConfigURLMessage *configMessage = (ConfigURLMessage *)message;
            
            _configURL = [NSURL URLWithString:configMessage.configURL];
        } else if([message isKindOfClass:[RoutesChangedMessage class]]) {
            RoutesChangedMessage *routesMessage = (RoutesChangedMessage *)message;
            
            NSLog(@"Got routes: %@", routesMessage.routeIDsToNames);
            
            [_routesMenu removeAllItems];
            
            if([routesMessage.routeIDsToNames count] == 0) {
                [_routesMenu addItem:_noRoutesMenuItem];
                
                _menuRouteIDs = nil;
            } else {
                NSMutableArray *menuRouteIDs = [NSMutableArray arrayWithCapacity:[routesMessage.routeIDsToNames count]];
                
                [routesMessage.routeIDsToNames enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull routeID, NSString * _Nonnull name, BOOL * _Nonnull stop) {
                    NSMenuItem *item = [_routesMenu addItemWithTitle:name action:@selector(connectRoute:) keyEquivalent:@""];
                    item.target = self;
                    item.tag = [menuRouteIDs count];
                    item.image = [NSImage imageNamed:@"yellow"];
                    [menuRouteIDs addObject:routeID];
                }];
                
                _routeIDsToNames = routesMessage.routeIDsToNames;
                _menuRouteIDs = menuRouteIDs;
            }
        } else if([message isKindOfClass:[EstablishingRouteMessage class]]) {
            EstablishingRouteMessage *routeMessage = (EstablishingRouteMessage *)message;
            
            for(NSUInteger i = 0; i < _menuRouteIDs.count; i++) {
                if([[_menuRouteIDs objectAtIndex:i] isEqualToString:routeMessage.routeID]) {
                    [[_routesMenu itemAtIndex:i] setImage:[NSImage imageNamed:@"yellow"]];
                }
            }
        } else if([message isKindOfClass:[EstablishedRouteMessage class]]) {
            EstablishedRouteMessage *routeMessage = (EstablishedRouteMessage *)message;
            
            for(NSUInteger i = 0; i < _menuRouteIDs.count; i++) {
                if([[_menuRouteIDs objectAtIndex:i] isEqualToString:routeMessage.routeID]) {
                    [[_routesMenu itemAtIndex:i] setImage:[NSImage imageNamed:@"green"]];
                }
            }
        } else if([message isKindOfClass:[EstablishedRouteErrorMessage class]]) {
            EstablishedRouteErrorMessage *routeErrorMessage = (EstablishedRouteErrorMessage *)message;
            
            for(NSUInteger i = 0; i < _menuRouteIDs.count; i++) {
                if([[_menuRouteIDs objectAtIndex:i] isEqualToString:routeErrorMessage.routeID]) {
                    [[_routesMenu itemAtIndex:i] setImage:[NSImage imageNamed:@"red"]];
                }
            }
        }
    };
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    [_connectionToService invalidate];
    [_packetForwarder stop];
    [_meshNode stop];
    
    _statusItem = nil;
}

- (IBAction)installHelper:(id)sender {
    OSStatus                    err;
    
    [NSApp activateIgnoringOtherApps:YES];
    
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
        [[NSAlert alertWithError:error] runModal];
        
        _connectAfterInstall = NO;
    } else {
        NSLog(@"Helper installed");
        
        if(_connectAfterInstall) {
            _connectAfterInstall = NO;
            
            [self connectRoute:sender];
        } else {
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Installation successful";
            alert.informativeText = @"VPN client installed successfully. Ready to connect.";
            [alert runModal];
        }
    }
}

- (IBAction)uninstallHelper:(id)sender {
    [self connectServiceWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error connecting to XPC service: %@", error);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSApp activateIgnoringOtherApps:YES];
            
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Client not installed";
            alert.informativeText = @"VPN client is not currently installed.";
            [alert runModal];
        });
    }];
    
    [_serviceProxy uninstallWithReply:^(int status) {
        NSLog(@"Deletion exit status: %i", status);
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        OSStatus                    err;
        
        [NSApp activateIgnoringOtherApps:YES];
        
        AuthorizationRef authRef;
        AuthorizationItem authItem = { kSMRightModifySystemDaemons, 0, NULL, 0 };
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
        
        success = SMJobRemove(kSMDomainSystemLaunchd, CFSTR("skycoin.nodetun"), authRef, YES, &cfError);
        if(!success) {
            NSError *error = (__bridge NSError *) cfError;
            
            NSLog(@"Couldn't uninstall helper: %@ %i (%@)", [error domain], (int)[error code], error);
            [[NSAlert alertWithError:error] runModal];
        } else {
            NSLog(@"Helper uninstalled");
            
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"Uninstallation successful";
            alert.informativeText = @"VPN client uninstalled successfully.";
            [alert runModal];
        }
    });
}

- (IBAction)disconnect:(id)sender {
    if(_packetForwarder != nil) {
        [_packetForwarder stop];
        _packetForwarder = nil;
    }
    
    [self disconnected];
}

- (IBAction)connectRoute:(id)sender {
    NSMenuItem *menuItem = sender;
    
    _connectedToRouteID = [_menuRouteIDs objectAtIndex:menuItem.tag];
    
    if(_packetForwarder != nil) {
        // connected - disconnect here
        [_packetForwarder stop];
        _packetForwarder = nil;
        
        return;
    }
    
    [self connectServiceWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Error connecting to XPC service: %@", error);
        
        if([error.domain isEqualToString:NSCocoaErrorDomain] && error.code == 4099) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            _connectAfterInstall = YES;
            [self installHelper:sender];
        });
    }];
    
    [_serviceProxy getVersionWithReply:^(NSString *versionString) {
        NSLog(@"Connected to service version: %@", versionString);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            NSString *ourVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
            
            if(![versionString isEqualToString:ourVersion]) {
                NSLog(@"Outdated service, upgrading...");
                
                _connectAfterInstall = YES;
                [self installHelper:sender];
                
                return;
            }
            
            [_serviceProxy openTunFdWithReply:^(NSError *error, NSFileHandle *tunHandle, NSString *deviceName) {
                if(error != nil || tunHandle == nil) {
                    NSLog(@"Couldn't open TUN device: %@", error);
                    return;
                }
                
                NSLog(@"Created utun device %@", deviceName);
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    _packetForwarder = [[PacketForwarder alloc] initWithFileHandle:tunHandle];
                    _packetForwarder.gotPacketHandler = ^(NSData *packet) {
                        NSLog(@"Got packet, sending to mesh node: %@", packet);
                        [_meshNode sendMessage:[[SendDataMessage alloc] initWithRouteID:_connectedToRouteID data:packet]];
                    };
                    
                    [_packetForwarder start];
                    
                    [_serviceProxy configureInterface:deviceName localAddress:@"10.200.200.5" remoteAddress:@"10.200.200.1" subnetMask:@"255.255.255.255" withReply:^(int status) {
                        if(status == 0) {
                            NSLog(@"Assigned IP addresss, configuring route");
                            
                            [_serviceProxy addDefaultRoute:deviceName remoteAddress:@"10.200.200.1" withReply:^(int status) {
                                if(status == 0) {
                                    NSLog(@"Default route configured");
                                } else {
                                    NSLog(@"Couldn't set default route");
                                }
                            }];
                        } else {
                            NSLog(@"Couldn't set IP address");
                        }
                    }];
                    
                    [self connected];
                });
                
            }];
        });
    }];
}

- (void)connectServiceWithErrorHandler:(void (^)(NSError *error))handler {
    if(_connectionToService != nil) {
        return;
    }
    
    NSDictionary *jobDictionary = CFBridgingRelease(SMJobCopyDictionary(kSMDomainSystemLaunchd, CFSTR("skycoin.nodetun")));
    
    if(!jobDictionary) {
        NSLog(@"Service not installed");
        handler(nil);
        return;
    } else {
        NSLog(@"Service found: %@", jobDictionary);
    }
    
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
    
    _serviceProxy = [_connectionToService remoteObjectProxyWithErrorHandler:[handler copy]];
}

- (void)connected {
    _disconnectMenuItem.hidden = NO;
    _connectMenuItem.hidden = YES;
    
    if(_connectedToRouteID != nil) {
        _connectedToMenuItem.title = [NSString stringWithFormat:@"Connected to %@", [_routeIDsToNames objectForKey:_connectedToRouteID]];
        _connectedToMenuItem.hidden = NO;
    } else {
        _connectedToMenuItem.hidden = YES;
    }
}

- (void)disconnected {
    _disconnectMenuItem.hidden = YES;
    _connectedToMenuItem.hidden = YES;
    
    _connectMenuItem.hidden = NO;
}

@end
