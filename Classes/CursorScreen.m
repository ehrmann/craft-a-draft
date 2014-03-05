//
//  CursorScreen.m
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/1/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "CursorScreen.h"

#import "Menu.h"
#import "ScreenSelector.h"
#import "WheelControl.h"
#import "UiConstants.h"
#import "Texture2D.h"
#import "CursorOverlay.h"


@implementation CursorScreen 

- (id) initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn {
	[super initWithSize:size];
	
	_menuTouch = nil;
	_topTouch = nil;
	_xTouch = nil;
	_yTouch = nil;
	
	Texture2D *xWheelTexture = [[[Texture2D alloc] initWithImage:[UIImage imageNamed:@"l_x_wheel.png"]] autorelease];
	Texture2D *yWheelTexture = [[[Texture2D alloc] initWithImage:[UIImage imageNamed:@"l_y_wheel.png"]] autorelease];
	
	int xWheelX = (int)(XY_WHEEL_MARGIN + XY_WHEEL_WIDTH / 2);
	int xWheelY = (int)_height - (int)(XY_WHEEL_MARGIN + XY_WHEEL_HEIGHT / 2);
	int yWheelX = (int)_width - (int)(XY_WHEEL_MARGIN + XY_WHEEL_WIDTH / 2);
	int yWheelY = (int)_height - (int)(XY_WHEEL_MARGIN + XY_WHEEL_HEIGHT / 2);
	
	_xWheel = [[WheelControl alloc] initWithTexture:xWheelTexture fadedIn:fadedIn x:xWheelX y:xWheelY width:XY_WHEEL_WIDTH height:XY_WHEEL_HEIGHT];
	_yWheel = [[WheelControl alloc] initWithTexture:yWheelTexture fadedIn:fadedIn x:yWheelX y:yWheelY width:XY_WHEEL_WIDTH height:XY_WHEEL_HEIGHT];
	
	_xWheel.controlTheta = M_PI / 4.0;
	_yWheel.controlTheta = -M_PI / 2.0;
	
	[_xWheel setListener:self];
	[_yWheel setListener:self];
	
	[_xWheel setRadToInt:XY_RAD_TO_DISTANCE];
	[_yWheel setRadToInt:-XY_RAD_TO_DISTANCE];
	
	_menu = [[Menu alloc] initWithSize:size x:_width / 2.0 y:MENU_TOP_MARGIN + MENU_BUTTON_HEIGHT / 2];
	[_menu addListener:self];
	
	[_menu addIcon:_drawIcon];
	[_menu addIcon:_clockIcon];
	[_menu addIcon:_cameraIcon];
	
	_menuVisible = FALSE;
	
	_cursorOverlay = [[CursorOverlay alloc] initWithWidth:_width height:_height];
	
	return self;
}

- (void) dealloc {
	[super dealloc];
	
	[_xWheel release];
	[_yWheel release];
	[_menu release];
	[_cursorOverlay release];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	
	for (UITouch *touch in touches) {
		CGPoint location = [touch locationInView:nil];
		if (location.y > _height * 3 / 8 && _menuVisible == FALSE) {
			// x wheel
			if (location.x < _width / 2) {
				if (_xTouch == nil) {
					_xTouch = touch;
					NSSet *touchSet = [NSSet setWithObject:_xTouch];
					[_xWheel touchesBegan:touchSet withEvent:event];
				}
			}
			// y wheel
			else {
				if (_yTouch == nil) {
					_yTouch = touch;
					NSSet *touchSet = [NSSet setWithObject:_yTouch];
					[_yWheel touchesBegan:touchSet withEvent:event];
				}
			}
		}
		// Top of the screen
		else {
			if (_menuTouch == nil) {
				_menuTouch = touch;
				if (_menuVisible) {
					NSSet *touchSet = [NSSet setWithObject:_menuTouch];
					[_menu touchesBegan:touchSet withEvent:event];
				}
			}
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_xTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_xTouch];
		[_xWheel touchesMoved:touchSet withEvent:event];
	}
	if ([touches containsObject:_yTouch]) {		
		NSSet *touchSet = [NSSet setWithObject:_yTouch];
		[_yWheel touchesMoved:touchSet withEvent:event];
	}
	if ([touches containsObject:_menuTouch]) {
		if (_menuVisible) {
			NSSet *touchSet = [NSSet setWithObject:_menuTouch];
			[_menu touchesMoved:touchSet withEvent:event];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_xTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_xTouch];
		[_xWheel touchesEnded:touchSet withEvent:event];
		_xTouch = nil;
	}
	if ([touches containsObject:_yTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_yTouch];
		[_yWheel touchesEnded:touchSet withEvent:event];
		_yTouch = nil;
	}
	if ([touches containsObject:_menuTouch]) {
		if (_menuVisible) {
			NSSet *touchSet = [NSSet setWithObject:_menuTouch];
			[_menu touchesEnded:touchSet withEvent:event];
		} else {
			[_menu show];
			_menuVisible = TRUE;
		}
		
		_menuTouch = nil;
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

- (void) draw {
	[_cursorOverlay draw];
	[_xWheel draw];
	[_yWheel draw];
	[_menu draw];
}

- (void) updateWithTimeElapsed:(float)time {
	[_xWheel updateWithTimeElapsed:time];
	[_yWheel updateWithTimeElapsed:time];
	[_menu updateWithTimeElapsed:time];
}

-(void)wheelTurned:(int)delta wheel:(WheelControl *)wheel {
	CGPoint cursor = [_listener getCursor];
	
	if (wheel == _xWheel) {
		cursor.x += delta;
		_cursorOverlay.x += delta;
		[_listener setCursor:cursor];
	} else if (wheel == _yWheel) {
		cursor.y += delta;
		_cursorOverlay.y += delta;
		[_listener setCursor:cursor];
	}
}

- (void) iconPressed:(Texture2D *)icon index:(unsigned int)index {
	if (icon == _drawIcon) {
		[_listener drawScreen];
	} else if (icon == _clockIcon) {
		[_listener timeScreen];
	} else if (icon == _cameraIcon) {
		[_listener screenshot];
	}
}

- (void) menuHidden {
	_menuVisible = FALSE;
}

- (void) pressCanceled {
	[_menu hide];
}

- (void)fadeIn {
	CGPoint cursor = [_listener getCursor];
	_cursorOverlay.x = cursor.x;
	_cursorOverlay.y = cursor.y;
	
	[_cursorOverlay fadeIn];
	[_xWheel fadeIn];
	[_yWheel fadeIn];
}

- (void)fadeOut {
	[_menu hide];
	[_xWheel fadeOut];
	[_yWheel fadeOut];
	[_cursorOverlay fadeOut];
}


@end
