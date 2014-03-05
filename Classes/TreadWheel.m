//
//  TreadWheel.m
//  CraftADraft
//
//  Created by David Ehrmann on 3/7/10.
//  Copyright 2010 David Ehrmann. All rights reserved.
//

#import "TreadWheel.h"

static const float MAX_OPACITY = 0.5;
static const float MIN_OPACITY = 0.25;

@implementation TreadWheel

- (id) init {
	_theta = 0.0;
	_teeth = 16;
	
	_width = 320.0;
	_height = 480.0;
	
	_wheelWidth = 50;
	_wheelHeight = 200;
	
	return self;
}

- (void) updateWithTimeElapsed:(float)time {
	while(_theta >= 2 * M_PI) {
		_theta -= 2 * M_PI;
	}
	
	while(_theta < 0) {
		_theta += 2 * M_PI;
	}
}

- (void)draw {
	
	_theta += .002;
	
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_COLOR_ARRAY);
	glEnable(GL_BLEND);
	
	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);	
	
	glPushMatrix();
	
	glTranslatef(_width / 2.0, _height / 2.0, 0.0);
	
	float theta = _theta;
	float inc = 2 * M_PI / _teeth;
	
	while (theta > -inc - M_PI / 2.0) {
		theta -= inc;
	}
	
	float littleR = (_wheelHeight / 2.0) * sin(inc / 4.0);
	
	float lowLineAlpha = 0.0;
	
	for (int i = 0; i < _teeth; i++) {
		
		float lowTheta = theta;
		float midTheta = theta + inc / 2.0;
		float highTheta = theta + inc;
		
		
		float midLineAlpha = 0.0;
		float highLineAlpha = 0.0;
		
		if ((lowTheta >= -M_PI / 2.0 && lowTheta <= M_PI / 2.0) || (midTheta >= -M_PI / 2.0 && midTheta <= M_PI / 2.0)) {
			
			if (lowTheta < -M_PI / 2.0 && midTheta <= M_PI / 2.0) {
				lowTheta = -M_PI / 2.0;
			} else if (lowTheta >= -M_PI / 2.0 && midTheta > M_PI / 2.0) {
				midTheta = M_PI / 2.0;
			}
			
			float lowY = ceil(sin(lowTheta) * _wheelHeight / 2.0);
			float highY = floor(sin(midTheta) * _wheelHeight / 2.0);
			
			GLfloat vertices[] = {
				-_wheelWidth / 2.0, lowY,
				_wheelWidth / 2.0, lowY,
				-_wheelWidth / 2.0, highY,
				_wheelWidth / 2.0, highY,
			};
			
			GLfloat colors[] = {
				1.0, 1.0, 1.0, cos(lowTheta) * (MAX_OPACITY - MIN_OPACITY) + MIN_OPACITY,
				1.0, 1.0, 1.0, cos(lowTheta) * (MAX_OPACITY - MIN_OPACITY) + MIN_OPACITY,
				1.0, 1.0, 1.0, cos(midTheta) * (MAX_OPACITY - MIN_OPACITY) + MIN_OPACITY,
				1.0, 1.0, 1.0, cos(midTheta) * (MAX_OPACITY - MIN_OPACITY) + MIN_OPACITY,
			};
			
			lowLineAlpha += (cos(lowTheta) * (MAX_OPACITY - MIN_OPACITY) + MIN_OPACITY) * (lowY - sin(lowTheta) * _wheelHeight / 2.0);
			midLineAlpha += (cos(midTheta) * (MAX_OPACITY - MIN_OPACITY) + MIN_OPACITY) * (sin(midTheta) * _wheelHeight / 2.0 - highY);
			
			glColorPointer(4, GL_FLOAT, 0, colors);
			glVertexPointer(2, GL_FLOAT, 0, vertices);
			glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
		}
		
		if ((midTheta >= -M_PI / 2.0 && midTheta <= M_PI / 2.0) || (highTheta >= -M_PI / 2.0 && highTheta <= M_PI / 2.0)) {
			float centerTheta = theta + inc * (3.0 / 4.0);
			
			float top = sin(midTheta) * _wheelHeight / 2.0;
			float bottom = sin(highTheta) * _wheelHeight / 2.0;
			float center = sin(centerTheta) * _wheelHeight / 2.0 - sin(centerTheta) * littleR;
			
			if (centerTheta < 0.0) {
				int arrayCount = 6;
				float cutoff = sin(highTheta) * _wheelHeight / 2.0;
				
				float centerOpacity = 0.5;
				float topOpacity = 0.2;
				float cutoffOpacity = cos(theta * 2) * topOpacity + sin(theta * 2) * centerOpacity;
				
				if (center > cutoff) {
					center = cutoff;
					highLineAlpha += (cutoff - floor(cutoff)) * centerOpacity;
				//	centerOpacity = cutoffOpacity;
				} else {
					highLineAlpha += (cutoff - floor(cutoff)) * topOpacity;
				}
				
				if (midTheta < -M_PI / 2.0) {
					top = -_wheelHeight / 2.0;
				}
				
				if (center < ceil(top)) {
					center = ceil(top);
					
				} else if (center > floor(cutoff)) {
					center = floor(cutoff);
					arrayCount = 4;
				} else {
					
				}
				
				GLfloat vertices[] = {
					-_wheelWidth / 2.0, ceil(top),
					_wheelWidth / 2.0, ceil(top),
					-_wheelWidth / 2.0, center,
					_wheelWidth / 2.0, center,
					-_wheelWidth / 2.0, floor(cutoff),
					_wheelWidth / 2.0, floor(cutoff),
				};
				
				midLineAlpha += (ceil(top) - top) * topOpacity;
			

				
				GLfloat colors[] = {
					1.0, 1.0, 1.0, topOpacity,
					1.0, 1.0, 1.0, topOpacity,
					1.0, 1.0, 1.0, centerOpacity,
					1.0, 1.0, 1.0, centerOpacity,
					1.0, 1.0, 1.0, topOpacity,
					1.0, 1.0, 1.0, topOpacity,
				};
				
				glColorPointer(4, GL_FLOAT, 0, colors);
				glVertexPointer(2, GL_FLOAT, 0, vertices);
				glDrawArrays(GL_TRIANGLE_STRIP, 0, arrayCount);
				
			} else {
				float cutoff = sin(midTheta) * _wheelHeight / 2.0;
				
				float centerOpacity = 0.5;
				float bottomOpacity = 0.2;
				float cutoffOpacity = cos(theta * 2) * bottomOpacity + sin(theta * 2) * centerOpacity;
				
				if (center < cutoff) {
					center = cutoff;
					
					midLineAlpha += centerOpacity * (ceil(cutoff) - cutoff);
					highLineAlpha += centerOpacity * (bottom - floor(bottom));
				} else {
					midLineAlpha += bottomOpacity * (ceil(cutoff) - cutoff);
					highLineAlpha += bottomOpacity * (bottom - floor(bottom));
				}
				
				if (highTheta > M_PI / 2.0) {
					bottom = _wheelHeight / 2.0;
				}
				
				if (center < ceil(cutoff)) {
					center = ceil(cutoff);
				} else if (center > floor(bottom)) {
					center = floor(bottom);
				}
				
				GLfloat vertices[] = {
					-_wheelWidth / 2.0, ceil(cutoff),
					_wheelWidth / 2.0, ceil(cutoff),
					-_wheelWidth / 2.0, center,
					_wheelWidth / 2.0, center,
					-_wheelWidth / 2.0, floor(bottom),
					_wheelWidth / 2.0, floor(bottom),
				};
				
				GLfloat colors[] = {
					1.0, 1.0, 1.0, bottomOpacity,
					1.0, 1.0, 1.0, bottomOpacity,
					1.0, 1.0, 1.0, centerOpacity,
					1.0, 1.0, 1.0, centerOpacity,
					1.0, 1.0, 1.0, bottomOpacity,
					1.0, 1.0, 1.0, bottomOpacity,
				};
				
				glColorPointer(4, GL_FLOAT, 0, colors);
				glVertexPointer(2, GL_FLOAT, 0, vertices);
				glDrawArrays(GL_TRIANGLE_STRIP, 0, 6);
			}
		}
		
		float lowY = ceil(sin(lowTheta) * _wheelHeight / 2.0);
		float highY = floor(sin(midTheta) * _wheelHeight / 2.0);
		
		/*
		GLfloat lineVertices[] = {
			-_wheelWidth / 2.0, lowY - 0.5,
			_wheelWidth / 2.0, lowY - 0.5,
			-_wheelWidth / 2.0, highY + 0.5,
			_wheelWidth / 2.0, highY + 0.5,
		};
		 */
		GLfloat lineVertices[] = {
			-_wheelWidth / 2.0, lowY - 0.5,
			0.0 / 2.0, lowY - 0.5,
			-_wheelWidth / 2.0, highY + 0.5,
			0.0 / 2.0, highY + 0.5,
		};
		
		GLfloat lineColors[] = {
			1.0, 1.0, 1.0, lowLineAlpha,
			1.0, 1.0, 1.0, lowLineAlpha,
			1.0, 1.0, 1.0, midLineAlpha,
			1.0, 1.0, 1.0, midLineAlpha,
		};
		
		glColorPointer(4, GL_FLOAT, 0, lineColors);
		glVertexPointer(2, GL_FLOAT, 0, lineVertices);
		glDrawArrays(GL_LINES, 0, 4);
		
		lowLineAlpha = highLineAlpha;
		theta += inc;
	}
	
	glPopMatrix();
	
	glDisableClientState(GL_COLOR_ARRAY);
	glDisableClientState(GL_VERTEX_ARRAY);
	glDisable(GL_BLEND);
}

@end
