//
//  TimeScreen.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/1/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Screen.h"
#import "MenuListener.h"
#import "WheelControlListener.h"

@class Menu;
@class WheelControl;
@class Texture2D;
@class CraftADraftLisender;

@interface TimeScreen : Screen <MenuListener, WheelControlListener> {
	Menu *_menu;
	WheelControl *_wheel;
	Texture2D *_wheelTexture;
	
	UITouch *_wheelTouch;
	UITouch *_menuTouch;
	
	BOOL _menuVisible;
}

-(id)initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn;

@end
