//
//  FacadeTouch.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/16/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FacadeTouch : UITouch {
	CGPoint point;
}

-(id)initWithPoint:(CGPoint)_point;

@property (readwrite,assign) CGPoint point;

@end
