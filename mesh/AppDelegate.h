//
//  AppDelegate.h
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property(strong) IBOutlet NSMenu *statusMenu;
@property(weak) IBOutlet NSMenuItem *connectOrDisconnectMenuItem;
@property(weak) IBOutlet NSMenuItem *startOrStopMenuItem;

- (IBAction)connectOrDisconnect:(id)sender;
- (IBAction)startOrStopNode:(id)sender;
- (IBAction)installHelper:(id)sender;

@end

