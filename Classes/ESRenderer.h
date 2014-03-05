//
//  ESRenderer.h
//  CraftADraftPad
//
//  Created by David Ehrmann on 4/29/10.
//  Copyright David Ehrmann 2010. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>

@protocol ESRenderer <NSObject>

- (void)render;
- (BOOL)resizeFromLayer:(CAEAGLLayer *)layer;

@end
