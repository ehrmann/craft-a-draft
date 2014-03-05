//
//  Epicycloid.m
//  CraftADraft
//
//  Created by David Ehrmann on 10/26/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import "Epicycloid.h"
#import "CraftADraft.h"

#define min(a,b) ((a) < (b) ? (a) : (b))

@implementation Epicycloid

- (Epicycloid *) initWithDrawer:(CraftADraft *)craftADraft {
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	
	_craftADraft = craftADraft;
	
	_theta = 0;
	_q = 2 + rand() % 7;
	_p = 4 + rand() % 7;
	
	if (_p >= _q) {
		_p++;
	}
	
	for (int i = 2; i <= 14; i++) {
		while (_q % i == 0 && _p % i == 0) {
			_q /= i;
			_p /= i;
		}
	}
	
	if (_p / _q == 2) {
		_p = 5;
		_q = 3;
	}
	
	float maxR = min(cgRect.size.width, cgRect.size.height) * 3 / 8;
	
	// k = p / q
	// r1 = k * r2
	// r1 + 2 * r2 = maxR
	
	// maxR - 2 * r2 = k * r2
	// maxR = r2 * (k + 2)
	// r2 = maxR / (k + 2)
	
	float k = (float)_p / (float)_q;
	_r2 = maxR / (k + 2);
	_r1 = k * _r2;
	
	return self;
}

- (BOOL) iterateWithDuration:(float)duration totalDuration:(float)totalDuration {
	if (_theta >= 2 * M_PI * _q) {
		return true;
	}
	
	CGRect cgRect =[[UIScreen mainScreen] bounds];
	int width = cgRect.size.width;
	int height = cgRect.size.height;
	
	float increment = 1.0 / ((_r1 + _r2) * 2);
	float target = _theta + 2.0 * M_PI * _q * (duration / totalDuration);

	NSDate *date = [NSDate date];
	[date retain];

	do {
		int x = width / 2 + (int)((_r1 + _r2) * cos(_theta) - (_r2) * cos(_theta * (_r1 + _r2) / _r2));
		int y = height / 2 + (int)((_r1 + _r2) * sin(_theta) - (_r2) * sin(_theta * (_r1 + _r2) / _r2));
		[_craftADraft setPositionWithX:x y:y];
		
		_theta += increment;
	} while (-[date timeIntervalSinceNow] < duration && _theta <= target);
	
	[date release];

	return (_theta >= 2 * M_PI * _q);
}

@end
