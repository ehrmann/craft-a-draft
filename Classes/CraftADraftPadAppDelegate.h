//
//  CraftADraftPadAppDelegate.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 4/29/10.
//  Copyright David Ehrmann 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class EAGLView;

@interface CraftADraftPadAppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    EAGLView *glView;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) IBOutlet EAGLView *glView;

@end

