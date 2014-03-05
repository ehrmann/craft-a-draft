//
//  DrawScreen.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/4/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Screen.h"
#import "MenuListener.h"

@class WheelControl;
@class Menu;
@class ScreenSelector;

@interface DrawScreen : Screen <MenuListener> {

	UITouch *_menuTouch;
	UITouch *_topTouch;
	UITouch *_selectorTouch;
	UITouch *_xTouch;
	UITouch *_yTouch;
	
	WheelControl *_xWheel;
	WheelControl *_yWheel;
	
	CGPoint _topLocation;
	
	BOOL _menuVisible;
	Menu *_menu;
	ScreenSelector *_screenSelector;
	
	Texture2D *_xWheelTexture;
	Texture2D *_yWheelTexture;	
}

-(id)initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn;

@end
