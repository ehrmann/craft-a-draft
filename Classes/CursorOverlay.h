//
//  CursorOverlay.h
//  CraftADraft
//
//  Created by David Ehrmann on 3/2/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Drawable.h"
#import "Updatable.h"

@class Texture2D;
@class Fader;

@interface CursorOverlay : NSObject <Drawable, Updatable> {
	unsigned int _width;
	unsigned int _height;
	
	float _cursorWidth;
	float _cursorHeight;
	
	float x;
	float y;
	
	Texture2D *_backTexture;
	Texture2D *_foreTexture;
	
	Fader *_fader;
}

- (id) initWithWidth:(unsigned int)width height:(unsigned int) height;
- (void) dealloc;
- (void) fadeIn;
- (void) fadeOut;

@property (readwrite,assign) float x;
@property (readwrite,assign) float y;

@end
