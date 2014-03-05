//
//  DrawScreen.m
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

@implementation DrawScreen 

- (id) initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn {
	[super initWithSize:size];
	
	_menuTouch = nil;
	_topTouch = nil;
	_selectorTouch = nil;
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
	
	_screenSelector = [[ScreenSelector alloc] initWithSize:size fadedIn:fadedIn];
	
	_menu = [[Menu alloc] initWithSize:size x:_width / 2.0 y:MENU_TOP_MARGIN + MENU_BUTTON_HEIGHT / 2];
	[_menu addListener:self];
	
	[_menu addIcon:_cursorIcon];
	[_menu addIcon:_clockIcon];
	[_menu addIcon:_cameraIcon];
	
	_menuVisible = FALSE;
	
	return self;
}

- (void) dealloc {
	[super dealloc];
	
	[_xWheel release];
	[_yWheel release];
}

-(void)setListener:(id<CraftADraftListener>)listener {
	[super setListener:listener];
	[_screenSelector setListener:listener];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {

	for (UITouch *touch in touches) {
		CGPoint location = [touch locationInView:nil];
		
		if (location.y > _height * 3 / 8 && _menuVisible == FALSE && _topTouch == nil && _selectorTouch == nil) {
			if (fabs([_listener getScreen] - (float)lrintf([_listener getScreen])) <= 1.0 / 512.0) {
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
		}
		// Top of the screen
		else {
			if (_menuVisible) {
				if (_menuTouch == nil) {
					_menuTouch = touch;
					[_menuTouch retain];

					NSSet *touchSet = [NSSet setWithObject:_menuTouch];
					[_menu touchesBegan:touchSet withEvent:event];
				}
			} else if (_topTouch == nil && _selectorTouch == nil && _xTouch == nil && _yTouch == nil) {
				if (fabs([_listener getScreen] - (float)lrintf([_listener getScreen])) > 1.0 / 512.0) {
					_selectorTouch = touch;
					[_selectorTouch retain];
					[_screenSelector touchesBegan:[NSSet setWithObject:touch] withEvent:event];
				} else {
					_topTouch = touch;
					[_topTouch retain];
					_topLocation = [touch locationInView:nil];
				}
			}
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	BOOL wheelMoved = FALSE;
	float oldXTheta = _xWheel.controlTheta;
	float oldYTheta = _yWheel.controlTheta;
	
	if ([touches containsObject:_xTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_xTouch];
		[_xWheel touchesMoved:touchSet withEvent:event];
		wheelMoved = TRUE;
		
	}
	if ([touches containsObject:_yTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_yTouch];
		[_yWheel touchesMoved:touchSet withEvent:event];
		wheelMoved = TRUE;
	}
	if ([touches containsObject:_selectorTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_selectorTouch];
		[_screenSelector touchesMoved:touchSet withEvent:event];
	}
	if ([touches containsObject:_topTouch]) {
		if (fabs(_topLocation.x - [_topTouch locationInView:nil].x) >= 4.0) {
			_selectorTouch = _topTouch;
			_topTouch = nil;
			NSSet *touchSet = [NSSet setWithObject:_selectorTouch];
			[_screenSelector touchesBegan:touchSet withEvent:event];
		}
	}
	if ([touches containsObject:_menuTouch]) {
		if (_menuVisible) {
			NSSet *touchSet = [NSSet setWithObject:_menuTouch];
			[_menu touchesMoved:touchSet withEvent:event];
		}
	}
		
	
	if (wheelMoved) {
		CGPoint oldCursor = [_listener getCursor];
		float newX = oldCursor.x + XY_RAD_TO_DISTANCE * getCoterminal(_xWheel.controlTheta - oldXTheta);
		float newY = oldCursor.y + XY_RAD_TO_DISTANCE * getCoterminal(-_yWheel.controlTheta + oldYTheta);
		[_listener cursorMoved:CGPointMake(newX, newY)];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	BOOL wheelMoved = FALSE;
	float oldXTheta = _xWheel.controlTheta;
	float oldYTheta = _yWheel.controlTheta;
	
	if ([touches containsObject:_xTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_xTouch];
		[_xWheel touchesEnded:touchSet withEvent:event];
		_xTouch = nil;
		wheelMoved = TRUE;
	}
	if ([touches containsObject:_yTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_yTouch];
		[_yWheel touchesEnded:touchSet withEvent:event];
		_yTouch = nil;
		wheelMoved = TRUE;
	}
	if ([touches containsObject:_menuTouch]) {
		if (_menuVisible) {
			NSSet *touchSet = [NSSet setWithObject:_menuTouch];
			[_menu touchesEnded:touchSet withEvent:event];
		} else {
			[_menu show];
			_menuVisible = TRUE;
		}
		[_menuTouch release];
		_menuTouch = nil;
	}
	if ([touches containsObject:_topTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_topTouch];

		if (fabs(_topLocation.x - [_topTouch locationInView:nil].x) >= 4.0) {
			[_screenSelector touchesBegan:touchSet withEvent:event];
			[_screenSelector touchesEnded:touchSet withEvent:event];
		} else {
			[_menu show];
			_menuVisible = TRUE;
			//[_menu touchesBegan:touchSet withEvent:event];
			//[_menu touchesEnded:touchSet withEvent:event];
		}
		
		[_topTouch release];
		_topTouch = nil;
	}
	if ([touches containsObject:_selectorTouch]) {
		NSSet *touchSet = [NSSet setWithObject:_selectorTouch];
		[_screenSelector touchesEnded:touchSet withEvent:event];
		[_selectorTouch release];
		_selectorTouch = nil;
	}
	
	if (wheelMoved) {
		CGPoint oldCursor = [_listener getCursor];
		float newX = oldCursor.x + XY_RAD_TO_DISTANCE * getCoterminal(_xWheel.controlTheta - oldXTheta);
		float newY = oldCursor.y + XY_RAD_TO_DISTANCE * getCoterminal(-_yWheel.controlTheta + oldYTheta);
		[_listener cursorMoved:CGPointMake(newX, newY)];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

- (void) draw {
	[_screenSelector draw];
	[_xWheel draw];
	[_yWheel draw];
	[_menu draw];
}

- (void) updateWithTimeElapsed:(float)time {
	[_screenSelector updateWithTimeElapsed:time];
	[_xWheel updateWithTimeElapsed:time];
	[_yWheel updateWithTimeElapsed:time];
	[_menu updateWithTimeElapsed:time];
}

- (void) iconPressed:(Texture2D *)icon index:(unsigned int)index {
	if (icon == _clockIcon) {
		[_listener timeScreen];
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
	[_screenSelector fadeIn];
	[_xWheel fadeIn];
	[_yWheel fadeIn];
}

- (void)fadeOut {
	[_screenSelector fadeOut];
	[_menu hide];
	[_xWheel fadeOut];
	[_yWheel fadeOut];
}

@end
