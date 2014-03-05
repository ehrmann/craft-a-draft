//
//  Controls.m
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import "Controls.h"

#import "Texture2D.h"
#import "Fader.h"

static const float FADE_TIME = 0.2;
static const float DIM_LEVEL = 0.35;
static const float BRIGHT_LEVEL = 0.6;

@implementation Controls

@synthesize xControlTheta;
@synthesize yControlTheta;

- (Controls *)initWithXControlX:(int)xControlX xControlY:(int)xControlY yControlX:(int)yControlX yControlY:(int)yControlY {
	_xControlX = xControlX;
	_xControlY = xControlY;
	_yControlX = yControlX;
	_yControlY = yControlY;
	
	xControlTheta = M_PI / 4;
	yControlTheta = 0;
	
	UIImage *xImage = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"x_" ofType:@"png"]];
	_xTexture = [[Texture2D alloc] initWithImage:xImage];
	_yTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"y_.png"]];
	
	_xState = CONTROL_STATE_DIM;
	_yState = CONTROL_STATE_DIM;
	
	_xOpacity = DIM_LEVEL;
	_yOpacity = DIM_LEVEL;
	
	_xDate = nil;
	_yDate = nil;
	
	_fader = [[Fader alloc] initWithTime:0.4 fadedIn:TRUE min:0.0 max:(float)1.0];
	
	return self;
}

- (void) dealloc {
	[_xTexture release];
	[_yTexture release];
	[_fader release];
	[super dealloc];
}

- (void) brightenX {
	if (_xDate != nil) {
		[_xDate release];
	}
	
	_xDate = [[NSDate date] retain];
	_xState = CONTROL_STATE_BRIGHTNING;
}

- (void) brightenY {
	if (_yDate != nil) {
		[_yDate release];
	}
	
	_yDate = [[NSDate date] retain];
	_yState = CONTROL_STATE_BRIGHTNING;
}

- (void) dimX {
	if (_xDate != nil) {
		[_xDate release];
	}
	
	_xDate = [[NSDate date] retain];
	_xState = CONTROL_STATE_DIMMING;
}

- (void) dimY {
	if (_yDate != nil) {
		[_yDate release];
	}
	
	_yDate = [[NSDate date] retain];
	_yState = CONTROL_STATE_DIMMING;
}

- (void) updateWithTimeElapsed:(float)time {
	
	if (_xDate != nil) {
		float d = -[_xDate timeIntervalSinceNow];
		[_xDate release];
		_xDate = [[NSDate date] retain];
		
		if (_xState == CONTROL_STATE_DIMMING) {
			_xOpacity -= (d / FADE_TIME) * (BRIGHT_LEVEL - DIM_LEVEL);
			if (_xOpacity <= DIM_LEVEL) {
				_xOpacity = DIM_LEVEL;
				_xState = CONTROL_STATE_DIM;
				[_xDate release];
				_xDate = nil;
			}
		} else if(_xState == CONTROL_STATE_BRIGHTNING) {
			_xOpacity += (d / FADE_TIME) * (BRIGHT_LEVEL - DIM_LEVEL);
			if (_xOpacity >= BRIGHT_LEVEL) {
				_xOpacity = BRIGHT_LEVEL;
				_xState = CONTROL_STATE_BRIGHT;
				[_xDate release];
				_xDate = nil;
			}
		}
	}
	if (_yDate != nil) {
		float d = -[_yDate timeIntervalSinceNow];
		[_yDate release];
		_yDate = [[NSDate date] retain];
		
		if (_yState == CONTROL_STATE_DIMMING) {
			_yOpacity -= (d / FADE_TIME) * (BRIGHT_LEVEL - DIM_LEVEL);
			if (_yOpacity <= DIM_LEVEL) {
				_yOpacity = DIM_LEVEL;
				_yState = CONTROL_STATE_DIM;
				[_yDate release];
				_yDate = nil;
			}
		} else if (_yState == CONTROL_STATE_BRIGHTNING) {
			_yOpacity += (d / FADE_TIME) * (BRIGHT_LEVEL - DIM_LEVEL);
			if (_yOpacity >= BRIGHT_LEVEL) {
				_yOpacity = BRIGHT_LEVEL;
				_yState = CONTROL_STATE_BRIGHT;
				[_yDate release];
				_yDate = nil;
			}
		}
	}
	
	while(xControlTheta >= 2 * M_PI) {
		xControlTheta -= 2 * M_PI;
	}
	
	while(xControlTheta < 0) {
		xControlTheta += 2 * M_PI;
	}
	
	while(yControlTheta >= 2 * M_PI) {
		yControlTheta -= 2 * M_PI;
	}
	
	while(yControlTheta < 0) {
		yControlTheta += 2 * M_PI;
	}
	
}

- (void)draw {

	glEnable(GL_BLEND);
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glEnable(GL_TEXTURE_2D);
	
	float masterOpacity = _fader.opacity;
	
	if (_xTexture != nil) {
		int width = _xTexture.contentSize.width;
		int height = _xTexture.contentSize.height;
		
		GLfloat coordinates[] = {
			0.0, 0.0,
			(float)width / _xTexture.pixelsWide, 0.0,
			0.0, (float)height / _xTexture.pixelsHigh,
			(float)width / _xTexture.pixelsWide, (float)height / _xTexture.pixelsHigh
		};
		
		GLfloat vertices[] = {
			0, 0,
			width, 0,
			0, height,
			width, height
		};
		
		glPushMatrix();
		
		glTranslatef(_xControlX, _xControlY, 0);
		
		glScalef(.5, .5, 1);
		glRotatef(xControlTheta * 180 / M_PI, 0, 0, 1);
		glTranslatef(-width / 2, -height / 2, 0);
	

		glBindTexture(GL_TEXTURE_2D, _xTexture.name);
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
		
		glColor4f(_xOpacity * masterOpacity, _xOpacity * masterOpacity, _xOpacity * masterOpacity, _xOpacity * masterOpacity);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glPopMatrix();
	}

	if (_yTexture != nil) {
		int width = _yTexture.contentSize.width;
		int height = _yTexture.contentSize.height;
		
		GLfloat coordinates[] = {
			0.0, 0.0,
			(float)width / _yTexture.pixelsWide, 0.0,
			0.0, (float)height / _yTexture.pixelsHigh,
			(float)width / _yTexture.pixelsWide, (float)height / _yTexture.pixelsHigh
		};
		
		GLfloat vertices[] = {
			0, 0,
			width, 0,
			0, height,
			width, height
		};
		
		glPushMatrix();
		
		glTranslatef(_yControlX, _yControlY, 0);
		
		glScalef(.5, .5, 1);
		glRotatef(yControlTheta * 180 / M_PI, 0, 0, 1);
		glTranslatef(-width / 2, -height / 2, 0);
		
		
		glBindTexture(GL_TEXTURE_2D, _yTexture.name);
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
		
		glColor4f(_yOpacity * masterOpacity, _yOpacity * masterOpacity, _yOpacity * masterOpacity, _yOpacity * masterOpacity);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glPopMatrix();
	}	
	
	glDisable(GL_BLEND);	
	glDisable(GL_TEXTURE_2D);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
}

-(void) fadeIn {
	[_fader fadeIn];
}

-(void) fadeOut {
	[_fader fadeOut];
}

@end
