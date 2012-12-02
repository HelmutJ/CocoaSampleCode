/*
     File: GamePiece.m
 Abstract: The mostly abstract superclass of all objects in the game.
  Version: 1.0
 
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

#import "GamePiece.h"
#import "Game.h"

@implementation GamePiece

/* Designated initializer for GamePiece
*/
- (id)initInGame:(Game *)g image:(NSImage *)frames numFrames:(NSInteger)nf numPoses:(NSInteger)np cache:(BOOL)cacheFlag {
    self = [super init];
    
    game = g;
    numImages = nf;
    numPoses = np;
    curImage = 0;
    curPose = 0;
    pos = NSZeroRect;
    vel = NSZeroSize;
    acc = NSZeroSize;

    if (frames != nil) {
	images = frames;
	NSSize imageSize = [images size];
        // Frames are vertically stacked, poses are horizontally stacked...
        [self setSize:NSMakeSize(imageSize.width / numPoses, imageSize.height / numImages)];
	if (cacheFlag) [[self class] cacheImage:images];
    }

    [self setPerFrameTime:DEFAULTPERFRAMETIME];
    aliveUntil = 0;		// This value indicates the object will not die
    
    return self;
}

- (id)initInGame:(Game *)g image:(NSImage *)frames numFrames:(NSInteger)nf numPoses:(NSInteger)np {
    return [self initInGame:g image:frames numFrames:nf numPoses:np cache:YES];
}

- (id)initInGame:(Game *)g imageName:(NSString *)imageName numFrames:(NSInteger)nf numPoses:(NSInteger)np {
    return [self initInGame:g image:[NSImage imageNamed:imageName] numFrames:nf numPoses:np];
}

- (id)initInGame:(Game *)g imageName:(NSString *)imageName numFrames:(NSInteger)nf {
    return [self initInGame:g imageName:imageName numFrames:nf numPoses:1];
}

- (id)initInGame:(Game *)g {
    return [self initInGame:g image:nil numFrames:1 numPoses:1 cache:YES];
}
               
- (void)setSize:(NSSize)newSize {
    pos = NSMakeRect(pos.origin.x, pos.origin.y, newSize.width, newSize.height);
}

- (void)setLocation:(NSPoint)newLocation {
    pos = NSMakeRect(newLocation.x, newLocation.y, pos.size.width, pos.size.height);
}

- (void)setPerFrameTime:(NSInteger)time {
    [self setPerFrameTime:time takeEffectNow:YES];
}

- (void)setPerFrameTime:(NSInteger)time takeEffectNow:(BOOL)nowFlag {
    perFrameTime = time;
    if (nowFlag) nextFrameTime = [game updateTime] + perFrameTime;
}

- (NSPoint)location {
    return pos.origin;
}

- (NSSize)size {
    return pos.size;
}

- (NSRect)rect {
    return pos;
}

- (void)reverseVelocity {
    NSSize newVel = NSMakeSize(-vel.width, -vel.height);
    [self setVelocity:newVel];
}

- (void)setVelocity:(NSSize)newVel {
    vel = newVel;
}

- (NSSize)velocity {
    return vel;
}

- (void)setAcceleration:(NSSize)newAcc {
    acc = newAcc;
}

- (NSSize)acceleration {
    return acc;
}

- (void)setTimeToExpire:(NSInteger)time {
    aliveUntil = [game updateTime] + time;
}

- (void)frameChanged {
}

- (BOOL)touches:(GamePiece *)obj {
    return (obj != nil && obj != self && [obj touchesRect:pos]);
}

+ (BOOL)intersectsRects:(NSRect)a :(NSRect)b {
    if (a.size.width == 0 || a.size.height == 0) return NO;
    if (b.size.width == 0 || b.size.height == 0) return NO;
    if (a.origin.x >= NSMaxX(b)) return NO;
    if (b.origin.x >= NSMaxX(a)) return NO;
    if (a.origin.y >= NSMaxY(b)) return NO;
    if (b.origin.y >= NSMaxY(a)) return NO;
    return YES;
}

- (BOOL)touchesRect:(NSRect)rect {
    return [GamePiece intersectsRects:pos :rect];
}

- (BOOL)isWithin:(CGFloat)dist ofPiece:(GamePiece *)obj {	// Horizontal proximity
    if (obj == nil) return NO;
    NSRect objRect = [obj rect];
    return (pos.origin.x - dist < NSMaxX(objRect)) && (NSMaxX(pos) + dist > objRect.origin.x);
}

- (BOOL)isInFrontAndWithin:(CGFloat)dist ofPiece:(GamePiece *)obj {
    if (obj == nil) return NO;
    NSRect objRect = [obj rect];
    return (pos.origin.x - dist < NSMaxX(objRect)) && (NSMaxX(pos) > objRect.origin.x);
}

- (BOOL)isInBackAndWithin:(CGFloat)dist ofPiece:(GamePiece *)obj {
    if (obj == nil) return NO;
    NSRect objRect = [obj rect];
    return (objRect.origin.x - NSMaxX(pos) < dist) && (NSMaxX(objRect) > pos.origin.x);
}

- (BOOL)isInFrontAndBetween:(CGFloat)farDist and:(CGFloat)nearDist ofPiece:(GamePiece *)obj {
    if (obj == nil) return NO;
    NSRect objRect = [obj rect];
    return (pos.origin.x - farDist < NSMaxX(objRect)) && (NSMaxX(pos) > objRect.origin.x + nearDist);
}

- (void)updatePiece {
    NSInteger updateTime = [game updateTime];
    NSInteger t = [game elapsedTime];

    if (t > 0) {

	if (aliveUntil > 0 && updateTime > aliveUntil) {
	    [game removeGamePiece:self];
	    return;
	}

	// Check to see if its time to jump to the next frame.

	if (images != nil && (updateTime > nextFrameTime)) {
            nextFrameTime = [Game maxInt:nextFrameTime + perFrameTime :updateTime + perFrameTime / 2];
	    curImage = (curImage + 1) % numImages;
	    [self frameChanged];
	}

	// Determine new velocity & location

	NSSize oldVel = vel;
        NSSize curAcc = [self acceleration];	// Due to goofiness in helicopter's implementation...
        CGFloat timeInSeconds = [Game timeInSeconds:t];
        if (curAcc.width != 0.0 || curAcc.height != 0.0) {	// Avoid creating a Size
            [self setVelocity:NSMakeSize(vel.width + curAcc.width * timeInSeconds, vel.height + curAcc.height * timeInSeconds)];
        }
        if (oldVel.width != 0.0 || oldVel.height != 0.0 || vel.width != 0.0 || vel.height != 0.0) {	// Avoid creating a Point
            [self setLocation:NSMakePoint(pos.origin.x + 0.5 * (oldVel.width + vel.width) * timeInSeconds, pos.origin.y + 0.5 * (oldVel.height + vel.height) * timeInSeconds)];
        }
    }
}

- (BOOL)isVisibleIn:(NSRect)rect {
    return [GamePiece intersectsRects:rect :pos];
}

- (void)draw:(NSRect)gameRect {
    if ([self isVisibleIn:gameRect] && images != nil) {
        NSRect fromRect = NSMakeRect(pos.size.width * curPose, pos.size.height * curImage, pos.size.width, pos.size.height);
	NSPoint toPoint = NSMakePoint(floor(pos.origin.x - gameRect.origin.x), floor(pos.origin.y - gameRect.origin.y));
	[images drawAtPoint:toPoint fromRect:fromRect operation:NSCompositeSourceOver fraction:1.0];
    }
}

- (void)explode {
    [self explode:nil];
}

/* Redeclared here to allow overriding...
*/
- (void)playExplosionSound {
    [game playExplosionSound];
}

- (void)explode:(GamePiece *)explosion {
    if (explosion != nil) {
	NSSize explosionSize = [explosion size];
	NSPoint loc = [self location];
	[self playExplosionSound];
	loc.x = pos.origin.x - (explosionSize.width - pos.size.width) / 2;
	loc.y = pos.origin.y - (explosionSize.height - pos.size.height) / 2;
	[explosion setVelocity:vel];
	[explosion setLocation:loc];
	[game addGamePiece:explosion];
    }
    [game removeGamePiece:self];
}

- (NSInteger)pieceType {
    return MobileEnemyPiece;
}

- (void)flyTowardsPiece:(GamePiece *)obj smart:(BOOL)smart {
    NSRect objRect = [obj rect];
    if (smart) {
        NSSize objVel = [obj velocity];
        objRect = NSMakeRect(objRect.origin.x + (objVel.width * 0.6), objRect.origin.y + (objVel.height * 0.4), objRect.size.width, objRect.size.height);
    }
    NSSize velVector = NSMakeSize(NSMidX(objRect) - pos.origin.x, NSMidY(objRect) - pos.origin.y);
    CGFloat mag = sqrt(velVector.width * velVector.width + velVector.height * velVector.height);
    CGFloat speed = sqrt(vel.width * vel.width + vel.height * vel.height);
    velVector.width = velVector.width * speed / mag;
    velVector.height = velVector.height * speed / mag;
    [self setVelocity:velVector];
}

// This method allows pieces to fire (shoot) other pieces
// bullet should already be created but not initted
// fireFrom specifies the offset to fire from; firefrom == FireFromMiddlePoint mean fire from middle

- (void)fireBullet:(GamePiece *)bullet speed:(CGFloat)speed towardsPiece:(GamePiece *)obj smart:(BOOL)smart from:(NSPoint)fireFrom {	
    NSSize newVel = NSMakeSize(speed, 0.0);
    NSPoint bulletLoc;
    bullet = [bullet initInGame:game];

    if (!NSEqualPoints(fireFrom, FireFromMiddlePoint)) {	// If firing location specified, fire from there
	bulletLoc = NSMakePoint(pos.origin.x + fireFrom.x, pos.origin.y + fireFrom.y);
    } else {		// else fire from the middle
	NSSize bulletSize = [bullet size];
	bulletLoc = NSMakePoint(NSMidX(pos) - bulletSize.width / 2.0, NSMidY(pos) - bulletSize.height / 2.0);
    }
    [bullet setLocation:bulletLoc];
    [bullet setVelocity:newVel];
    [game addGamePiece:bullet];
    [game playEnemyFireSound];
    [bullet flyTowardsPiece:obj smart:smart];
}

// Hold images which have been explicitly cached...

+ (void)cacheImage:(NSImage *)image {
    static NSMutableSet *cachedImages = nil;
    if (!cachedImages) cachedImages = [[NSMutableSet alloc] init];
    if (![cachedImages containsObject:image]) {
        [image lockFocus];
        [image unlockFocus];
        [cachedImages addObject:image];
    }
}

+ (void)cacheImageNamed:(NSString *)imageName {
    NSImage *image = [NSImage imageNamed:imageName];
    if (image == nil) {
	NSLog(@"Bad image to cache %@", imageName);
    } else {
	[self cacheImage:image];
    }
}
@end


