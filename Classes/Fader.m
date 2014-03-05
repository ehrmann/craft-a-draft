//
//  Fader.m
//  CraftADraft
//
//  Created by David Ehrmann on 2/20/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "Fader.h"
#import "FaderListener.h"

typedef enum {
	STATE_FADED_OUT,
	STATE_FADED_IN,
	STATE_FADING_OUT,
	STATE_FADING_IN,
} FaderState;

@implementation Fader

-(id)initWithTime:(float)time fadedIn:(BOOL)fadedIn min:(float)min max:(float)max {
	_min = min;
	_max = max;
	_fadeTime = time;
	_state = STATE_FADED_IN;
	_opacity = max;
	_stateChange = nil;

	if (fadedIn) {
		_state = STATE_FADED_IN;
	} else {
		_state = STATE_FADED_OUT;
	}
	
	_listeners = [[NSMutableSet alloc] initWithCapacity:4];
	
	return self;
}

-(void)dealloc {
	[_stateChange release];
	[_listeners release];
	[super dealloc];
}

-(id)initFadedOutWithTime:(float)time min:(float)min max:(float)max {
	_min = min;
	_max = max;
	_fadeTime = time;
	_state = STATE_FADED_OUT;
	_opacity = min;
	
	_listeners = [[NSMutableSet alloc] initWithCapacity:4];
	
	return self;
}

-(void)fadeIn {
	if (_state == STATE_FADED_OUT || _state == STATE_FADING_OUT) {
		if (_state == STATE_FADED_OUT) {
			_stateChange = [[NSDate date] retain];
		} else {
			float offset = _fadeTime + [_stateChange timeIntervalSinceNow];
			if (offset <= 0.0) {
				offset = 0.0;
			}
			
			[_stateChange release];
			_stateChange = [[NSDate dateWithTimeIntervalSinceNow:-offset] retain];
		}
		_state = STATE_FADING_IN;
	}
}

-(void)fadeOut {
	if (_state == STATE_FADED_IN || _state == STATE_FADING_IN) {
		if (_state == STATE_FADED_IN) {
			_stateChange = [[NSDate date] retain];
		} else {
			float offset = _fadeTime + [_stateChange timeIntervalSinceNow];
			if (offset <= 0.0) {
				offset = 0.0;
			}
			
			[_stateChange release];
			_stateChange = [[NSDate dateWithTimeIntervalSinceNow:-offset] retain];
		}
		_state = STATE_FADING_OUT;		
	}
}

-(void)fadeReverse {
	if (_state == STATE_FADED_IN || _state == STATE_FADING_IN) {
		[self fadeOut];
	} else if (_state == STATE_FADED_OUT || _state == STATE_FADING_OUT) {
		[self fadeIn];
	}
}

-(void)addListener:(id)listener {
	[_listeners addObject:listener];
}

-(void)removeListener:(id)listener {
	[_listeners removeObject:listener];
}

@dynamic opacity;

-(float) opacity {
	if (_state == STATE_FADED_OUT) {
		return _min;
	} else if (_state == STATE_FADED_IN) {
		return _max;
	} else if (_state == STATE_FADING_IN) {
		float current = -[_stateChange timeIntervalSinceNow] / _fadeTime;
		if (current >= 1.0) {
			[_stateChange release];
			_stateChange = nil;
			_state = STATE_FADED_IN;
			
			for (id<FaderListener> listener in _listeners) {
				[listener fadedIn];
			}
			
			return _max;
		} else {
			return _min + current * (_max - _min);
		}
	} else if (_state == STATE_FADING_OUT) {
		float current = -[_stateChange timeIntervalSinceNow] / _fadeTime;
		if (current >= 1.0) {
			[_stateChange release];
			_stateChange = nil;
			_state = STATE_FADED_OUT;
			
			for (id<FaderListener> listener in _listeners) {
				[listener fadedOut];
			}
			
			return _min;
		} else {
			return _max - current * (_max - _min);
		}
	}
	
	return _min;
}

@end
