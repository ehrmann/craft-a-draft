//
//  Screen.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/1/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

// #import <UIKit/UIKit.h>

#import "Drawable.h"
#import "Updatable.h"
#import "CraftADraftListener.h"



@class Texture2D;

extern Texture2D *_drawIcon;
extern Texture2D *_cameraIcon;
extern Texture2D *_cursorIcon;
extern Texture2D *_clockIcon;


@interface Screen : NSObject <Drawable, Updatable> {
	float _width;
	float _height;
	id<CraftADraftListener> _listener;
}

- (id)initWithSize:(CGSize)size;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;

- (void)setListener:(id<CraftADraftListener>)listener;

- (void)fadeIn;
- (void)fadeOut;

@end
