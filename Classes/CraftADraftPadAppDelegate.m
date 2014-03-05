//
//  CraftADraftPadAppDelegate.m
//  CraftADraftPad
//
//  Created by David Ehrmann on 4/29/10.
//  Copyright David Ehrmann 2010. All rights reserved.
//

#import "CraftADraftPadAppDelegate.h"
#import "EAGLView.h"
#import "CraftADraft.h"

@implementation CraftADraftPadAppDelegate

@synthesize window;
@synthesize glView;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions   
{
	[glView becomeFirstResponder];
    [glView startAnimation];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [glView stopAnimation];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [glView startAnimation];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
	[[CraftADraft sharedCraftADraft] saveScreens];
    [glView stopAnimation];
}

- (void)dealloc
{
    [window release];
    [glView release];

    [super dealloc];
}

@end
