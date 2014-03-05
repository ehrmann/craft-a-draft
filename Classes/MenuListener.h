//
//  MenuListener.h
//  CraftADraft
//
//  Created by David Ehrmann on 11/16/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Texture2D;

@protocol MenuListener <NSObject>

- (void) iconPressed:(Texture2D *)icon index:(unsigned int)index;
- (void) menuHidden;
- (void) pressCanceled;

@end

