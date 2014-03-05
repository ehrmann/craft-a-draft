//
//  Menu.m
//  CraftADraft
//
//  Created by David Ehrmann on 11/16/09.
//  Copyright 2009 David Ehrmann. All rights reserved.
//

#import "Menu.h"
#import "Texture2D.h"
#import "MenuListener.h"
#import "Fader.h"

#import "UiConstants.h"

static const float FADE_TIME = 0.5;



@implementation Menu

static NSMutableDictionary *textures = nil;

- (id) initWithSize:(CGSize)size x:(float)x y:(float)y {
	_listeners = [[NSMutableArray alloc] initWithCapacity:4];
	_icons = [[NSMutableArray alloc] initWithCapacity:8];
	
	_x = x;
	_y = y;
	_size = size;
	
	_fadeInTime = nil;
	_fadeOutTime = nil;
	
	_irrevocableFadeout = FALSE;
	
	_depressedIcon = nil;
	
	_activeTouches = [[NSMutableSet alloc] initWithCapacity:4];
	_mostRecentTouch = nil;
	
	_opacity = 0.0;
	
	_blackFader = [[Fader alloc] initWithTime:FADE_TIME fadedIn:FALSE min:0.0 max:0.3];
	_fader = [[Fader alloc] initWithTime:FADE_TIME fadedIn:FALSE min:0.0 max:1.0];
	[_fader addListener:self];
	
	if (textures == nil) {
		textures = [[NSMutableDictionary alloc] initWithCapacity:16];
	} else {
		[textures retain];
	}
	
	return self;
}

- (void) dealloc {
	[super dealloc];
	
	[_listeners release];
	
	[_fadeInTime release];
	[_fadeOutTime release];
	[_activeTouches release];
	[_blackFader release];
	[_fader release];
	
	for (Texture2D *icon in _icons) {
		if ([icon retainCount] == 2) {
			[textures removeObjectForKey:icon];
		} else {
			[icon release];
		}
	}
	
	[_icons release];
	
	[textures release];
	if ([textures retainCount] == 0) {
		textures = nil;
	}
}

- (void) addIcon:(Texture2D *)icon {
	[_icons addObject:icon];
}

- (void) addIcon:(Texture2D *)icon atIndex:(unsigned int)index {
	[_icons insertObject:icon atIndex:index];
}

- (void) removeIcon:(Texture2D *)icon {
	[_icons removeObject:icon];
}
- (void) removeIconAtIndex:(unsigned int)index {
	[_icons removeObjectAtIndex:index];
}
- (Texture2D *) getIconAtIndex:(unsigned int)index {
	return (Texture2D *)[_icons objectAtIndex:index];
}

- (void) removeAllIcons {
	[_icons removeAllObjects];
}

- (unsigned int) iconCount {
	return [_icons count];
}

- (void) addListener: (id<MenuListener>)listener {
	[_listeners addObject:listener];
}

- (void) removeListener:(id<MenuListener>)listener {
	[_listeners removeObject:listener];
}

- (void) show {
	if (_irrevocableFadeout == FALSE) {
		[_blackFader fadeIn];
		[_fader fadeIn];
	}
}

- (void) hide {
	[_blackFader fadeOut];
	[_fader fadeOut];
}

- (void) fadedOut {
	_irrevocableFadeout = FALSE;
	_depressedIcon = nil;
	
	for (id<MenuListener> listener in _listeners) {
		[listener menuHidden];
	}
}

- (void) fadedIn {
	
}

- (void) updateWithTimeElapsed:(float)time {
	
}

- (void) draw {
	_opacity = _fader.opacity;
	float _blackOpacity = _blackFader.opacity;
	
	
	if (_blackOpacity > 0.0) {		
		GLfloat vertices2[] = {
			0.0, 0.0,
			_size.width, 0.0,
			0.0, _size.height,
			_size.width, _size.height
		};
		
		GLfloat black[] = {
			0.0, 0.0, 0.0, _blackOpacity,
			0.0, 0.0, 0.0, _blackOpacity,
			0.0, 0.0, 0.0, _blackOpacity,
			0.0, 0.0, 0.0, _blackOpacity
		};
		
		glColor4f(1.0, 1.0, 1.0, 1.0);
		
		glEnableClientState(GL_VERTEX_ARRAY);
		glEnableClientState(GL_COLOR_ARRAY);
		glEnable(GL_BLEND);
		
		//glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
		glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);

		
		glVertexPointer(2, GL_FLOAT, 0, vertices2);
		
		glColorPointer(4, GL_FLOAT, 0, black);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glDisable(GL_BLEND);
		glDisableClientState(GL_VERTEX_ARRAY);
		glDisableClientState(GL_COLOR_ARRAY);
	}
	
	
	glEnable(GL_BLEND);
	glBlendFunc (GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
	
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glEnableClientState(GL_VERTEX_ARRAY);
	
	glEnable(GL_TEXTURE_2D);
	
	
	float offset = -((float)[_icons count] - 1.0) / 2.0;
	float distance = MENU_BUTTON_LR_MARGIN + MENU_BUTTON_WIDTH;
	
	for (unsigned int i = 0; i < [_icons count]; i++) {
		
		Texture2D *icon = [_icons objectAtIndex:i];
		
		int width = icon.contentSize.width;
		int height = icon.contentSize.height;
		
		GLfloat coordinates[] = {
			0.0, 0.0,
			(float)width / icon.pixelsWide, 0.0,
			0.0, (float)height / icon.pixelsHigh,
			(float)width / icon.pixelsWide, (float)height / icon.pixelsHigh
		};
		
		GLfloat vertices[] = {
			-MENU_BUTTON_WIDTH / 2, -MENU_BUTTON_HEIGHT / 2,
			MENU_BUTTON_WIDTH / 2, -MENU_BUTTON_HEIGHT / 2,
			-MENU_BUTTON_WIDTH / 2, MENU_BUTTON_HEIGHT / 2,
			MENU_BUTTON_WIDTH / 2, MENU_BUTTON_HEIGHT / 2
		};
		
		glPushMatrix();
		
		glTranslatef(_x, _y, 0.0);
		glTranslatef((float)offset * distance, 0.0, 0.0);
		
		glBindTexture(GL_TEXTURE_2D, icon.name);
		if (icon != _depressedIcon) {
			glColor4f(_opacity, _opacity, _opacity, _opacity);
		} else {
			glColor4f(0.6 * _opacity, 0.6 * _opacity, 0.6 * _opacity, _opacity);
		}
		
		glVertexPointer(2, GL_FLOAT, 0, vertices);
		glTexCoordPointer(2, GL_FLOAT, 0, coordinates);
		
		glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		
		glPopMatrix();
		
		offset++;
	}
	
	glColor4f(1.0, 1.0, 1.0, 1.0);
	
	glDisable(GL_BLEND);	
	glDisable(GL_TEXTURE_2D);
	
	glDisableClientState(GL_TEXTURE_COORD_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);	
	
}

- (Texture2D *) onWhichIconWithX:(unsigned int)x y:(unsigned int)y {
	
	float offset = -((float)[_icons count] - 1.0) / 2.0;
	float distance = MENU_BUTTON_LR_MARGIN + MENU_BUTTON_WIDTH;
	
	float minY = _y - MENU_BUTTON_HEIGHT / 2;
	float maxY = _y + MENU_BUTTON_HEIGHT / 2;
	
	for (unsigned int i = 0; i < [_icons count]; i++) {
		float centerX = (float)offset * distance + _x;
		float minX = centerX - MENU_BUTTON_WIDTH / 2;
		float maxX = centerX + MENU_BUTTON_WIDTH / 2;
		
		if ((float)x >= minX && (float)x <= maxX && (float)y >= minY && (float)y <= maxY) {
			return [_icons objectAtIndex:i];
		}
		
		offset++;
	}

	return nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if (_irrevocableFadeout == FALSE) {
		for (UITouch *touch in touches) {
			if (![_activeTouches containsObject:touch]) {
				CGPoint location = [touch locationInView:nil];
				_depressedIcon = [self onWhichIconWithX:location.x y:location.y];
				if (_depressedIcon != nil) {
					_mostRecentTouch = touch;
					[_activeTouches addObject:touch];
				} else {
					[self hide];
					_mostRecentTouch = nil;
				}
			}
		}
	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_mostRecentTouch]) {
		CGPoint location = [_mostRecentTouch locationInView:nil];
		Texture2D *newIcon = [self onWhichIconWithX:location.x y:location.y];
		if (_depressedIcon != newIcon) {
			[self hide];
			_irrevocableFadeout = TRUE;
			[_activeTouches removeObject:_mostRecentTouch];
			_mostRecentTouch = nil;
		}
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([touches containsObject:_mostRecentTouch]) {
		CGPoint location = [_mostRecentTouch locationInView:nil];
		Texture2D *newIcon = [self onWhichIconWithX:location.x y:location.y];
		if (_depressedIcon == nil) {
			[self hide];
		} else if (_depressedIcon != newIcon) {
			[self hide];
			_irrevocableFadeout = TRUE;
		} else {
			for (id<MenuListener> listener in _listeners) {
				[listener iconPressed:_depressedIcon index:[_icons indexOfObject:_depressedIcon]];
			}
			[self hide];
			_irrevocableFadeout = TRUE;
		}
		
		_mostRecentTouch = nil;
	}
	[_activeTouches minusSet:touches];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchesEnded:touches withEvent:event];
}

@end
