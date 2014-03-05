//
//  Updatable.h
//  CraftADraft
//
//  Created by David Ehrmann on 10/25/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol Updatable <NSObject>

- (void) updateWithTimeElapsed:(float)time;

@end
