//
//  Controls.h
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "Updatable.h"
#import "CraftADraftListener.h"

@class Texture2D;
@class Fader;

@interface ScreenSelector : NSObject <Drawable, Updatable> {
	CGSize _size;
	
	unsigned int activeScreen;
	float swipePosition;
	float _screenVelocity;
	float _screenAcceleration;
	int _targetScreen;
	
	int _state;
	
	Texture2D *_brightScreenSelectorTexture;
	Texture2D *_dimScreenSelectorTexture;
	
	Fader *_fader;
	
	UITouch *_swipeTouch;
	NSDate *_lastScreenMove;
	CGPoint _lastSwipeLocation;
	
	id<CraftADraftListener> _listener;
}

- (id)initWithSize:(CGSize)size fadedIn:(BOOL)fadedIn;

- (void)fadeIn;
- (void)fadeOut;

- (void)setListener:(id<CraftADraftListener>)listener;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;


@end
