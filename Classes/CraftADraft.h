//
//  CraftADraft.h
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "Drawable.h"
#import "Updatable.h"
#import "MenuListener.h"
#import "CraftADraftListener.h"
#import "FlashListener.h"

@class CanvasScreen;
@class Controls;
@class TimeControl;
@class ScreenSelector;
@class Menu;
@class CursorOverlay;
@class WheelControl;
@class DrawScreen;
@class TimeScreen;
@class CursorScreen;
@class Screen;
@class FlashScreen;

@interface CraftADraft : NSObject <Drawable, Updatable, CraftADraftListener, FlashListener, UIAccelerometerDelegate> {
	@public

	DrawScreen *_drawScreen[4];
	TimeScreen *_timeScreen[4];
	CursorScreen *_cursorScreen[4];
	Screen *_activeScreen;
	FlashScreen *_flashScreen;
	
	NSMutableArray *_screens;
	DrawScreen *_blankScreen;
	
	NSMutableDictionary *_touchMap;

	
	
	NSDate *_lastBigA;
	int _bigACount;
@private
	float _screenPosition;
	
	int _orientation;
	
	NSDate *_lockDate;
	
	CFMutableDictionaryRef _screenToFile;
	
	NSNotification *_pendingRotate;
}

+(CraftADraft *)sharedCraftADraft;
-(CraftADraft *)init;

- (void)saveScreens;
- (void)loadScreens;

-(void) receivedRotate: (NSNotification*) notification;

//- (void)setPositionWithX:(int)x y:(int)y;
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event;

@end
