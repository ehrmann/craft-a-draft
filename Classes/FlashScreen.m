//
//  FlashScreen.m
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/13/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "FlashScreen.h"

#import "Fader.h"
#import "UiConstants.h"

@implementation FlashScreen

-(id)initWithSize:(CGSize)size {
	_size = size;
	_fader = nil;
	_listener = nil;
	_opacity = 0.0;
	_oneDraw = FALSE;
	
	return self;
}

-(void)dealloc {
	[super dealloc];
	[_fader release];
}

-(void)setListener:(id<FlashListener>)listener {
	[_listener release];
	_listener = listener;
	[_listener retain];
}

-(void)flash {
	if (_fader == nil) {
		_fader = [[Fader alloc] initWithTime:FLASH_FADE_IN_TIME fadedIn:FALSE min:0.0 max:1.0];
		[_fader addListener:self];
		[_fader fadeIn];
	}
}

- (void) fadedOut {
	[_fader autorelease];
	_fader = nil;
	[_listener flashDone];
}

- (void) fadedIn {	
	_oneDraw = TRUE;
	
	[_fader autorelease];	
	_fader = [[Fader alloc] initWithTime:FLASH_FADE_OUT_TIME fadedIn:TRUE min:0.0 max:1.0];
	[_fader addListener:self];
}

- (void) updateWithTimeElapsed:(float)time {
	if (_oneDraw == TRUE) {
		[_listener flashBrightest];
		[_fader fadeOut];
		
		_oneDraw = FALSE;
	}
	
	if (_fader != nil) {
		_opacity = _fader.opacity;
	} else {
		_opacity = 0.0;
	}
}

-(void)draw {
	if (_opacity > 0.0) {
		GLfloat vertices[] = {
			0.0, 0.0,
			_size.width, 0.0,
			0.0, _size.height,
			_size.width, _size.height
		};
		
		GLfloat colors[] = {
			1.0, 1.0, 1.0, _opacity,
			1.0, 1.0, 1.0, _opacity,
			1.0, 1.0, 1.0, _opacity,
			1.0, 1.0, 1.0, _opacity,
		};
		
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glEnable(GL_BLEND);
		
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		
		glColorPointer(4, GL_FLOAT, 0, colors);
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		
		glDisableClientState(GL_COLOR_ARRAY);
		glDisableClientState(GL_VERTEX_ARRAY);

		glDisable(GL_BLEND);
	}
}

@end
