//
//  CursorOverlay.m
//  CraftADraft
//
//  Created by David Ehrmann on 3/2/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "CursorOverlay.h"

#import "Texture2D.h"
#import "Fader.h"

static const float MAX_OVERLAY_OPACITY = 0.4;

@implementation CursorOverlay

@dynamic x;
@dynamic y;

- (id) initWithWidth:(unsigned int)width height:(unsigned int) height {
	_width = height;
	_height = width;
	
	
	_cursorWidth = 32;
	_cursorHeight = 32;
		
	x = 180;
	y = 90;
	UIImage *back = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cursor_back2" ofType:@"png"]];
	_backTexture = [[Texture2D alloc] initWithImage:back];
	_foreTexture = [[Texture2D alloc] initWithImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"cursor_fore" ofType:@"png"]]];
	
	_fader = [[Fader alloc] initWithTime:0.35 fadedIn:FALSE min:0.0 max:1.0];
	
	return self;
}

- (void) dealloc {
	[_backTexture release];
	[_foreTexture release];
	[_fader release];
	[super dealloc];
}

- (void) fadeIn {
	[_fader fadeIn];
}

- (void) fadeOut {
	[_fader fadeOut];
}

- (float) x {
	return _height - y;
}
- (void) setX:(float)val {
	y = _height - val;
	if (y < 0.0) {
		y = 0.0;
	} else if (y > _height) {
		y = _height;
	}
}

- (float) y {
	return x;
}
- (void) setY:(float)val {
	x = val;
	if (x < 0.0) {
		x = 0.0;
	} else if (x > _width) {
		x = _width;
	}
}

- (void) updateWithTimeElapsed:(float)time {
	
}

- (void) draw {
	GLfloat topMaskVertices[] = {
		0.0, 0.0,
		(GLfloat)_height, 0.0,
		0.0, x - _cursorWidth / 2.0,
		(GLfloat)_height, x - _cursorWidth / 2.0
	};
	
	GLfloat bottomMaskVertices[] = {
		0.0,  x + _cursorWidth / 2.0,
		(GLfloat)_height, x + _cursorWidth / 2.0,
		0.0, (GLfloat)_width,
		(GLfloat)_height, (GLfloat)_width
	};
	
	GLfloat leftMaskVertices[] = {
		0.0, x - _cursorWidth / 2.0,
		(_height - y) - _cursorHeight / 2.0, x - _cursorWidth / 2.0,
		0.0, x + _cursorWidth / 2.0,
		(_height - y) - _cursorHeight / 2.0, x + _cursorWidth / 2.0,
	};
	
	GLfloat rightMaskVertices[] = {
		(_height - y) + _cursorHeight / 2.0, x - _cursorWidth / 2.0,
		(GLfloat)_height, x - _cursorWidth / 2.0,
		(_height - y) + _cursorHeight / 2.0, x + _cursorWidth / 2.0,
		(GLfloat)_height, x + _cursorWidth / 2.0,
	};
	
	GLfloat cursorVertices[] = {
		(_height - y) - _cursorWidth / 2.0, x - _cursorWidth / 2.0,
		(_height - y) + _cursorWidth / 2.0, x - _cursorWidth / 2.0,
		(_height - y) - _cursorWidth / 2.0, x + _cursorWidth / 2.0,
		(_height - y) + _cursorWidth / 2.0, x + _cursorWidth / 2.0,
	};
	
	float opacity = _fader.opacity;
	
	GLfloat colors[] = {
		0.0, 0.0, 0.0, MAX_OVERLAY_OPACITY * opacity,
		0.0, 0.0, 0.0, MAX_OVERLAY_OPACITY * opacity,
		0.0, 0.0, 0.0, MAX_OVERLAY_OPACITY * opacity,
		0.0, 0.0, 0.0, MAX_OVERLAY_OPACITY * opacity,
	};
	
	GLfloat coordinates[] = {
		0.0, 0.0,
		1.0, 0.0,
		0.0, 1.0,
		1.0, 1.0
	};
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnable(GL_BLEND);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	//glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

	
	glColorPointer(4, GL_FLOAT, 0, colors);
	
	glVertexPointer(2, GL_FLOAT, 0, topMaskVertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	glVertexPointer(2, GL_FLOAT, 0, bottomMaskVertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glVertexPointer(2, GL_FLOAT, 0, leftMaskVertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glVertexPointer(2, GL_FLOAT, 0, rightMaskVertices);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);

	
	glDisableClientState(GL_COLOR_ARRAY);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnable(GL_TEXTURE_2D);
	
	glVertexPointer(2, GL_FLOAT, 0, cursorVertices);
	glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
	
	glColor4f(1.0, 1.0, 1.0, MAX_OVERLAY_OPACITY * opacity);
	
	glBindTexture(GL_TEXTURE_2D, _backTexture.name);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glColor4f(1.0, 1.0, 1.0, opacity);
	
	glBindTexture(GL_TEXTURE_2D, _foreTexture.name);
	glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
	
	glDisable(GL_BLEND);
	
	glDisableClientState(GL_VERTEX_ARRAY);
}

@end
