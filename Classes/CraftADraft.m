//
//  CraftADraft.m
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import "CraftADraft.h"

#import "Controls.h"
#import "CanvasScreen.h"
#import "ScreenSelector.h"
#import "Menu.h"
#import "Texture2D.h"
#import "TimeControl.h"
#import "CursorOverlay.h"
#import "WheelControl.h"
#import "UiConstants.h"
#import "DrawScreen.h"
#import "CursorScreen.h"
#import "TimeScreen.h"
#import "FlashScreen.h"
#import "FacadeTouch.h"

static const unsigned int MAX_SCREENS = 8;

static const void *myRetainCallback (CFAllocatorRef allocator,const void *value) {
	[(NSObject *)value retain];
	return value;
}

static void myReleaseCallback (CFAllocatorRef allocator, const void *value) {
	[(NSObject *)value release];
}


@implementation CraftADraft

+(CraftADraft *)sharedCraftADraft
{
	static CraftADraft *sharedCraftADraft;
	
	@synchronized(self)
	{
		if (!sharedCraftADraft) {
			sharedCraftADraft = [[CraftADraft alloc] init];
		}
		
		return sharedCraftADraft;
	}
	
	return NULL;
}

-(CraftADraft *)init {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	
	unsigned int width = cgRect.size.width;
	unsigned int height = cgRect.size.height;
	
	
	_screens = [[NSMutableArray alloc] initWithCapacity:MAX_SCREENS];
	
	[_screens addObject:[[[CanvasScreen alloc] initWithWidth:width height:height] autorelease]];
	[[_screens objectAtIndex:0] setListener:self];
	
	_blankScreen = [[CanvasScreen alloc] initWithWidth:width height:height];
	
	_screenPosition = 0.0;
	
	_bigACount = 0;
	_lastBigA = nil;
	
	_lockDate = nil;
	_pendingRotate = nil;
	
	[UIAccelerometer sharedAccelerometer].updateInterval = 1.0 / 60;
	[UIAccelerometer sharedAccelerometer].delegate = self;
	
	CFDictionaryKeyCallBacks keyCallbacks = {
		.version = 0,
		.retain = myRetainCallback,
		.release = myReleaseCallback,
		.copyDescription = NULL,
		.equal = NULL,
		.hash = NULL,
	};
	
	CFDictionaryValueCallBacks valueCallbacks = {
		.version = 0,
		.retain = myRetainCallback,
		.release = myReleaseCallback,
		.copyDescription = NULL,
		.equal = NULL,
	};
	
	_screenToFile = CFDictionaryCreateMutable (NULL, 0, &keyCallbacks, &valueCallbacks);
										//			  CFAllocatorRef allocator,
									//				  CFIndex capacity,
									//				  const CFDictionaryKeyCallBacks *keyCallBacks,
									//				  const CFDictionaryValueCallBacks *valueCallBacks
	
	
	_orientation = 0;

	CGSize portraitSize = CGSizeMake(width, height);
	CGSize landscapeSize = CGSizeMake(height, width);
	
	for (int i = 0; i < 4; i++) {
		CGSize size;
		if (i % 2 == 0) {
			size = portraitSize;
		} else {
			size = landscapeSize;
		}
		
		if (i == _orientation) {
			_drawScreen[i] = [[DrawScreen alloc] initWithSize:size fadedIn:TRUE];
		} else {
			_drawScreen[i] = [[DrawScreen alloc] initWithSize:size fadedIn:FALSE];
		}
		_timeScreen[i] = [[TimeScreen alloc] initWithSize:size fadedIn:FALSE];
		_cursorScreen[i] = [[CursorScreen alloc] initWithSize:size fadedIn:FALSE];
		
		[_drawScreen[i] setListener:self];
		[_timeScreen[i] setListener:self];
		[_cursorScreen[i] setListener:self];
	}
	
	_activeScreen = _drawScreen[_orientation];
	
	_touchMap = [[NSMutableDictionary alloc] initWithCapacity:16];
	
	
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedRotate:) name: UIDeviceOrientationDidChangeNotification object: nil];
	
	[self loadScreens];
	
	return self;
}

- (int) getScreenIndex {
	int index = lrintf(_screenPosition);
	
	if (index < 0) {
		return 0;
	} else if (index >= [_screens count]) {
		return [_screens count] - 1;
	} else {
		return index;
	}
}

/*
- (void)setPositionWithX:(int)x y:(int)y {
	float deltaX = _CanvasScreen.x - x;
	float deltaY = _CanvasScreen.y - y;
	
	if (deltaX > 2.0 || deltaX < -2.0 || deltaY > 2.0 || deltaY < -2.0) {
		[_CanvasScreen nextSegmentWithX:x y:y];
	}
	
	float newXTheta = deltaX / THETA_TO_DISTANCE;
	float newYTheta = deltaY / THETA_TO_DISTANCE;
	
	_controls.yControlTheta += newXTheta;
	_controls.xControlTheta += newYTheta;
}
*/

- (void)loadScreens {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	
	unsigned int width = cgRect.size.width;
	unsigned int height = cgRect.size.height;
	
	NSMutableArray *screenFiles = [[NSMutableArray alloc] initWithCapacity:32];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [paths objectAtIndex:0];
	
	NSArray *archivedFiles = nil;
	@try {
		NSDictionary * rootObject = [NSKeyedUnarchiver unarchiveObjectWithFile:[path stringByAppendingPathComponent:@"screen_list"]];
		if (rootObject) {
			archivedFiles = [rootObject valueForKey:@"screenFiles"];
		} else {
			archivedFiles = nil;
		}
	}
	@catch (NSException *e) {
	}
	
	if (archivedFiles) {
		for (NSString *filename in archivedFiles) {
			[screenFiles addObject:[path stringByAppendingPathComponent:filename]];
		}
	}
	
	[[NSFileManager defaultManager] removeItemAtPath:[path stringByAppendingPathComponent:@"screen_list"] error:NULL];
	
	if (!archivedFiles) {
		NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:NULL];
		
		for (NSString *filename in dirContents) {
			if (strncmp("screen.", [filename UTF8String], strlen("screen.")) != 0) {
				continue;
			}
			
			const char *start = [filename UTF8String] + strlen("screen.");
			char *end;
			int screen = strtol(start, &end, 10);
			if (screen == 0 && *end != '\0') {
				continue;
			}
			
			[screenFiles addObject:[path stringByAppendingPathComponent:filename]];
		}
	}
	
	for (int i = 0; i < [screenFiles count] && [_screens count] <= MAX_SCREENS; i++) {
		NSString *filename = (NSString *)[screenFiles objectAtIndex:i];
		NSData *data = [[NSFileManager defaultManager] contentsAtPath:filename];
		
		if (data != nil) {
			CanvasScreen *ds = (CanvasScreen *)[_screens objectAtIndex:[_screens count] - 1];
			[ds setData:data];
			if (ds.dotCount > 0) {
				if ([_screens count] < MAX_SCREENS) {
					CanvasScreen *newScreen = [[CanvasScreen alloc] initWithWidth:width height:height];
					[newScreen setListener:self];
					[_screens addObject:[newScreen autorelease]];
				}
				
				CFDictionaryAddValue(_screenToFile, ds, filename);
			}
		}
	}
		
	[screenFiles release];
}

- (void)flushScreen:(CanvasScreen *)screen {
	if (screen.dotCount > 0) {
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *path = [paths objectAtIndex:0];
		
		NSData *data;
		
		const char *mode = "a";

		if (screen.headerCount > 10) {
			data = [screen getData];
			mode = "w";
		} else {
			data = [screen getDataUpdate];
		}

		
		if (data == nil) {
			return;
		}
		
		NSString *filename = (NSString *)CFDictionaryGetValue(_screenToFile, screen);
		if (!filename) {
			int suffix = rand() % 32768;
			int attempts = 0;
			NSString *testString = nil;
			do {
				testString = [NSString stringWithFormat:@"screen.%d", suffix];
				
				unsigned int dictionarySize = CFDictionaryGetCount(_screenToFile);
				NSString **values = malloc(sizeof(NSString *) * dictionarySize);
				if (values == NULL) {
					testString = nil;
					break;
				}
				
				CFDictionaryGetKeysAndValues(_screenToFile, NULL, (const void **)values);
				
				for (unsigned int i = 0; i < dictionarySize; i++) {
					NSString *otherFilename = values[i];
					
					if ([otherFilename compare:[path stringByAppendingPathComponent:testString]] == NSOrderedSame) {
						testString = nil;
						suffix++;
						break;
					}
				}
				
				free(values);
				
				if (suffix >= 32768) {
					suffix = 0;
				}
				attempts++;
			} while (testString == nil && attempts < 32);
			
			if (testString == nil) {
				return;
			}
			
			filename = [path stringByAppendingPathComponent:testString];
			CFDictionarySetValue(_screenToFile, screen, filename);
		}
		
		FILE *fp = fopen([filename UTF8String], mode);
		if (fp != NULL) {
			fwrite([data bytes], 1, [data length], fp);
			fclose(fp);
		}
	}
}

- (void)saveScreens {
	
	NSMutableArray *screenFilenames = [[NSMutableArray alloc] initWithCapacity:8];
	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *path = [paths objectAtIndex:0];
	
	for (int i = 0; i < [_screens count]; i++) {
		CanvasScreen *ds = (CanvasScreen *)[_screens objectAtIndex:i];
		
		[self flushScreen:ds];
		NSString *filename = (NSString *)CFDictionaryGetValue(_screenToFile, ds);
		if (filename) {
			[screenFilenames addObject:[filename lastPathComponent]];
		}
	}
	
	if ([screenFilenames count] > 0) {
		NSMutableDictionary * rootObject = [NSMutableDictionary dictionary]; 
		[rootObject setValue:screenFilenames forKey:@"screenFiles"];
	
		[NSKeyedArchiver archiveRootObject: rootObject toFile:[path stringByAppendingPathComponent:@"screen_list"]]; 
	}
	
	[screenFilenames release];
}

- (void)translateTouch:(FacadeTouch *) touch {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	
	if (_orientation == 1) {
		touch.point = CGPointMake(cgRect.size.height - touch.point.y, touch.point.x);
	} else if (_orientation == 2) {
		touch.point = CGPointMake(cgRect.size.width - touch.point.x, cgRect.size.height - touch.point.y);
	} else if (_orientation == 3) {
		touch.point = CGPointMake(touch.point.y, cgRect.size.width - touch.point.x);
	}
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_lockDate == nil) {
		NSMutableSet *touchSet = [[[NSMutableSet alloc] initWithCapacity:4] autorelease];
		
		for (UITouch *touch in touches) {
			FacadeTouch *newTouch = [[[FacadeTouch alloc] initWithPoint:[touch locationInView:nil]] autorelease];
			[self translateTouch:newTouch];
			NSValue *key = [NSValue valueWithPointer:touch];
			[_touchMap setObject:newTouch forKey:key];
			[touchSet addObject:newTouch];
		}
		
		[_activeScreen touchesBegan:touchSet withEvent:event];
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	
	NSMutableSet *touchSet = [[[NSMutableSet alloc] initWithCapacity:4] autorelease];
	
	for (UITouch *touch in touches) {
		NSValue *key = [NSValue valueWithPointer:touch];
		FacadeTouch *newTouch = [_touchMap objectForKey:key];
		if (newTouch != nil) {
			newTouch.point = [touch locationInView:nil];
			[self translateTouch:newTouch];
			[touchSet addObject:newTouch];
		}
	}
	
	[_activeScreen touchesMoved:touchSet withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	
	NSMutableSet *touchSet = [[[NSMutableSet alloc] initWithCapacity:4] autorelease];
	
	for (UITouch *touch in touches) {
		NSValue *key = [NSValue valueWithPointer:touch];
		FacadeTouch *newTouch = [_touchMap objectForKey:key];
		if (newTouch != nil) {
			newTouch.point = [touch locationInView:nil];
			[self translateTouch:newTouch];
			[touchSet addObject:newTouch];
		}
	}
	
	[_activeScreen touchesEnded:touchSet withEvent:event];
	
	for (int i = 0; i < 4; i++) {
		[_drawScreen[i] touchesEnded:touchSet withEvent:event];
		[_timeScreen[i] touchesEnded:touchSet withEvent:event];
		[_cursorScreen[i] touchesEnded:touchSet withEvent:event];
	}
	
	for (UITouch *touch in touches) {
		NSValue *key = [NSValue valueWithPointer:touch];
		[_touchMap removeObjectForKey:key];
	}
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	NSMutableSet *touchSet = [[[NSMutableSet alloc] initWithCapacity:4] autorelease];
	
	for (UITouch *touch in touches) {
		NSValue *key = [NSValue valueWithPointer:touch];
		FacadeTouch *newTouch = [_touchMap objectForKey:key];
		if (newTouch != nil) {
			newTouch.point = [touch locationInView:nil];
			[self translateTouch:newTouch];
			[touchSet addObject:newTouch];
		}
	}
	
	[_activeScreen touchesCancelled:touchSet withEvent:event];
	
	for (int i = 0; i < 4; i++) {
		[_drawScreen[i] touchesCancelled:touchSet withEvent:event];
		[_timeScreen[i] touchesCancelled:touchSet withEvent:event];
		[_cursorScreen[i] touchesCancelled:touchSet withEvent:event];
	}
	
	for (UITouch *touch in touches) {
		NSValue *key = [NSValue valueWithPointer:touch];
		[_touchMap removeObjectForKey:key];
	}
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	/*
    if ( event.subtype == UIEventSubtypeMotionShake ) {
		int screen = lrintf(_screenPosition);
		if (fabs(_screenPosition - (float)screen) <= 1.0 / 512.0) {			
			for (id key in _touchMap) {
				id obj = [_touchMap objectForKey:key];
				[self touchesCancelled:[[NSSet setWithObject:obj] autorelease] withEvent:nil];
			}
			
			if (screen >= 0 && screen < [_screens count]) {
				[[_screens objectAtIndex:screen] clearWithDuration:0.9];
			}
		}
	}
	 */
}

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	
	float wi = acceleration.x;
	float wj = acceleration.y;
	
	// Make it less sensitive to z acceleration so setting it down isn't a clear
	float wk = acceleration.z / 2;
	
	float magnitude = sqrt(wi * wi + wj * wj + wk * wk);
	
	if (magnitude > 2.1) {
		if (_lastBigA && -[_lastBigA timeIntervalSinceNow] <= 1.0) {
			_bigACount++;
		} else {
			_bigACount = 1;
		}
		
		_lastBigA = [[NSDate date] retain];
		
		if (_bigACount == 3) {
			CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
			[screen clearWithDuration:21.4];
			
			NSString *filename = (NSString *)CFDictionaryGetValue(_screenToFile, screen);
			if (filename) {
				[[NSFileManager defaultManager] removeItemAtPath:filename error:NULL];
				CFDictionaryRemoveValue(_screenToFile, screen);
			}
			
			_bigACount = 0;
		}
	}
}


- (void) draw {
	CGRect cgRect =[[UIScreen mainScreen] bounds];

	// Draw canvas screen(s)
	int iLeftScreen = lrintf(floor(_screenPosition));
	int iRightScreen = lrintf(ceil(_screenPosition));
	
	DrawScreen *leftScreen = _blankScreen;
	DrawScreen *rightScreen = _blankScreen;
	
	if (iLeftScreen >= 0 && iLeftScreen < [_screens count]) {
		leftScreen = [_screens objectAtIndex:iLeftScreen];
	}
	
	if (iRightScreen >= 0 && iRightScreen < [_screens count]) {
		rightScreen = [_screens objectAtIndex:iRightScreen];
	}
	
	float lxOffset = 0;
	float lyOffset = 0;
	float rxOffset = 0;
	float ryOffset = 0;
	
	// Use ceil and floor so there's never a line between the backgrounds
	if (_orientation == 0) {
		lxOffset = floor((floor(_screenPosition) - _screenPosition) * cgRect.size.width);
		rxOffset = lxOffset + cgRect.size.width;
	} else if (_orientation == 1) {
		ryOffset = floor( (-1.0 - (floor(_screenPosition) - _screenPosition)) * cgRect.size.height);
		lyOffset = ryOffset + cgRect.size.height;
	} else if (_orientation == 2) {
		rxOffset = floor((-1.0 - (floor(_screenPosition) - _screenPosition)) * cgRect.size.width);
		lxOffset = rxOffset + cgRect.size.width;
	} else {
		lyOffset = floor((floor(_screenPosition) - _screenPosition) * cgRect.size.height);
		ryOffset = lyOffset + cgRect.size.height;
	}

	glPushMatrix();
	glTranslatef(lxOffset, lyOffset, 0.0);
	[leftScreen draw];
	glPopMatrix();
	
	if (iLeftScreen != iRightScreen) {
		glPushMatrix();
		glTranslatef(rxOffset, ryOffset, 0.0);
		[rightScreen draw];
		glPopMatrix();
	}
	
	glPushMatrix();
	
	if (_orientation == 1) {
		glTranslatef(cgRect.size.width / 2.0, cgRect.size.height / 2.0, 0.0);
		glRotatef(270.0, 0.0, 0.0, 1.0);
		glTranslatef(-cgRect.size.height / 2.0, -cgRect.size.width / 2.0, 0.0);
	} else if (_orientation == 2) {
		glTranslatef(cgRect.size.width / 2.0, cgRect.size.height / 2.0, 0.0);
		glRotatef(180.0, 0.0, 0.0, 1.0);
		glTranslatef(-cgRect.size.width / 2.0, -cgRect.size.height / 2.0, 0.0);
	} else if (_orientation == 3) {
		glTranslatef(cgRect.size.width / 2.0, cgRect.size.height / 2.0, 0.0);
		glRotatef(90.0, 0.0, 0.0, 1.0);
		glTranslatef(-cgRect.size.height / 2.0, -cgRect.size.width / 2.0, 0.0);
	}
	
	if (_activeScreen == _drawScreen[_orientation]) {
		[_timeScreen[_orientation] draw];
		[_cursorScreen[_orientation] draw];
	} else if (_activeScreen == _timeScreen[_orientation]) {
		[_cursorScreen[_orientation] draw];
		[_drawScreen[_orientation] draw];
	} else if (_activeScreen == _cursorScreen[_orientation]) {
		[_drawScreen[_orientation] draw];
		[_timeScreen[_orientation] draw];
	}
	
	[_activeScreen draw];
	
	glPopMatrix();
	
	[_flashScreen draw];
}

- (void) updateWithTimeElapsed:(float)time {	
	if (_lockDate != nil && -[_lockDate timeIntervalSinceNow] > 0.5) {
		[_lockDate release];
		_lockDate = nil;
	}
	
	[_activeScreen updateWithTimeElapsed:time];
	
	for (CanvasScreen *CanvasScreen in _screens) {
		[CanvasScreen updateWithTimeElapsed:time];
	}
	
	[_flashScreen updateWithTimeElapsed:time];
}

-(void) receivedRotate: (NSNotification*) notification {
	if (fabs(_screenPosition - floor(_screenPosition)) < 1.0 / 1024.0) {
		UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
		int oldOrientation = _orientation;
		
		if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
			_orientation = 1;
		} else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight) {
			_orientation = 3;
		} else if (interfaceOrientation == UIInterfaceOrientationPortrait) {
			_orientation = 0;
		} else if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
			_orientation = 2;
		}
		
		if (_orientation != oldOrientation) {
			// Cancel outstanding touches
			NSArray *touches = [_touchMap allKeys];
			NSMutableSet *touchSet = [NSMutableSet setWithCapacity:[touches count]];
			
			for (NSValue *touch in touches) {
				[touchSet addObject:[touch pointerValue]];
			}
			
			[self touchesEnded:touchSet withEvent:nil];
			
			// Lock the UI for 0.5 seconds
			_lockDate = [[NSDate date] retain];
			
			[_activeScreen fadeOut];
			
			if (_activeScreen == _drawScreen[oldOrientation]) {
				_activeScreen = _drawScreen[_orientation];
			} else if (_activeScreen == _timeScreen[oldOrientation]) {
				_activeScreen = _timeScreen[_orientation];
			} else if (_activeScreen == _cursorScreen[oldOrientation]) {
				_activeScreen = _cursorScreen[_orientation];
			}
			
			[_activeScreen fadeIn];
		}
		[_pendingRotate release];
		_pendingRotate = nil;
	} else {
		_pendingRotate = [notification retain];
	}
}

-(CGPoint)getCursor {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
	
	if (_orientation == 0) {
		return CGPointMake(screen.x, screen.y);
	} else if (_orientation == 1) {
		return CGPointMake(cgRect.size.height - screen.y, screen.x);
	} else if (_orientation == 2) {
		return CGPointMake(cgRect.size.width - screen.x, cgRect.size.height - screen.y);
	} else {
		return CGPointMake(screen.y, cgRect.size.width - screen.x);
	}
}

-(void)setCursor:(CGPoint)newPoint {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
	CGPoint tempPoint = newPoint;
	
	if (_orientation == 1) {
		tempPoint.x = newPoint.y;
		tempPoint.y = cgRect.size.height - newPoint.x;
	} else if (_orientation == 2) {
		tempPoint.y = cgRect.size.height - newPoint.y;
		tempPoint.x = cgRect.size.width - newPoint.x;
	} else if (_orientation == 3) {
		tempPoint.x = cgRect.size.width - newPoint.y;
		tempPoint.y = newPoint.x;
	}
	
	screen.x = tempPoint.x;
	screen.y = tempPoint.y;
}

-(void)cursorMoved:(CGPoint)newPoint {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	CGPoint tempPoint = newPoint;
	
	if (_orientation == 1) {
		tempPoint.x = newPoint.y;
		tempPoint.y = cgRect.size.height - newPoint.x;
	} else if (_orientation == 2) {
		tempPoint.y = cgRect.size.height - newPoint.y;
		tempPoint.x = cgRect.size.width - newPoint.x;
	} else if (_orientation == 3) {
		tempPoint.x = cgRect.size.width - newPoint.y;
		tempPoint.y = newPoint.x;
	}
	
	CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
	
	unsigned int initialDotCount = [screen dotCount];
	
	[screen nextSegmentWithX:tempPoint.x y:tempPoint.y];
	
	if (initialDotCount == 0 && [screen dotCount] > 0) {
		for (int i = [_screens count] - 2; i >= 0; i--) {
			if ([[_screens objectAtIndex:i] dotCount] == 0) {
				if (i < [self getScreenIndex]) {
					[_screens removeObjectAtIndex:i];
					_screenPosition -= 1.0;
				} else if (i >= [self getScreenIndex]) {
					[_screens removeObjectAtIndex:i];
				}
			}
		}
		
		if ([self getScreenIndex] == [_screens count] - 1 && [_screens count] < MAX_SCREENS) {
			CGRect cgRect =[[UIScreen mainScreen] bounds];
			CanvasScreen *newScreen = [[CanvasScreen alloc] initWithWidth:cgRect.size.width height:cgRect.size.height];
			[newScreen setListener:self];
			[_screens addObject:[newScreen autorelease]];
		}
	}
}

-(float)getScreen {
	return _screenPosition;
}

-(void)setScreen:(float)screen {
	_screenPosition = screen;
}

-(int)getScreenCount {
	return [_screens count];
}

-(void)screenChangeDone {
	// The last screen is allowed to be blank
	for (int i = [_screens count] - 2; i >= 0; i--) {
		if ([[_screens objectAtIndex:i] dotCount] == 0) {
			[_screens removeObjectAtIndex:i];
			if (_screenPosition - (float)i > -1.0 / 1024.0) {
				_screenPosition -= 1.0;
			}
		}
	}
	
	if (_screenPosition < 0.0) {
		_screenPosition = 0.0;
	}
	
	for (CanvasScreen* screen in _screens) {
		[self flushScreen:screen];
	}
	
	if (_pendingRotate) {
		[self receivedRotate:_pendingRotate];
	}
}

-(void)setDot:(unsigned int)dot {
	CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
	screen.nextDotIndex = dot;
}

-(unsigned int)getCurrentDot {
	CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
	return screen.nextDotIndex;
}

-(unsigned int)getDotCount {
	CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
	return screen.dotCount;
}

-(void)drawScreen {
	[_cursorScreen[_orientation] fadeOut];
	[_timeScreen[_orientation] fadeOut];
	
	_activeScreen = _drawScreen[_orientation];
	
	[_activeScreen fadeIn];
}

-(void)cursorScreen {
	[_drawScreen[_orientation] fadeOut];
	[_timeScreen[_orientation] fadeOut];
	
	_activeScreen = _cursorScreen[_orientation];
	
	[_activeScreen fadeIn];
}

-(void)timeScreen {
	[_drawScreen[_orientation] fadeOut];
	[_cursorScreen[_orientation] fadeOut];
	
	_activeScreen = _timeScreen[_orientation];
	
	[_activeScreen fadeIn];
}

-(void)screenshot {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	[_flashScreen release];
	_flashScreen = [[FlashScreen alloc] initWithSize:cgRect.size];
	[_flashScreen setListener:self];
	[_flashScreen flash];
}

-(void)flashBrightest {
	CanvasScreen *screen = [_screens objectAtIndex:[self getScreenIndex]];
	UIImage *image = [[screen getUIImageWithOrientation:UIImageOrientationUp] retain];
	if (image != nil) {
		UIImageWriteToSavedPhotosAlbum(image, self, nil, nil);
		[image release];
	}
}

-(void)flashDone {
	[_flashScreen release];
	_flashScreen = nil;
}

-(void)screenCleared {
	int count = [_screens count];
	if (count >= 2) {
		if ([[_screens objectAtIndex:count - 1] dotCount] == 0 &&
				[[_screens objectAtIndex:count - 2] dotCount] == 0) {
			[_screens removeObjectAtIndex:count - 1];
		}
	}
	/*
	for (int i = [_screens count] - 2; i >= 0; i--) {
		if ([[_screens objectAtIndex:i] dotCount] == 0) {
			if (i < [self getScreenIndex]) {
				[_screens removeObjectAtIndex:i];
				_screenPosition -= 1.0;
			} else if (i >= [self getScreenIndex]) {
				[_screens removeObjectAtIndex:i];
			}
		}
	}
	 */
}


@end
