//
//  WheelControlListener.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/10/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WheelControl;

@protocol WheelControlListener

-(void)wheelTurned:(int)delta wheel:(WheelControl *)wheel;

@end
