//
//  CanvasScreen.h
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Drawable.h"
#import "Updatable.h"
#import "FaderListener.h"
#import "CraftADraftListener.h"

typedef struct {
	GLfloat vertexX;
	GLfloat vertexY;
	GLfloat coordX;
	GLfloat coordY;
} VertexData;

@interface CanvasScreenUpdateState : NSObject {
@public
	unsigned int nextDotIndex;
	unsigned int cursorIndex;
}

@end

@class Fader;


@interface CanvasScreen : NSObject <Drawable, Updatable, FaderListener> {
	unsigned int _width;
	unsigned int _height;
	
	float x;
	float y;
	
	float lastDotX;
	float lastDotY;
	
	int _state;
	
	GLuint _texture;
	GLuint _fbo;
	GLuint _depthBuffer;
	bool _fboAllocated;
	
	unsigned int _textureWidth;
	unsigned int _textureHeight;
	
	Fader *_fader;
	
	unsigned int nextDotIndex;

	NSDate *_fadeStart;
	NSMutableArray *_dots;
	unsigned int _dotsDrawn;
	
	VertexData *_historyBuffer;
	unsigned int _dotsInHistoryBuffer;
	
	unsigned int _firstNewDot;
	unsigned int _originalCursorPosition;
	
	unsigned int headerCount;
	
	UITouch *_xTouch;
	UITouch *_yTouch;
	UITouch *_menuTouch;
	
	id<CraftADraftListener> _listener;
	
	BOOL _menuVisible;
}

- (id) initWithWidth:(unsigned int)width height:(unsigned int) height;
- (void) nextSegmentWithX:(float)x y:(float)y;
- (void) clearWithDuration:(float)duration;
//- (UIImage *) getUIImage;
- (UIImage *) getUIImageWithOrientation:(UIImageOrientation) orientation;

- (void) setData:(NSData *)nsData;
- (NSMutableData *) getData;
- (NSMutableData *) getDataUpdate;
- (void)setListener:(id<CraftADraftListener>)listener;

@property (readwrite,assign) float x;
@property (readwrite,assign) float y;

@property (readonly) unsigned int dotCount;
@property (readwrite,assign) unsigned int nextDotIndex;
@property (readonly) unsigned int headerCount;

@end
