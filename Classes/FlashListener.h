//
//  FlashListener.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/13/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Screen.h"

@protocol FlashListener <NSObject>

-(void)flashBrightest;
-(void)flashDone;

@end
