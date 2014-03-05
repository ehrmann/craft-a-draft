//
//  Epicycloid.h
//  CraftADraft
//
//  Created by David Ehrmann on 10/26/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CraftADraft;

@interface Epicycloid : NSObject {
	CraftADraft *_craftADraft;
	
	int _p;
	int _q;
	float _theta;
	float _r1;
	float _r2;
}

- (Epicycloid *) initWithDrawer:(CraftADraft *)craftADraft;
- (BOOL) iterateWithDuration:(float)duration totalDuration:(float)totalDuration;

@end
