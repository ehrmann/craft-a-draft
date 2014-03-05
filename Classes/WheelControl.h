//
//  WheelControl.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 4/30/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Drawable.h"
#import "Updatable.h"
#import "WheelControlListener.h"

@class Texture2D;
@class Fader;

float getCoterminal(float theta);

@interface WheelControl : NSObject <Drawable, Updatable> {
	float _x;
	float _y;
	
	float _width;
	float _height;
	
	float controlTheta;
	float _lastTouchTheta;
	
	float _radToInt;
	float _bufferedDelta;
	
	Texture2D *_texture;
	
	Fader *_fader;
	Fader *_dimmer;
	
	id<WheelControlListener> _listener;
	
	UITouch *_touch;
}

- (id)initWithTexture:(Texture2D *)texture fadedIn:(BOOL)fadedIn x:(int)x y:(int)y;
- (id)initWithTexture:(Texture2D *)texture fadedIn:(BOOL)fadedIn x:(int)x y:(int)y width:(float)width height:(float)height;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

- (void) setListener:(id<WheelControlListener>)listener;
- (void) setRadToInt:(float)radToInt;

- (void) brighten;
- (void) dim;

-(void) fadeOut;
-(void) fadeIn;

@property (readwrite,assign) float controlTheta;


@end
