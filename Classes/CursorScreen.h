//
//  CursorScreen.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/1/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Screen.h"
#import "MenuListener.h"
#import "WheelControlListener.h"

@class WheelControl;
@class Texture2D;
@class Menu;
@class CursorOverlay;

@interface CursorScreen : Screen <MenuListener, WheelControlListener> {
	
	UITouch *_menuTouch;
	UITouch *_topTouch;
	UITouch *_xTouch;
	UITouch *_yTouch;
	
	WheelControl *_xWheel;
	WheelControl *_yWheel;
	
	float _bufferedXTheta;
	float _bufferedYTheta;
	
	BOOL _menuVisible;
	Menu *_menu;
	
	CursorOverlay *_cursorOverlay;
	
	Texture2D *_xWheelTexture;
	Texture2D *_yWheelTexture;
}

-(id)initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn;

@end
