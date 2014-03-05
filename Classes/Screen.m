//
//  Screen.m
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/4/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "DrawScreen.h"

#import "Menu.h"
#import "ScreenSelector.h"
#import "WheelControl.h"
#import "UiConstants.h"
#import "Texture2D.h"
#import "CraftADraftListener.h"

Texture2D *_drawIcon = nil;
Texture2D *_cameraIcon = nil;
Texture2D *_cursorIcon = nil;
Texture2D *_clockIcon = nil;

@implementation Screen 

- (id)initWithSize:(CGSize)size {
	_width = size.width;
	_height = size.height;
	
	if (_drawIcon == nil) {
		_drawIcon = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"draw_icon.png"]];
	} else {
		[_drawIcon retain];
	}
	
	if (_cameraIcon == nil) {
		_cameraIcon = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"camera_icon.png"]];
	} else {
		[_cameraIcon retain];
	}
	
	if (_clockIcon == nil) {
		_clockIcon = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"clock_icon.png"]];
	} else {
		[_clockIcon retain];
	}
	
	if (_cursorIcon == nil) {
		_cursorIcon = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"cursor_icon.png"]];
	} else {
		[_cursorIcon retain];
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
	
	if ([_drawIcon retainCount] == 1) {
		[_drawIcon release];
		_drawIcon = nil;
	} else {
		[_drawIcon release];
	}
	
	if ([_cursorIcon retainCount] == 1) {
		[_cursorIcon release];
		_cursorIcon = nil;
	} else {
		[_cursorIcon release];
	}
	
	if ([_clockIcon retainCount] == 1) {
		[_clockIcon release];
		_clockIcon = nil;
	} else {
		[_clockIcon release];
	}
	
	if ([_cameraIcon retainCount] == 1) {
		[_cameraIcon release];
		_cameraIcon = nil;
	} else {
		[_cameraIcon release];
	}
}

-(void)setListener:(id<CraftADraftListener>)listener {
	_listener = listener;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
}

- (void) draw {
}

- (void) updateWithTimeElapsed:(float)time {
}

- (void) fadeIn {
}

- (void) fadeOut {
}

@end