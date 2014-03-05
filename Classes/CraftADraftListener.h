//
//  CraftADraftListener.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 5/5/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol CraftADraftListener <NSObject>

-(CGPoint)getCursor;
-(void)setCursor:(CGPoint)newPoint;
-(void)cursorMoved:(CGPoint)newPoint;

-(float)getScreen;
-(void)setScreen:(float)screen;
-(int)getScreenCount;
-(void)screenChangeDone;

-(void)setDot:(unsigned int)dot;
-(unsigned int)getDotCount;
-(unsigned int)getCurrentDot;

-(void)drawScreen;
-(void)cursorScreen;
-(void)screenshot;
-(void)timeScreen;

-(void)screenCleared;

@end
