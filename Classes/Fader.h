//
//  Fader.h
//  CraftADraft
//
//  Created by David Ehrmann on 2/20/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Fader : NSObject {
	float _opacity;
	float _min;
	float _max;
	unsigned int _state;
	NSDate *_stateChange;
	float _fadeTime;
	NSMutableSet *_listeners;
}

-(id)initWithTime:(float)time fadedIn:(BOOL)fadedIn min:(float)min max:(float)max;
-(void)fadeIn;
-(void)fadeOut;
-(void)fadeReverse;
-(void)addListener:(id)listener;
-(void)removeListener:(id)listener;

@property (readonly) float opacity; 

@end
