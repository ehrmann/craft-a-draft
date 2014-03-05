//
//  CanvasScreen.m
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import "CanvasScreen.h"
#import "Texture2D.h"

#import "Fader.h"

static const float OPACITY = 0.17;
static const float FADE_TIME = 0.8;

static const int X_BORDER = 2;
static const int Y_BORDER = 3;

// Small numbers (< ~32) create performance problems
static const unsigned int HISTORY_BUFFER_SIZE = 512;

static Texture2D *backTexture = nil;
static Texture2D *drawTexture = nil;

static void providerReleaseData (void *info, const void *data, size_t size) {
	free((void *)data);
}

static int pow2(int n) {
	int x = 1;
	
	while(x < n) {
		x <<= 1;
	}
	
	return x;
}   

typedef struct {
	GLuint matrixMode;
	GLuint framebuffer;
	GLuint renderbuffer;
	GLint viewportDims[4];
} openGlState;

static void backupGlState(openGlState *state) {
	glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, (GLint *)&state->framebuffer);
	glGetIntegerv(GL_RENDERBUFFER_BINDING_OES, (GLint *)&state->renderbuffer);
	glGetIntegerv(GL_VIEWPORT, state->viewportDims);
	glGetIntegerv(GL_MATRIX_MODE, (GLint *)&state->matrixMode);
	
	glMatrixMode(GL_PROJECTION);
}

static void restoreGlState(openGlState *state) {
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, state->framebuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, state->renderbuffer);
	glViewport(state->viewportDims[0], state->viewportDims[1], state->viewportDims[2], state->viewportDims[3]);
	glMatrixMode(state->matrixMode);
}

@interface Dot : NSObject {
	@public
	float x;
	float y;
}

- (void) toVertexData:(VertexData *)data;

@end

@implementation Dot
- (void) toVertexData:(VertexData *)data {
	data[0].vertexX = self->x - 2;
	data[0].vertexY = self->y - 2;
	data[1].vertexX = self->x + 2;
	data[1].vertexY = self->y - 2;
	data[2].vertexX = self->x - 2;
	data[2].vertexY = self->y + 2;
	
	data[3].vertexX = self->x - 2;
	data[3].vertexY = self->y + 2;		
	data[4].vertexX = self->x + 2;
	data[4].vertexY = self->y + 2;	
	data[5].vertexX = self->x + 2;
	data[5].vertexY = self->y - 2;
	
	data[0].coordX = 0.0;
	data[0].coordY = 0.0;
	data[1].coordX = 1.0;
	data[1].coordY = 0.0;
	data[2].coordX = 0.0;
	data[2].coordY = 1.0;
	
	data[3].coordX = 0.0;
	data[3].coordY = 1.0;
	data[4].coordX = 1.0;
	data[4].coordY = 1.0;
	data[5].coordX = 1.0;
	data[5].coordY = 0.0;
}
@end

@implementation CanvasScreenUpdateState
@end


@implementation CanvasScreen

@dynamic x;
@dynamic y;
@dynamic dotCount;
@synthesize headerCount;

- (id) initWithWidth:(unsigned int)width height:(unsigned int) height {
	_width = width;
	_height = height;
	
	_textureWidth = pow2(width);
	_textureHeight = pow2(height);
	
	x = width / 2;
	y = height / 2;
	
	lastDotX = x;
	lastDotY = y;
	
	if (backTexture == nil) {
		backTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"paper2.png"]];
	} else {
		[backTexture retain];
	}
	
	if (drawTexture == nil) {
		drawTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"texture_.png"]];
	} else {
		[drawTexture retain];
	}
	
	_fader = [[Fader alloc] initWithTime:FADE_TIME fadedIn:TRUE min:0.0 max:1.0];
	[_fader addListener:self];
	
	_dots = [[NSMutableArray alloc] initWithCapacity:1024];
	_dotsDrawn = 0;
	nextDotIndex = 0;
	
	_fboAllocated = false;
	
	_firstNewDot = 0;
	_originalCursorPosition = 0;
	
	_historyBuffer = malloc(sizeof(VertexData) * HISTORY_BUFFER_SIZE * 6);
	_dotsInHistoryBuffer = 0;
	
	headerCount = 0;
	
	_listener = nil;
	
	return self;
}

-(void)setListener:(id<CraftADraftListener>) listener {
	[_listener release];
	_listener = [listener retain];
}

/*
 * 0xc0 1100 0000 - Header
 * 0xff 1111 1111 - Full, regular point 
 * 0x00 00.. .... - Delta point
 * 0xc1 1100 0001 - Cursor (little endian) set
 * 0xc2 1100 0002 - Cursor (little endian) set
 
*/
- (void) setData:(NSData *)nsData {
	
	unsigned char header[16] = {
		0xc0,
		'C', 'r', 'a', 'f', 't', 'A', 'D', 'r', 'a', 'f', 't',
		0x00, 0x00, 0x00, 0x00
	};
	
	unsigned char *data = (unsigned char *)[nsData bytes];
	
	if ([nsData length] >= sizeof(header)) {
		if (memcmp(header, data, sizeof(header)) != 0) {
			return;
		}
	} else {
		return;
	}
	
	int lastX = 0;
	int lastY = 0;
	
	for (unsigned int i = sizeof(header); i < [nsData length];) {
		// Delta point
		if ((data[i] & 0xc0) == 0x00) {
			if (nextDotIndex < [_dots count]) {
				NSRange range = { .location = nextDotIndex, .length = [_dots count] - nextDotIndex };
				[_dots removeObjectsInRange:range];
			}
			
			Dot *dot = [Dot alloc];
			
			int deltaX = ((data[i] >> 3) & 0x07);
			int deltaY = (data[i] & 0x07);
			if (deltaX & 0x4) {
				deltaX |= (~0 ^ 0x07);
			}
			if (deltaY & 0x4) {
				deltaY |= (~0 ^ 0x07);
			}
			
			lastX += deltaX;
			lastY += deltaY;
			dot->x = lastX;
			dot->y = lastY;

			[_dots addObject:dot];
			[dot release];

			nextDotIndex++;
			
			x = lastX;
			y = lastY;
			
			i++;
		}
		// CraftADraft header
		else if (data[i] == 0xc0) {
			if (i + sizeof(header) > [nsData length]) {
				return;
			}
			
			if (memcmp(header, data + i, sizeof(header)) != 0) {
				return;
			}
			i += sizeof(header);
			headerCount++;
		}
		// Full point
		else if (data[i] == 0xff) {
			if (i + 5 > [nsData length]) {
				return;
			}
			
			if (nextDotIndex < [_dots count]) {
				NSRange range = { .location = nextDotIndex, .length = [_dots count] - nextDotIndex };
				[_dots removeObjectsInRange:range];
			}
			
			lastX = (data[i + 1] << 8) | data[i + 2];
			lastY = (data[i + 3] << 8) | data[i + 4];
			
			Dot *dot = [Dot alloc];
			dot->x = lastX;
			dot->y = lastY;
			
			x = lastX;
			y = lastY;
			
			[_dots addObject:dot];
			[dot release];

			nextDotIndex++;
			
			i += 5;
		}
		
		// Big endian cursor
		else if (data[i] == 0xc2) {
			if (i + 5 > [nsData length]) {
				return;
			}
			
			unsigned int temp = 0;
			temp = data[i + 4];
			temp |= (data[i + 3] << 8);
			temp |= (data[i + 2] << 16);
			temp |= (data[i + 1] << 24);
			
			if (temp <= [_dots count]) {
				nextDotIndex = temp;
			}
			
			if (nextDotIndex < [_dots count]) {
				x = ((Dot *)[_dots objectAtIndex:nextDotIndex])->x;
				y = ((Dot *)[_dots objectAtIndex:nextDotIndex])->y;
			}
			
			i += 5;
		} else {
			break;
		}
	}
	
	lastDotX = x;
	lastDotY = y;
	
	_firstNewDot = nextDotIndex;
	_originalCursorPosition = nextDotIndex;
	
	return;
}


- (NSMutableData *) getDataUpdate {
	
	if (_firstNewDot == 0 && [_dots count] == 0) {
		return nil;
	}
	
	if (_firstNewDot > [_dots count]) {
		return nil;
	}
	
	if (_originalCursorPosition == nextDotIndex && _firstNewDot == [_dots count]) {
		return nil;
	}
	

	unsigned int size = 16; // 0xc0 craftadraft 0x00000000
	
	Dot *lastDot = nil;
	for (unsigned int i = _firstNewDot; i < [_dots count]; i++) {
		Dot *dot = (Dot *)[_dots objectAtIndex:i];
		size++;
		
		if (lastDot) {
			int detaX = lrintf(dot->x) - lrintf(lastDot->x);
			int deltaY = lrintf(dot->y) - lrintf(lastDot->y);
			
			if (detaX >= -4 && detaX <= 3 && deltaY >= -4 && deltaY <= 3) {
			} else {
				size += 4;
			}
		} else {
			size += 4;
		}
		
		lastDot = dot;
	}
	
	// Set the cursor at the begining and end
	size += 10;
	
	
	NSMutableData *nsData = [[NSMutableData dataWithLength:size] retain];
	unsigned char *data = [nsData mutableBytes];
	
	unsigned int offset = 0;
	data[offset++] = 0xc0;
	memcpy(data + offset, "CraftADraft", strlen("CraftADraft"));
	offset += strlen("CraftADraft");
	
	static const unsigned char version[] = { 0x00, 0x00, 0x00, 0x00 };
	memcpy(data + offset, version, sizeof(version));
	offset += sizeof(version);
	
	// Set the cursor position
	data[offset++] = 0xc2;
	data[offset++] = (_firstNewDot >> 24) & 0xff;
	data[offset++] = (_firstNewDot >> 16) & 0xff;
	data[offset++] = (_firstNewDot >> 8) & 0xff;
	data[offset++] = _firstNewDot & 0xff;
	
	lastDot = nil;
	int lastX = 0;
	int lastY = 0;
	for (unsigned int i = _firstNewDot; i < [_dots count]; i++) {
		Dot *dot = (Dot *)[_dots objectAtIndex:i];
		int dotX = lrintf(dot->x);
		int dotY = lrintf(dot->y);
		
		if (lastDot) {
			int deltaX = dotX - lastX;
			int deltaY = dotY - lastY;
			
			if (deltaX >= -4 && deltaX <= 3 && deltaY >= -4 && deltaY <= 3) {
				unsigned char val = ((deltaX & 0x07) << 3);
				val |= (deltaY & 0x07);
				data[offset++] = val;
			} else {
				data[offset++] = 0xff;
				unsigned char x16[2] = { (dotX >> 8) & 0xff, dotX & 0xff };
				unsigned char y16[2] = { (dotY >> 8) & 0xff, dotY & 0xff };
				memcpy(data + offset, x16, sizeof(x16));
				offset += sizeof(x16);
				memcpy(data + offset, y16, sizeof(y16));
				offset += sizeof(y16);
			}
		} else {
			data[offset++] = 0xff;
			unsigned char x16[2] = { (dotX >> 8) & 0xff, dotX & 0xff };
			unsigned char y16[2] = { (dotY >> 8) & 0xff, dotY & 0xff };
			memcpy(data + offset, x16, sizeof(x16));
			offset += sizeof(x16);
			memcpy(data + offset, y16, sizeof(y16));
			offset += sizeof(y16);
		}
		
		lastX = dotX;
		lastY = dotY;
		lastDot = dot;
	}
	
	// Set cursor position (0xc1)
	data[offset++] = 0xc2;
	data[offset++] = (nextDotIndex >> 24) & 0xff;
	data[offset++] = (nextDotIndex >> 16) & 0xff;
	data[offset++] = (nextDotIndex >> 8) & 0xff;
	data[offset++] = nextDotIndex & 0xff;
	
	_firstNewDot = [_dots count];
	_originalCursorPosition = nextDotIndex;
	
	headerCount++;
	
	return [nsData autorelease];
}

- (NSMutableData *) getData {
	
	if (_firstNewDot == 0 && [_dots count] == 0) {
		headerCount = 0;
		return nil;
	}
	
	unsigned int size = 16; // 0xc0 craftadraft 0x00000000
	
	Dot *lastDot = nil;
	for (unsigned int i = 0; i < [_dots count]; i++) {
		Dot *dot = (Dot *)[_dots objectAtIndex:i];
		size++;
		
		if (lastDot) {
			int detaX = lrintf(dot->x) - lrintf(lastDot->x);
			int deltaY = lrintf(dot->y) - lrintf(lastDot->y);
			
			if (detaX >= -4 && detaX <= 3 && deltaY >= -4 && deltaY <= 3) {
			} else {
				size += 4;
			}
		} else {
			size += 4;
		}
		
		lastDot = dot;
	}
	
	// Set the cursor at the end
	size += 5;
	
	NSMutableData *nsData = [[NSMutableData dataWithLength:size] retain];
	unsigned char *data = [nsData mutableBytes];
	
	unsigned int offset = 0;
	data[offset++] = 0xc0;
	memcpy(data + offset, "CraftADraft", strlen("CraftADraft"));
	offset += strlen("CraftADraft");
	
	static const unsigned char version[] = { 0x00, 0x00, 0x00, 0x00 };
	memcpy(data + offset, version, sizeof(version));
	offset += sizeof(version);
	
	lastDot = nil;
	int lastX = 0;
	int lastY = 0;
	for (unsigned int i = 0; i < [_dots count]; i++) {
		Dot *dot = (Dot *)[_dots objectAtIndex:i];
		int dotX = lrintf(dot->x);
		int dotY = lrintf(dot->y);
		
		if (lastDot) {
			int deltaX = dotX - lastX;
			int deltaY = dotY - lastY;
			
			if (deltaX >= -4 && deltaX <= 3 && deltaY >= -4 && deltaY <= 3) {
				unsigned char val = ((deltaX & 0x07) << 3);
				val |= (deltaY & 0x07);
				data[offset++] = val;
			} else {
				data[offset++] = 0xff;
				unsigned char x16[2] = { (dotX >> 8) & 0xff, dotX & 0xff };
				unsigned char y16[2] = { (dotY >> 8) & 0xff, dotY & 0xff };
				memcpy(data + offset, x16, sizeof(x16));
				offset += sizeof(x16);
				memcpy(data + offset, y16, sizeof(y16));
				offset += sizeof(y16);
			}
		} else {
			data[offset++] = 0xff;
			unsigned char x16[2] = { (dotX >> 8) & 0xff, dotX & 0xff };
			unsigned char y16[2] = { (dotY >> 8) & 0xff, dotY & 0xff };
			memcpy(data + offset, x16, sizeof(x16));
			offset += sizeof(x16);
			memcpy(data + offset, y16, sizeof(y16));
			offset += sizeof(y16);
		}
		
		lastX = dotX;
		lastY = dotY;
		lastDot = dot;
	}
	
	// Set cursor position (0xc1)
	data[offset++] = 0xc2;
	data[offset++] = (nextDotIndex >> 24) & 0xff;
	data[offset++] = (nextDotIndex >> 16) & 0xff;
	data[offset++] = (nextDotIndex >> 8) & 0xff;
	data[offset++] = nextDotIndex & 0xff;
	
	_firstNewDot = [_dots count];
	_originalCursorPosition = nextDotIndex;
	
	headerCount = 1;
	
	return [nsData autorelease];
}

- (void) dealloc {
	if ([drawTexture retainCount] == 1) {
		[drawTexture release];
		drawTexture = nil;
	} else {
		[drawTexture release];
	}
	
	if ([backTexture retainCount] == 1) {
		[backTexture release];
		backTexture = nil;
	} else {
		[backTexture release];
	}
	
	if (_fboAllocated) {
		glDeleteTextures(1, &_texture);
		glDeleteFramebuffersOES(1, &_fbo);
	}
	
	if (_historyBuffer != NULL) {
		free(_historyBuffer);
	}
	
	[_dots release];
	[_fader release];
	[_listener release];
	
	[super dealloc];
}

- (void) redrawTexture {
	
	openGlState oldState;
	backupGlState(&oldState);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _fbo);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthBuffer);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
    glLoadIdentity();
	glOrthof(0, _width, _height, 0, 0, 100);
	
	glViewport(0, 0, _width, _height);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glEnable(GL_TEXTURE_2D);	
	glBindTexture(GL_TEXTURE_2D, backTexture.name);
	
	if (backTexture != nil) {
		GLfloat coordinates[] = {
			0.0, backTexture.contentSize.height / (float)backTexture.pixelsHigh,
			backTexture.contentSize.width / (float)backTexture.pixelsWide, backTexture.contentSize.height / (float)backTexture.pixelsHigh,
			0.0, 0.0,
			backTexture.contentSize.width / (float)backTexture.pixelsWide, 0.0
		};
		
		GLfloat vertices[] = {
			0.0, _height,
			_width, _height,
			0.0, 0.0,
			_width, 0.0
		};
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
		glColor4f(1.0, 1.0, 1.0, 1.0);
		
		glMatrixMode(GL_MODELVIEW);
		
		glPushMatrix();
		
		glLoadIdentity();
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glPopMatrix();
	}
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
	glDisable(GL_TEXTURE_2D);
	
	restoreGlState(&oldState);
	
	_dotsDrawn = 0;
}

- (float) x {
	return x;
}

- (void) setX:(float)val {
	if (val < X_BORDER) {
		val = X_BORDER;
	} else if (val >= _width - X_BORDER) {
		val = _width - X_BORDER - 1;
	}

	x = val;
	lastDotX = x;
}

- (float) y {
	return y;
}

- (void) setY:(float)val {
	if (val < Y_BORDER) {
		val = Y_BORDER;
	} else if (val >= _height - Y_BORDER) {
		val = _height - Y_BORDER - 1;
	}
	
	y = val;
	lastDotY = y;
}

- (void) allocateFbo {
	
	openGlState oldState;
	backupGlState(&oldState);
	
	glGenFramebuffersOES(1, &_fbo);
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _fbo);
	
	glGenTextures(1, &_texture);
	glBindTexture(GL_TEXTURE_2D, _texture);
	
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MIN_FILTER,GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D,GL_TEXTURE_MAG_FILTER,GL_LINEAR);
	
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
	
	glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, _textureWidth, _textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
	
	glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, _texture, 0);
	
	glGenRenderbuffersOES(1, &_depthBuffer);
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthBuffer);
	glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, _textureWidth, _textureHeight);
	glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, _depthBuffer);
	
	GLenum status = glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) ;
	if(status != GL_FRAMEBUFFER_COMPLETE_OES) {
		NSLog(@"failed to make complete framebuffer object %x", status);
	} else {
		_fboAllocated = true;
	}
	
	restoreGlState(&oldState);
}

- (void) fillHistoryBuffer {
	int index;
	int bufferIndex = 0;
	for (index = _dotsDrawn; index - _dotsDrawn < HISTORY_BUFFER_SIZE && index < [_dots count]; index++) {
		Dot *dot = [_dots objectAtIndex:index];
		[dot toVertexData:_historyBuffer + bufferIndex];
		bufferIndex += 6;
	}
	_dotsInHistoryBuffer = bufferIndex / 6;
}

- (void) flushHistoryBufferWithDots:(unsigned int)dots {
	
	if (dots > _dotsInHistoryBuffer) {
		dots = _dotsInHistoryBuffer;
	}

	openGlState oldState;
	backupGlState(&oldState);
	
	glBindFramebufferOES(GL_FRAMEBUFFER_OES, _fbo);
	glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, _texture, 0);
	
	glBindRenderbufferOES(GL_RENDERBUFFER_OES, _depthBuffer);
	
	glMatrixMode(GL_PROJECTION);
	glPushMatrix();
    glLoadIdentity();
	glOrthof(0, _width, _height, 0, 0, 100);
	glMatrixMode(GL_MODELVIEW);
	
	glViewport(0, 0, _width, _height);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glEnable(GL_TEXTURE_2D);
	glBindTexture(GL_TEXTURE_2D, drawTexture.name);
	
	glEnable(GL_BLEND);
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	glVertexPointer(2, GL_FLOAT, sizeof(VertexData), &_historyBuffer[0].vertexX);
	glTexCoordPointer(2, GL_FLOAT, sizeof(VertexData), &_historyBuffer[0].coordX);
	
	glColor4f(OPACITY, OPACITY, OPACITY, OPACITY);
	
	glPushMatrix();
	glLoadIdentity();
	glDrawArrays(GL_TRIANGLES, 0, 6 * dots);
	glPopMatrix();
	
	glMatrixMode(GL_PROJECTION);
	glPopMatrix();
	glMatrixMode(GL_MODELVIEW);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	
	glDisable(GL_TEXTURE_2D);
	glDisable(GL_BLEND);
	
	restoreGlState(&oldState);

	_dotsDrawn += dots;
	_dotsInHistoryBuffer = 0;
}

- (void) flushHistoryBuffer {
	[self flushHistoryBufferWithDots:_dotsInHistoryBuffer];
}

- (UIImage *) getUIImageWithOrientation:(UIImageOrientation) orientation {
	if (_fboAllocated) {
		[self updateWithTimeElapsed:0.0];
		
		if (_dotsDrawn < nextDotIndex) {
			[self flushHistoryBufferWithDots:nextDotIndex - _dotsDrawn];
		}
		
		GLuint oldFramebuffer;
		glGetIntegerv(GL_FRAMEBUFFER_BINDING_OES, (GLint *)&oldFramebuffer);
		
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, _fbo);
		glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D, _texture, 0);
		
		GLubyte *data = malloc(_width * _height * 4);
		if (data == NULL) {
			glBindFramebufferOES(GL_FRAMEBUFFER_OES, oldFramebuffer);
			return nil;
		}
		
		glReadPixels(0, 0, _width, _height, GL_RGBA, GL_UNSIGNED_BYTE, data);
		
		glBindFramebufferOES(GL_FRAMEBUFFER_OES, oldFramebuffer);
		
		
		CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, data, _width * _height * 4, providerReleaseData);
		
		// prep the ingredients
		int bitsPerComponent = 8;
		int bitsPerPixel = 32;
		int bytesPerRow = 4 * _width;
		
		CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceRGB();
		
		CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
		
		CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
		
		// make the cgimage
		CGImageRef imageRef = CGImageCreate(_width, _height, bitsPerComponent, bitsPerPixel, bytesPerRow, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
		CGColorSpaceRelease(colorSpaceRef);
		CGDataProviderRelease(provider);
		
		// then make the uiimage from that
		UIImage *myImage = [UIImage imageWithCGImage:imageRef];
		CGImageRelease(imageRef);

		CGSize newSize;
		
		switch (orientation) {
			case UIImageOrientationLeftMirrored:
			case UIImageOrientationLeft:
			case UIImageOrientationRightMirrored:
			case UIImageOrientationRight:
				newSize.width = myImage.size.height;
				newSize.height = myImage.size.width;
				UIGraphicsBeginImageContext(newSize);
				break;
				
			case UIImageOrientationUpMirrored:
			case UIImageOrientationUp:
			case UIImageOrientationDownMirrored:
			case UIImageOrientationDown:				
			default:
				UIGraphicsBeginImageContext(myImage.size);
				break;
		}
		
		CGContextRef context = UIGraphicsGetCurrentContext();
		
		// Flip image from OpenGl land to Core Graphics land
		CGContextScaleCTM(context, 1.0, -1.0);
		CGContextTranslateCTM(context, 0.0, -(float)_height);
		
		switch (orientation) {				
			case UIImageOrientationUpMirrored:
			case UIImageOrientationDownMirrored:
			case UIImageOrientationLeftMirrored:
			case UIImageOrientationRightMirrored:
				CGContextScaleCTM(context, -1.0, 1.0);
				break;
			default:
				break;
		}

		switch (orientation) {				
			case UIImageOrientationUp:
			case UIImageOrientationUpMirrored:
				break;
				
			case UIImageOrientationDown:
			case UIImageOrientationDownMirrored:
				CGContextRotateCTM(context, M_PI);
				CGContextTranslateCTM(context, -(float)_width, -(float)_height);
				break;
				
			case UIImageOrientationLeft:
			case UIImageOrientationLeftMirrored:
				CGContextRotateCTM(context, M_PI / 2.0);
				CGContextTranslateCTM(context, fabs((float)_height - (float)_width), -(float)_height);
				break;
				
			case UIImageOrientationRight:
			case UIImageOrientationRightMirrored:
				CGContextRotateCTM(context, -M_PI / 2.0);
				CGContextTranslateCTM(context, -(float)_height, 0.0);
				break;
				
			default:
				break;
		}
		
		[myImage drawAtPoint:CGPointMake(0, 0)];
		
		UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
				
		return ret;		
	}
	return nil;
}


- (void) updateWithTimeElapsed:(float)time {
	
	if (_fader.opacity == 1.0) {	
		if (!_fboAllocated && [_dots count] > 0) {
			[self allocateFbo];
			[self redrawTexture];
		}
		
		if (_dotsDrawn < nextDotIndex) {
			
			if (nextDotIndex == [_dots count]) {
				while (_dotsDrawn < nextDotIndex) {
					[self fillHistoryBuffer];
					[self flushHistoryBuffer];
				}
			} else {
				while (_dotsDrawn + HISTORY_BUFFER_SIZE / 2 < nextDotIndex) {
					[self fillHistoryBuffer];
					[self flushHistoryBufferWithDots:HISTORY_BUFFER_SIZE / 2];
				}
				[self fillHistoryBuffer];
			}
		} else if (_dotsDrawn > nextDotIndex) {
			[self redrawTexture];
			
			if (nextDotIndex > HISTORY_BUFFER_SIZE / 2) {
				[self fillHistoryBuffer];
				[self flushHistoryBufferWithDots:(nextDotIndex - HISTORY_BUFFER_SIZE / 2) % HISTORY_BUFFER_SIZE];
			}
			
			[self fillHistoryBuffer];
			while (_dotsDrawn + HISTORY_BUFFER_SIZE <= nextDotIndex) {
				[self flushHistoryBuffer];
				[self fillHistoryBuffer];
			}
		}
	}
}

- (void) nextSegmentWithX:(float)x_ y:(float)y_ {
	if (_fader.opacity == 1.0) {
		float d = sqrt((lastDotX - x_) * (lastDotX - x_) + (lastDotY - y_) * (lastDotY - y_));
		
		float fSteps = d * 2;
		int iSteps = lrintf(floor(fSteps));
		
		if (iSteps > 0 && nextDotIndex < [_dots count]) {
			NSRange range = {
				.location = nextDotIndex,
				.length = [_dots count] - nextDotIndex,
			};
			
			[_dots removeObjectsInRange:range];
			
			if (nextDotIndex < _firstNewDot) {
				_firstNewDot = nextDotIndex;
			}
		}
		
		float xStep = (x_ - lastDotX) / fSteps;
		float yStep = (y_ - lastDotY) / fSteps;
		
		float dotX = lastDotX + xStep;
		float dotY = lastDotY + yStep;

		for (int step = 0; step < iSteps; step++) {
			if (dotX >= X_BORDER && dotX < _width - X_BORDER && dotY >= Y_BORDER && dotY < _height - Y_BORDER) {				
				Dot *dot = [Dot alloc];
				dot->x = dotX + (rand() % 3) - 1;
				dot->y = dotY + (rand() % 3) - 1;

				[_dots addObject:dot];
				[dot release];
				
				nextDotIndex++;
				
				lastDotX = dotX;
				lastDotY = dotY;

				x = dotX;
				y = dotY;
				
				dotX += xStep;
				dotY += yStep;
			} else {
				break;
			}
		}

		if (x_ >= X_BORDER && x_ < _width - X_BORDER) {
			x = x_;
		}
		if (y_ >= Y_BORDER && y_ < _height - Y_BORDER) {
			y = y_;
		}
	}
}

- (void) clearWithDuration:(float)duration {
	// Flush everytihng(ish) to the screen
	NSRange range = { .location = nextDotIndex, .length = [_dots count] - nextDotIndex };
	[_dots removeObjectsInRange:range];
	[self updateWithTimeElapsed:0.0];
	
	nextDotIndex = 0;
	[_fader fadeOut];

	[_dots removeAllObjects];
		
	_dotsDrawn = 0;
	nextDotIndex = 0;
	_originalCursorPosition = 0;
	_firstNewDot = 0;
	_dotsInHistoryBuffer = 0;
	headerCount = 0;
}

@dynamic nextDotIndex;

- (void) setNextDotIndex:(unsigned int)index {
	if (index > [_dots count]) {
		index = [_dots count];
	}
	nextDotIndex = index;
	
	if (nextDotIndex > 0) {
		Dot *dot = [_dots objectAtIndex:nextDotIndex - 1];
		x = dot->x;
		y = dot->y;
		
		lastDotX = x;
		lastDotY = y;
	} else if ([_dots count] > 0) {
		Dot *dot = [_dots objectAtIndex:0];
		x = dot->x;
		y = dot->y;
		
		lastDotX = x;
		lastDotY = y;
	}
}

- (unsigned int) nextDotIndex {
	return nextDotIndex;
}

- (void) draw {
	float opacity = _fader.opacity;
	
	if (backTexture != nil) {
		glEnableClientState(GL_TEXTURE_COORD_ARRAY);
		glEnableClientState(GL_VERTEX_ARRAY);
		
		glEnable(GL_TEXTURE_2D);
			
		// Draw background (with some dots)
		if (_fboAllocated) {
			GLfloat coordinates[] = {
				0.0, 0.0,
				_width / (float)_textureWidth, 0.0,
				0.0, _height / (float)_textureHeight,
				_width / (float)_textureWidth, _height / (float)_textureHeight
			};	
			
			GLfloat vertices[] = {
				0.0, _height,
				_width, _height,
				0.0, 0.0,
				_width, 0.0
			};
			
			glBindTexture(GL_TEXTURE_2D,  _texture);
			glVertexPointer(2, GL_FLOAT, 0, vertices);
			glTexCoordPointer(2, GL_FLOAT, 0, coordinates);

			glColor4f(1.0, 1.0, 1.0, 1.0);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
		} else {
			GLfloat coordinates[] = {
				0.0, backTexture.contentSize.height / (float)backTexture.pixelsHigh,
				backTexture.contentSize.width / (float)backTexture.pixelsWide, backTexture.contentSize.height / (float)backTexture.pixelsHigh,
				0.0, 0.0,
				backTexture.contentSize.width / (float)backTexture.pixelsWide, 0.0
			};	
			
			GLfloat vertices[] = {
				0.0, _height,
				_width, _height,
				0.0, 0.0,
				_width, 0.0
			};
			
			glBindTexture(GL_TEXTURE_2D, backTexture.name);
			glVertexPointer(2, GL_FLOAT, 0, vertices);
			glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			
			glColor4f(1.0, 1.0, 1.0, 1.0);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		}

		// Draw any missing dots
		if (_dotsDrawn < nextDotIndex) {
			glBindTexture(GL_TEXTURE_2D, drawTexture.name);
			
			glEnable(GL_BLEND);
			glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			
			glVertexPointer(2, GL_FLOAT, sizeof(VertexData), &_historyBuffer[0].vertexX);
			glTexCoordPointer(2, GL_FLOAT, sizeof(VertexData), &_historyBuffer[0].coordX);
			
			glColor4f(OPACITY, OPACITY, OPACITY, OPACITY);
			glDrawArrays(GL_TRIANGLES, 0, (nextDotIndex - _dotsDrawn) * 6);
			
			glDisable(GL_BLEND);
		}
		
		if (opacity < 1.0) {
			GLfloat coordinates[] = {
				0.0, backTexture.contentSize.height / (float)backTexture.pixelsHigh,
				backTexture.contentSize.width / (float)backTexture.pixelsWide, backTexture.contentSize.height / (float)backTexture.pixelsHigh,
				0.0, 0.0,
				backTexture.contentSize.width / (float)backTexture.pixelsWide, 0.0
			};	
			
			GLfloat vertices[] = {
				0.0, _height,
				_width, _height,
				0.0, 0.0,
				_width, 0.0
			};
			
			glEnable(GL_BLEND);
			glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
			
			glColor4f(1.0 - opacity, 1.0 - opacity, 1.0 - opacity, 1.0 - opacity);
			
			glBindTexture(GL_TEXTURE_2D, backTexture.name);
			glVertexPointer(2, GL_FLOAT, 0, vertices);
			glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
			
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
			
			glDisable(GL_BLEND);
		}
		
		glDisableClientState(GL_TEXTURE_COORD_ARRAY);
		glDisableClientState(GL_VERTEX_ARRAY);
		
		glDisable(GL_TEXTURE_2D);
	}
}

- (unsigned int) dotCount {
	return [_dots count];
}

- (void) fadedIn {
}

- (void) fadedOut {
	[_fader autorelease];
	_fader = [[Fader alloc] initWithTime:FADE_TIME fadedIn:TRUE min:0.0 max:1.0];
	[_fader addListener:self];
	[self redrawTexture];
	
	[_listener screenCleared];
}

@end
