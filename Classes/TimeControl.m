//
//  TimeControl.m
//  CraftADraft
//
//  Created by David Ehrmann on 2/21/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "TimeControl.h"

#import "Texture2D.h"
#import "Fader.h"

#import "UiConstants.h"

static const float FADE_TIME = 0.2;
static const float DIM_LEVEL = 0.35;
static const float BRIGHT_LEVEL = 0.6;

@implementation TimeControl

@synthesize controlTheta;

- (id)initFadedOutWithX:(int)x y:(int)y {
	_controlX = x;
	_controlY = y;
	
	controlTheta = M_PI / 2;
	
	UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"xl_t_wheel" ofType:@"png"]];
	_texture = [[Texture2D alloc] initWithImage:image];
	
	_fader = [[Fader alloc] initWithTime:0.4 fadedIn:FALSE min:0.0 max:(float)1.0];
	_dimmer = [[Fader alloc] initWithTime:FADE_TIME fadedIn:FALSE min:DIM_LEVEL max:BRIGHT_LEVEL];
	
	return self;
}

- (id)initFadedInWithX:(int)x y:(int)y {
	_controlX = x;
	_controlY = y;
	
	controlTheta = 0;
	
	UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"t_wheel_140px" ofType:@"png"]];
	_texture = [[Texture2D alloc] initWithImage:image];
	
	_fader = [[Fader alloc] initWithTime:0.25 fadedIn:TRUE min:0.0 max:(float)1.0];
	_dimmer = [[Fader alloc] initWithTime:FADE_TIME fadedIn:FALSE min:DIM_LEVEL max:BRIGHT_LEVEL];
	
	return self;
}

- (void) dealloc {
	[_texture release];
	[_fader release];
	[_dimmer release];
	[super dealloc];
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

- (void)draw {
	
	glEnable(GL_BLEND);
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glEnable(GL_TEXTURE_2D);
	
	if (_texture != nil) {

		GLfloat coordinates[] = {
			0.0, 0.0,
			_texture.contentSize.width / _texture.pixelsWide, 0.0,
			0.0, _texture.contentSize.height / _texture.pixelsHigh,
			_texture.contentSize.width / _texture.pixelsWide, _texture.contentSize.height / _texture.pixelsHigh
		};
		
		GLfloat vertices[] = {
			0, 0,
			T_WHEEL_WIDTH, 0,
			0, T_WHEEL_HEIGHT,
			T_WHEEL_WIDTH, T_WHEEL_HEIGHT
		};
		
		glPushMatrix();
		
		glTranslatef(_controlX, _controlY, 0);
		
		glScalef(1.0, 1.0, 1.0);
		glRotatef(controlTheta * 180 / M_PI, 0, 0, 1);
		glTranslatef(-T_WHEEL_WIDTH / 2, -T_WHEEL_HEIGHT / 2, 0);
		
		
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

