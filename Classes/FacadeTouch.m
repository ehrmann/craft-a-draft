//
//  FacadeTouch.m
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/16/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "FacadeTouch.h"


@implementation FacadeTouch

-(id)initWithPoint:(CGPoint)_point {
	point = _point;
	return self;
}

- (CGPoint)locationInView:(UIView *)view {
	return point;
}

@synthesize point;



@end
