//
//  TreadWheel.h
//  CraftADraft
//
//  Created by David Ehrmann on 3/7/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Drawable.h"
#import "Updatable.h"


@interface TreadWheel : NSObject <Drawable, Updatable> {

	float _width;
	float _height;
	
	float _wheelHeight;
	float _wheelWidth;
	
	float _theta;
	unsigned int _teeth;
}

- (id) init;

@end
