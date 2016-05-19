//
//  ViewController.m
//

#import "ViewController.h"

#import "AppDelegate.h"

@interface ViewController()
@end

@implementation ViewController


- (void)viewWillAppear {
    [super viewWillAppear];
    
    AppDelegate *appDelegate = [NSApplication sharedApplication].delegate;
    
    [NSApp activateIgnoringOtherApps:YES];
    
    NSLog(@"Displaying configuration URL: %@", appDelegate.configURL);
    [_webView.mainFrame loadRequest:[NSURLRequest requestWithURL:appDelegate.configURL]];
}

@end
