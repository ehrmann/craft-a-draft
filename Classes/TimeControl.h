//
//  TimeControl.h
//  CraftADraft
//
//  Created by David Ehrmann on 2/21/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "Updatable.h"


@class Texture2D;
@class Fader;

@interface TimeControl : NSObject <Drawable, Updatable> {
	int _controlX;
	int _controlY;
	
	float controlTheta;
	
	Texture2D *_texture;
	
	Fader *_dimmer;
	Fader *_fader;
}

- (id)initFadedOutWithX:(int)x y:(int)y;
- (id)initFadedInWithX:(int)x y:(int)y;

- (void) brighten;
- (void) dim;

-(void) fadeOut;
-(void) fadeIn;

@property (readwrite,assign) float controlTheta;

@end
