/*
     File: GameView.m 
 Abstract: Controller class for displaying a simple OpenGL game in a menu.
  
  Version: 1.6 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "GameView.h"


#define PADDLE_Y_COORD (-.45)
#define PADDLE_WIDTH .3
#define PADDLE_DEPTH .15

#define ALIEN_START_HEIGHT .5

#define INTER_ALIEN_X_SPACING .000
#define INTER_ALIEN_Y_SPACING .00

#define ALIEN_WIDTH .045
#define ALIEN_HEIGHT .07

#define MAX_MASS_X_POS .35

#define ALIEN_X_SPEED .7

#define BULLET_SPEED 1.6
#define BULLET_RADIUS .01

static const unsigned char kText[] = 
"***  *   *        *         *       * **** *   * *    *"
" *   **  *       * *        **     ** *    **  * *    *"
" *   * * *      *****       * *   * * ***  * * * *    *"
" *   *  **     *     *      *  * *  * *    *  ** *    *"
"***  *   *    *       *     *   *   * **** *   *  **** ";


@implementation GameView

- (id)initWithFrame:(NSRect)frame pixelFormat:(NSOpenGLPixelFormat *)format {
    self = [super initWithFrame:frame pixelFormat:format];
    if (self) {

    }
    return self;
}

- (void)awakeFromNib {
    [[self window] setAcceptsMouseMovedEvents:YES];
    updateTimer = [[NSTimer timerWithTimeInterval:0 target:self selector:@selector(updateScene:) userInfo:nil repeats:YES] retain];
    [[NSRunLoop currentRunLoop] addTimer:updateTimer forMode:NSEventTrackingRunLoopMode];
    
    [self reset:nil];
}

- (IBAction)reset:sender {
    int x, y;
    double xLocation = - ((ALIEN_WIDTH * ALIEN_X_COUNT / 2.) + INTER_ALIEN_X_SPACING * (ALIEN_X_COUNT - 1) / 2.);
    for (x = 0; x < ALIEN_X_COUNT; x++) {
	double yLocation = ALIEN_START_HEIGHT;    
	for (y = 0; y < ALIEN_Y_COUNT; y++) {
	    char val = kText[y * ALIEN_X_COUNT + x];
	    if (val == ' ') aliens[y][x].state = dead;
	    else aliens[y][x].state = alive;
	    aliens[y][x].origin.x = xLocation;
	    aliens[y][x].origin.y = yLocation;
	    
	    yLocation -= INTER_ALIEN_Y_SPACING + ALIEN_HEIGHT;
	}
	xLocation += INTER_ALIEN_X_SPACING + ALIEN_WIDTH;
    }
}

- (void)drawPaddle {

    glPushMatrix();
    glTranslatef(0., -.07, .15);
    glBegin(GL_QUADS);
    glNormal3f(0., 1., 0.);
    glVertex3f(-PADDLE_WIDTH/2, PADDLE_Y_COORD, PADDLE_DEPTH/2);
    glVertex3f(PADDLE_WIDTH/2, PADDLE_Y_COORD, PADDLE_DEPTH/2);
    glVertex3f(PADDLE_WIDTH/2, PADDLE_Y_COORD, -PADDLE_DEPTH/2);
    glVertex3f(-PADDLE_WIDTH/2, PADDLE_Y_COORD, -PADDLE_DEPTH/2);
    glEnd();
    glPopMatrix();

    glPushMatrix();
    glTranslatef(0., .1, 0.);
    glRotated(75., 1., 0., 0.);
    glTranslatef(0., 0.f, - PADDLE_Y_COORD);
    gluCylinder(quadratic, .025, .05, .15, 64, 64);
    glPopMatrix();
    
    glPushMatrix();
    glRotated(75., 1., 0., 0.);
    glTranslatef(0., 0.f, - PADDLE_Y_COORD);
    gluCylinder(quadratic, .075, .15, .1, 64, 64);
    glPopMatrix(); 
}

- (void)drawRect:(NSRect)rect {
    glClearColor(0., 0., 0., 1.);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glColor3ub(255., 255., 255.);
    
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
    glTranslatef(0., 0., -1.5f);
    
    glBindTexture(GL_TEXTURE_2D, grayTexture);
    
    /* draw paddle */
    glPushMatrix();
    glTranslatef(lastXPosition, 0, 0);
    [self drawPaddle];
    glPopMatrix();
    
    
    /* draw aliens */
    glPushMatrix();
    glTranslatef(alienMassXPosition, alienMassYPosition, 0.);
    glBegin(GL_QUADS);
    glNormal3f(0., 0., 1.);
    int x, y;
    for (x = 0; x < ALIEN_X_COUNT; x++) {
	for (y = 0; y < ALIEN_Y_COUNT; y++) {
	    if (aliens[y][x].state == alive) {
		double xLoc = aliens[y][x].origin.x;
		double yLoc = aliens[y][x].origin.y;
		
		glVertex3f(xLoc, yLoc, 0);
		glVertex3f(xLoc + ALIEN_WIDTH, yLoc, 0);
		glVertex3f(xLoc + ALIEN_WIDTH, yLoc + ALIEN_HEIGHT, 0);
		glVertex3f(xLoc, yLoc + ALIEN_HEIGHT, 0);
	    }
	}
    }
    glEnd();
    glPopMatrix();
    
    glBindTexture(GL_TEXTURE_2D, redTexture);
    /* draw bullets */
    int i;
    for (i=0; i < MAX_BULLETS; i++) {
	if (bullets[i].state == shot) {
	    glPushMatrix();
	    glTranslatef(bullets[i].origin.x, bullets[i].origin.y + BULLET_SPEED * (progress - bullets[i].progress), 0.);
	    gluSphere(quadratic, BULLET_RADIUS, 32, 32);
	    glPopMatrix();
	}
    }
    
    glFlush();
}

- (void)updateScene:time {
    CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
    double diff = now - lastTime;
    if (diff > .1) diff = .1;
    lastTime = now;
    
    progress += diff;
    
    /* reclaim bullets */
    int i;
    for (i=0; i < MAX_BULLETS; i++) {
	double bulletX = bullets[i].origin.x - alienMassXPosition - ALIEN_WIDTH / 2.;
	double bulletY = bullets[i].origin.y + BULLET_SPEED * (progress - bullets[i].progress);
	
	if (bullets[i].state == shot) {
	    if (bulletY > 1.5) {
		bullets[i].state = unshot;
	    }
	    else {
		int x, y;
		for (y = 0; y < ALIEN_Y_COUNT; y++) {
		    for (x = 0; x < ALIEN_X_COUNT; x++) {
			if (aliens[y][x].state == alive) {
			    double xDiff = aliens[y][x].origin.x - bulletX;
			    if (xDiff >= 0 && xDiff < ALIEN_WIDTH) {
				double yDiff = aliens[y][x].origin.y - bulletY;
				if (yDiff >= 0 && yDiff < ALIEN_HEIGHT) {
				    bullets[i].state = unshot;
				    aliens[y][x].state = dead;
				    goto endBullet;
				}
			    }
			}
		    }
		}
		endBullet:
		;
	    }
	}
    }
    
    alienMassXPosition = MAX_MASS_X_POS * sin(progress * ALIEN_X_SPEED);
    [self setNeedsDisplay:YES];
}

- (void)prepareOpenGL {
    glShadeModel(GL_SMOOTH);
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_TEXTURE_2D);
    glDepthFunc(GL_LEQUAL);
    glEnable(GL_CULL_FACE);
    glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
    
    GLfloat LightPosition[] = {0, 0, -1, 1};
    GLfloat LightAmbient[] = {.75, .75, .75, 1.};
    GLfloat LightDiffuse[] = {1., 1., 1., 1.};
    glLightfv(GL_LIGHT1, GL_AMBIENT, LightAmbient);
    glLightfv(GL_LIGHT1, GL_DIFFUSE, LightDiffuse);
    glLightfv(GL_LIGHT1, GL_POSITION, LightPosition);
    glEnable(GL_LIGHT1);
    glEnable(GL_LIGHTING);
    
    quadratic = gluNewQuadric();
    gluQuadricNormals(quadratic, GLU_SMOOTH);
    gluQuadricTexture(quadratic, GL_TRUE);
    gluQuadricOrientation(quadratic, GLU_INSIDE);
    
    if (! grayTexture) {
	glGenTextures(1, &grayTexture);
	glBindTexture(GL_TEXTURE_2D, grayTexture);
	unsigned char texture[] = {0xFF, 0xFF, 0xFF, 0xFF};
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture);
    }
    
    if (! redTexture) {
	glGenTextures(1, &redTexture);
	glBindTexture(GL_TEXTURE_2D, redTexture);
	unsigned char texture[] = {0xFF, 0, 0, 0xFF};
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 1, 1, 0, GL_RGBA, GL_UNSIGNED_BYTE, texture);
    }
}

- (void)reshape {
    NSRect bounds = [self bounds];
    glViewport(0, 0, NSWidth(bounds), NSHeight(bounds));
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    gluPerspective(45., NSWidth(bounds) / NSHeight(bounds), .1, 100.);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint location = [self convertPoint:[event locationInWindow] fromView:nil];
    lastXPosition = ((location.x / NSWidth([self bounds])) - .5) * 3.;
    [self setNeedsDisplay:YES];
}

- (void)mouseDown:(NSEvent *)event {
    /* find an empty bullet */
    int i;
    for (i=0; i < MAX_BULLETS; i++) {
	if (bullets[i].state == unshot) break;
    }
    
    if (i < MAX_BULLETS) {
	bullets[i].state = shot;
	bullets[i].origin.x = lastXPosition;
	bullets[i].origin.y = PADDLE_Y_COORD;
	bullets[i].progress = progress;
    }
    
    [NSCursor setHiddenUntilMouseMoves:YES];
}

- (BOOL)acceptsFirstResponder { return YES; }

@end
