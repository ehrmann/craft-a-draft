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

typedef enum {
	CONTROL_STATE_BRIGHT,
	CONTROL_STATE_DIM,
	CONTROL_STATE_BRIGHTNING,
	CONTROL_STATE_DIMMING,
} ControlState;

@class Texture2D;
@class Fader;

@interface Controls : NSObject <Drawable, Updatable> {
	int _xControlX;
	int _xControlY;
	int _yControlX;
	int _yControlY;
	
	float xControlTheta;
	float yControlTheta;
	
	float _xOpacity;
	float _yOpacity;
	
	ControlState _xState;
	ControlState _yState;
	
	NSDate *_xDate;
	NSDate *_yDate;
	
	Texture2D *_xTexture;
	Texture2D *_yTexture;
	
	Fader *_fader;
}

- (Controls *)initWithXControlX:(int)xControlX xControlY:(int)xControlY yControlX:(int)yControlX yControlY:(int)yControlY;

- (void) brightenX;
- (void) brightenY;
- (void) dimX;
- (void) dimY;

-(void) fadeOut;
-(void) fadeIn;

@property (readwrite,assign) float xControlTheta;
@property (readwrite,assign) float yControlTheta;


@end
