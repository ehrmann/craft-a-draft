//
//  FlashScreen.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/13/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Screen.h"
#import "FlashListener.h"
#import "FaderListener.h"

@class Fader;
@class CanvasScreen;

@interface FlashScreen : NSObject <Drawable, Updatable, FaderListener> {
	CGSize _size;
	Fader *_fader;
	id<FlashListener> _listener;
	float _opacity;
	BOOL _oneDraw;
}

-(id)initWithSize:(CGSize)size;
-(void)setListener:(id<FlashListener>)listener;
-(void)flash;
-(void)updateWithTimeElapsed:(float)time;
-(void)draw;


@end
