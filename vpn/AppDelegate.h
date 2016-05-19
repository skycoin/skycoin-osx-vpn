//
//  AppDelegate.h
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) IBOutlet NSMenu *statusMenu;
@property(strong) IBOutlet NSMenu *routesMenu;
@property(strong) IBOutlet NSMenuItem *noRoutesMenuItem;
@property(strong) IBOutlet NSMenuItem *connectedToMenuItem;
@property(strong) IBOutlet NSMenuItem *connectMenuItem;
@property(strong) IBOutlet NSMenuItem *disconnectMenuItem;
@property(strong) NSURL *configURL;

- (IBAction)connectRoute:(id)sender;
- (IBAction)disconnect:(id)sender;
- (IBAction)installHelper:(id)sender;
- (IBAction)uninstallHelper:(id)sender;

@end

