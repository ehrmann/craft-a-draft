//
//  Controls.m
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import "ScreenSelector.h"
#import "Texture2D.h"
#import "Fader.h"
#import "UiConstants.h"

typedef enum {
	STATE_NORMAL,
	STATE_SCREEN_CHANGE,
	STATE_SCREEN_SETTLE,
} SwipeState;

@implementation ScreenSelector

- (id)initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn {
	_brightScreenSelectorTexture = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"7px_bright" ofType:@"png"]]];
	_dimScreenSelectorTexture = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"7px_faded" ofType:@"png"]]];

	_fader = [[Fader alloc] initWithTime:0.25 fadedIn:fadedIn min:0.0 max:1.0];
	
	_size = size;
	
	activeScreen = 0;
	swipePosition = 0.0;
	_screenAcceleration = 0.0;
	
	_swipeTouch = nil;
	_lastScreenMove = nil;
	
	_listener = nil;
	
	return self;
}

- (void) dealloc {
	[_brightScreenSelectorTexture release];
	[_dimScreenSelectorTexture release];
	[_fader release];
	[super dealloc];
}

- (void)setListener:(id<CraftADraftListener>)listener {
	[_listener release];
	_listener = listener;
	[_listener retain];
	
	activeScreen = [_listener getScreen];
}

- (void) updateWithTimeElapsed:(float)time {
	if (_state == STATE_SCREEN_SETTLE) {
		swipePosition += _screenVelocity * time + (1.0 / 2.0) * _screenAcceleration * time * time;
		_screenVelocity = _screenVelocity + _screenAcceleration * time;
		
		if (_screenAcceleration == 0.0) {
			if (_screenVelocity < 0.0) {
				if (swipePosition < _targetScreen - .01) {
					_screenAcceleration = 2.0 * _screenVelocity * _screenVelocity * 32.0;
				}
			} else {
				if (swipePosition > _targetScreen + .01) {
					_screenAcceleration = -2.0 * _screenVelocity * _screenVelocity * 32.0;
				}
			}
		} else if (_screenAcceleration != 0.0) {
			if (_screenVelocity < 0.0 && _screenAcceleration < 0.0) {
				_screenVelocity = -0.2;
				if (swipePosition - (float)_targetScreen <= 1.0 / 256.0) {					
					swipePosition = _targetScreen;
					activeScreen = _targetScreen;
					_state = STATE_NORMAL;
					
					_screenAcceleration = 0.0;
					
					[_listener setScreen:(float)_targetScreen];
					[_listener screenChangeDone];
					return;
				}
			} else if (_screenVelocity > 0.0 && _screenAcceleration > 0.0) {
				_screenVelocity = 0.2;
				if ((float)_targetScreen - swipePosition <= 1.0 / 256.0) {
					swipePosition = _targetScreen;
					activeScreen = _targetScreen;
					
					_state = STATE_NORMAL;
					_screenAcceleration = 0.0;
					
					[_listener setScreen:(float)_targetScreen];
					[_listener screenChangeDone];
					return;
				}
			} else {
				if (_screenVelocity < 0.0 && _screenAcceleration < 0.0 && swipePosition - (float)_targetScreen < 1.0 / 64.0) {
					_screenAcceleration = -_screenAcceleration;
				} else if(_screenVelocity > 0.0 && _screenAcceleration > 0.0 && (float)_targetScreen - swipePosition < 1.0 / 64.0) {
					_screenAcceleration = -_screenAcceleration;
				}
			}
		}
		
		[_listener setScreen:swipePosition];
	} else if (_state == STATE_NORMAL) {
		activeScreen = lrintf([_listener getScreen]);
	}
}

- (void)draw {
	
	glEnable(GL_BLEND);
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glEnable(GL_TEXTURE_2D);
	
	if (_brightScreenSelectorTexture != nil && _dimScreenSelectorTexture != nil) {
		int width = _brightScreenSelectorTexture.contentSize.width;
		int height = _brightScreenSelectorTexture.contentSize.height;
		
		GLfloat coordinates[] = {
			0.0, 0.0,
			(float)width / _brightScreenSelectorTexture.pixelsWide, 0.0,
			0.0, (float)height / _brightScreenSelectorTexture.pixelsHigh,
			(float)width / _brightScreenSelectorTexture.pixelsWide, (float)height / _brightScreenSelectorTexture.pixelsHigh
		};
		
		GLfloat vertices[] = {
			-width / 2, -height / 2,
			width / 2, -height / 2,
			-width / 2, height / 2,
			width / 2, height / 2
		};
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
		
		float opacity = _fader.opacity;
		glColor4f(opacity, opacity, opacity, opacity);
		
		float offset = -((float)[_listener getScreenCount] - 1.0) / 2.0;
		float distance = 16;
		
		for (unsigned int screen = 0; screen < [_listener getScreenCount]; screen++) {
			glPushMatrix();
			
			glTranslatef(_size.width / 2.0 + offset * distance, MENU_TOP_MARGIN / 2.0, 0);

			if (screen != activeScreen) {
				glBindTexture(GL_TEXTURE_2D, _dimScreenSelectorTexture.name);
			} else {
				glBindTexture(GL_TEXTURE_2D, _brightScreenSelectorTexture.name);
			}
			
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			glPopMatrix();
			
			offset++;
		}
		
		glDisable(GL_BLEND);	
		glDisable(GL_TEXTURE_2D);
		
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisableClientState(GL_VERTEX_ARRAY);
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
	[_swipeTouch release];
	_swipeTouch = [[touches anyObject] retain];
	_lastSwipeLocation = [_swipeTouch locationInView:nil];
	
	// Only let the user pick up a settling screen if it's not settling from an
	// out-of-bounds screen
	if (_state == STATE_SCREEN_SETTLE) {
		if (swipePosition > 0.0 && swipePosition < (float)[_listener getScreenCount] - 1.0) {
			_screenAcceleration = 0.0;
			_screenVelocity = 0.0;
			_state = STATE_SCREEN_CHANGE;
			_lastScreenMove = [[NSDate date] retain];
		} else {
			[_swipeTouch release];
			_swipeTouch = nil;
		}
	} else if (_state == STATE_SCREEN_CHANGE) {
		if (swipePosition < 0.0 || swipePosition > (float)[_listener getScreenCount] - 1.0) {
			[_swipeTouch release];
			_swipeTouch = nil;
			
			[_lastScreenMove release];
			_lastScreenMove = nil;
			
			_state = STATE_SCREEN_SETTLE;
			
			_screenVelocity = .6;
			if (swipePosition - floor(swipePosition) < 0.5) {
				_targetScreen = lrintf(floor(swipePosition));
			} else {
				_targetScreen = lrintf(ceil(swipePosition));
			}
			
			if (_targetScreen <= 0) {
				_targetScreen = 1;
			} else if (_targetScreen > [_listener getScreenCount] - 1) {
				_targetScreen = [_listener getScreenCount] - 1;
			}
			
			if (_targetScreen < swipePosition) {
				_screenVelocity = -_screenVelocity;
			}
			
			_screenAcceleration = 0.0;					
		}
	} else if (_state == STATE_NORMAL) {
		_state = STATE_SCREEN_CHANGE;
		swipePosition = activeScreen;
		_screenVelocity = 0.0;
		_lastScreenMove = [[NSDate date] retain];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_swipeTouch]) {
		CGRect cgRect =[[UIScreen mainScreen] bounds];
		CGPoint location = [_swipeTouch locationInView:nil];
		
		if (_state == STATE_SCREEN_CHANGE) {
			float oldScreenPosition = swipePosition;
			if (swipePosition < 0.0 || swipePosition > (float)[_listener getScreenCount] - 1.0) {
				swipePosition -= 0.5 * (float)(location.x - _lastSwipeLocation.x) / (float)cgRect.size.height;
			} else {
				swipePosition -= (float)(location.x - _lastSwipeLocation.x) / (float)cgRect.size.height;
			}

			_lastSwipeLocation = location;
			_screenVelocity = _screenVelocity * 2.0 / 4.0;
			
			float d = -[_lastScreenMove timeIntervalSinceNow];
			_screenVelocity += (swipePosition - oldScreenPosition) * 0.5 / d;
			
			if (_screenVelocity < -10.0) {
				_screenVelocity = -10.0;
			} else if (_screenVelocity > 10.0) {
				_screenVelocity = 10.0;
			}
			
			[_lastScreenMove release];
			_lastScreenMove = [[NSDate date] retain];
			
			[_listener setScreen:swipePosition];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {	
	if ([touches containsObject:_swipeTouch]) {
		CGRect cgRect =[[UIScreen mainScreen] bounds];
		CGPoint location = [_swipeTouch locationInView:nil];
		if (_state == STATE_SCREEN_CHANGE) {
			float oldScreenPosition = swipePosition;
			swipePosition -= (float)(location.x - _lastSwipeLocation.x) / (float)cgRect.size.height;
			_lastSwipeLocation = location;
			_screenVelocity = _screenVelocity / 2.0;
			
			float d = -[_lastScreenMove timeIntervalSinceNow];
			_screenVelocity += (swipePosition - oldScreenPosition) * 0.5 / d;
			
			if (_screenVelocity < -10.0) {
				_screenVelocity = -10.0;
			} else if (_screenVelocity > 10.0) {
				_screenVelocity = 10.0;
			}
			
			
			[_lastScreenMove release];
			_lastScreenMove = nil;
			
			_state = STATE_SCREEN_SETTLE;
			
			if (fabs(_screenVelocity) > .25) {
				if (_screenVelocity < 0) {
					_targetScreen = lrintf(floor(swipePosition));
					_screenVelocity = -_screenVelocity;
				} else {
					_targetScreen = lrintf(ceil(swipePosition));
				}
			} else {
				if (swipePosition - floor(swipePosition) < 0.5) {
					_targetScreen = lrintf(floor(swipePosition));
					
				} else {
					_targetScreen = lrintf(ceil(swipePosition));
				}
				
				if (fabs(_targetScreen - swipePosition) < 0.05) {
					_screenVelocity = .2;
				} else {
					_screenVelocity = .6;
				}
			}
			
			if (_targetScreen < 0) {
				_targetScreen = 0;
				_screenVelocity = .6;
			} else if (_targetScreen >= [_listener getScreenCount]) {
				_targetScreen = [_listener getScreenCount] - 1;
				_screenVelocity = .6;
			}
			
			if (_targetScreen < swipePosition) {
				_screenVelocity = -_screenVelocity;
			}
			
			_screenAcceleration = 0.0;
			
			[_lastScreenMove release];
			_lastScreenMove = nil;
		}
		
		_swipeTouch = nil;
		
		[_listener setScreen:swipePosition];
	}	
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_swipeTouch]) {
		if (_state == STATE_SCREEN_CHANGE) {
			
			[_lastScreenMove release];
			_lastScreenMove = nil;
			
			_state = STATE_SCREEN_SETTLE;
			
			_targetScreen = activeScreen;
			
			_screenVelocity = .6;

			if (_targetScreen < swipePosition) {
				_screenVelocity = -_screenVelocity;
			}
			
			_screenAcceleration = 0.0;
			
			[_lastScreenMove release];
			_lastScreenMove = nil;
		}
		
		[_listener setScreen:swipePosition];
		
		_swipeTouch = nil;
	}
}

- (void) fadeIn {
	[_fader fadeIn];
}

- (void) fadeOut {
	[_fader fadeOut];
}

@end
