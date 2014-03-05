//
//  Menu.h
//  CraftADraft
//
//  Created by David Ehrmann on 11/16/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "Updatable.h"
#import "MenuListener.h"
#import "FaderListener.h"

@class Texture2D;
@class Fader;

@interface Menu : NSObject <Updatable, Drawable, FaderListener> {	
	float _x;
	float _y;
	CGSize _size;
	
	NSMutableSet *_activeTouches;
	UITouch *_mostRecentTouch;
	NSMutableArray *_listeners;
	NSMutableArray *_icons;
	NSDate *_fadeInTime;
	NSDate *_fadeOutTime;
	BOOL _irrevocableFadeout;
	Texture2D *_depressedIcon;
	Fader *_blackFader;
	Fader *_fader;
	float _opacity;
}

//- (id) initWithWidth:(unsigned int)width height:(unsigned int)height;
- (id) initWithSize:(CGSize)size x:(float)x y:(float)y;

- (void) addIcon:(Texture2D *)icon;
- (void) addIcon:(Texture2D *)icon atIndex:(unsigned int)index;
- (void) removeIcon:(Texture2D *)icon;
- (void) removeIconAtIndex:(unsigned int)index;
- (void) removeAllIcons;
- (Texture2D *) getIconAtIndex:(unsigned int)index;
- (unsigned int) iconCount;

- (void) addListener:(id<MenuListener>)listener;
- (void) removeListener:(id<MenuListener>)listener;

- (void) show;
- (void) hide;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

@end
