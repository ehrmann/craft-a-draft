//
//  WheelControl.m
//  CraftADraftPad
//
//  Created by David Ehrmann on 4/30/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "WheelControl.h"
#import "Texture2D.h"
#import "Fader.h"

static const float FADE_TIME = 0.2;
static const float DIM_LEVEL = 0.25;
static const float BRIGHT_LEVEL = 0.5;

float getCoterminal(float theta) {
	while (theta < -M_PI) {
		theta += M_PI * 2.0;
	}
	while (theta >= M_PI) {
		theta -= M_PI * 2.0;
	}
	return theta;
}

@implementation WheelControl

@synthesize controlTheta;

- (id)initWithTexture:(Texture2D *)texture fadedIn:(BOOL)fadedIn x:(int)x y:(int)y {
	_texture = [texture retain];
	
	_x = x;
	_y = y;
	
	controlTheta = 0.0;
	
	_bufferedDelta = 0.0;
	_radToInt = 0.0;
	
	_width = texture.contentSize.width;
	_height = texture.contentSize.height;
	
	_fader = [[Fader alloc] initWithTime:0.4 fadedIn:(BOOL)fadedIn min:0.0 max:(float)1.0];
	_dimmer = [[Fader alloc] initWithTime:FADE_TIME fadedIn:FALSE min:DIM_LEVEL max:BRIGHT_LEVEL];
	
	_touch = nil;
	
	return self;
}

- (id)initWithTexture:(Texture2D *)texture fadedIn:(BOOL)fadedIn x:(int)x y:(int)y width:(float)width height:(float)height {
	_texture = [texture retain];
	
	_x = x;
	_y = y;
	
	_width = width;
	_height = height;
	
	_fader = [[Fader alloc] initWithTime:0.4 fadedIn:(BOOL)fadedIn min:0.0 max:(float)1.0];
	_dimmer = [[Fader alloc] initWithTime:FADE_TIME fadedIn:FALSE min:DIM_LEVEL max:BRIGHT_LEVEL];
	
	return self;
}

- (void) dealloc {
	[super dealloc];
	
	[_fader release];
	[_dimmer release];
	[_texture release];
	[_touch release];
}

- (void) setListener:(id<WheelControlListener>)listener {
	_listener = listener;
}

- (void) setRadToInt:(float)radToInt {
	_radToInt = radToInt;
}

- (void) brighten {
	[_dimmer fadeIn];
}

- (void) dim {
	[_dimmer fadeOut];
}

-(void) fadeIn {
	[_fader fadeIn];
}

-(void) fadeOut {
	[_fader fadeOut];
}

- (void) updateWithTimeElapsed:(float)time {
	while(controlTheta >= 2 * M_PI) {
		controlTheta -= 2 * M_PI;
	}
	
	while(controlTheta < 0) {
		controlTheta += 2 * M_PI;
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_touch == nil) {
		_touch = [touches anyObject];
		[_touch retain];
		CGPoint location = [_touch locationInView:nil];
		_lastTouchTheta = atan2(location.y - _y, location.x - _x);
		[self brighten];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_touch]) {
		float oldControlTheta = controlTheta;
		
		CGPoint location = [_touch locationInView:nil];
		float theta = atan2(location.y - _y, location.x - _x);
		controlTheta += (theta - _lastTouchTheta);
		controlTheta = getCoterminal(controlTheta);
		_lastTouchTheta = theta;
		
		float deltaTheta = getCoterminal(controlTheta - oldControlTheta);
		float deltaF = deltaTheta * _radToInt + _bufferedDelta;
		int delta = lrintf(floor(deltaF));
		_bufferedDelta = deltaF - floor(deltaF);
		
		if (delta != 0) {
			[_listener wheelTurned:delta wheel:self];
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_touch]) {
		float oldControlTheta = controlTheta;
		
		CGPoint location = [_touch locationInView:nil];
		float theta = atan2(location.y - _y, location.x - _x);
		controlTheta += (theta - _lastTouchTheta);
		controlTheta = getCoterminal(controlTheta);
		[_touch release];
		_touch = nil;
		
		float deltaTheta = getCoterminal(controlTheta - oldControlTheta);
		float deltaF = deltaTheta * _radToInt + _bufferedDelta;
		int delta = lrintf(floor(deltaF));
		_bufferedDelta = deltaF - floor(deltaF);
		
		if (delta != 0) {
			[_listener wheelTurned:delta wheel:self];
		}
		
		[self dim];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

- (void)draw {
	
	glEnable(GL_BLEND);
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glEnable(GL_TEXTURE_2D);
	
	if (_texture != nil) {
		
		GLfloat coordinates[] = {
			0.0, 0.0,
			(float)_texture.contentSize.width / (float)_texture.pixelsWide, 0.0,
			0.0, (float)_texture.contentSize.height / (float)_texture.pixelsHigh,
			(float)_texture.contentSize.width / (float)_texture.pixelsWide, (float)_texture.contentSize.height / (float)_texture.pixelsHigh
		};
		
		GLfloat vertices[] = {
			0, 0,
			_width, 0,
			0, _height,
			_width, _height
		};
		
		glPushMatrix();
		
		glTranslatef(_x, _y, 0);
		
		//glScalef(1.0, 1.0, 1.0);
		glRotatef(controlTheta * 180 / M_PI, 0, 0, 1.0);
		//glTranslatef(_x, _y, 0);
		glTranslatef(-_width / 2.0, -_height / 2.0, 0);
		
		glBindTexture(GL_TEXTURE_2D, _texture.name);
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
		
		float opacity = _fader.opacity * _dimmer.opacity;
		glColor4f(opacity, opacity, opacity, opacity);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glPopMatrix();
	}	
	
	glDisable(GL_BLEND);	
	glDisable(GL_TEXTURE_2D);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
}


@end
