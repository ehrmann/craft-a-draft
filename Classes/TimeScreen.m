//
//  TimeScreen.m
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/1/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "TimeScreen.h"
#import "Menu.h"
#import "UiConstants.h"
#import "Texture2D.h"
#import "WheelControl.h"

@implementation TimeScreen

- (id) initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn {
	[super initWithSize:size];
	
	_menuVisible = FALSE;
	
	float wheelX = _width / 2;
	float wheelY = _height - T_WHEEL_BOTTOM_MARGIN - T_WHEEL_HEIGHT / 2;
	_wheelTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"xl_t_wheel.png"]];
	_wheel = [[WheelControl alloc] initWithTexture:_wheelTexture fadedIn:fadedIn x:wheelX y:wheelY width:T_WHEEL_WIDTH height:T_WHEEL_HEIGHT];
	[_wheel setListener:self];
	[_wheel setRadToInt:T_WHEEL_RAD_TO_DOTS];
	
	_menu = [[Menu alloc] initWithSize:size x:_width / 2.0 y:MENU_TOP_MARGIN + MENU_BUTTON_HEIGHT / 2];
	
	[_menu addListener:self];
	
	[_menu addIcon:_cursorIcon];
	[_menu addIcon:_drawIcon];
	[_menu addIcon:_cameraIcon];
	
	return self;
}

- (void) dealloc {
	[super dealloc];
	[_menu release];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

	for (UITouch *touch in touches) {
		CGPoint location = [touch locationInView:nil];
		if (location.y > _height * 3 / 8 && _menuVisible == FALSE && _menuTouch == nil) {
			if (_wheelTouch == nil) {
				_wheelTouch = touch;
				NSSet *touchSet = [NSSet setWithObject:_wheelTouch];
				[_wheel touchesBegan:touchSet withEvent:event];
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
	if ([touches containsObject:_wheelTouch]) {		
		NSSet *touchSet = [NSSet setWithObject:_wheelTouch];
		[_wheel touchesMoved:touchSet withEvent:event];
	}
	if ([touches containsObject:_menuTouch]) {
		if (_menuVisible) {
			NSSet *touchSet = [NSSet setWithObject:_menuTouch];
			[_menu touchesMoved:touchSet withEvent:event];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_wheelTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_wheelTouch];
		[_wheel touchesEnded:touchSet withEvent:event];
		_wheelTouch = nil;
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

-(void)wheelTurned:(int)delta wheel:(WheelControl *)wheel {
	unsigned int oldDot = [_listener getCurrentDot];
	if (delta < 0 && -delta > oldDot) {
		delta = -oldDot;
	}
	
	[_listener setDot:oldDot + delta];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

- (void) draw {
	[_wheel draw];
	[_menu draw];
}

- (void) updateWithTimeElapsed:(float)time {
	[_wheel updateWithTimeElapsed:time];
	[_menu updateWithTimeElapsed:time];
}

- (void) iconPressed:(Texture2D *)icon index:(unsigned int)index {
	if (icon == _drawIcon) {
		[_listener drawScreen];
	} else if (icon == _cameraIcon) {
		[_listener screenshot];
	} else if (icon == _cursorIcon) {
		[_listener cursorScreen];
	}
}

- (void) menuHidden {
	_menuVisible = FALSE;
}

- (void) pressCanceled {
	[_menu hide];
}

- (void)fadeIn {
	[_wheel fadeIn];
}

- (void)fadeOut {
	[_menu hide];
	[_wheel fadeOut];
}

@end
