/*
     File: Helicopter.m
 Abstract: One of the interesting subclasses of GamePiece, implementing the helicopter
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


#import "Helicopter.h"
#import "Bullet.h"
#import "HelicopterExplosion.h"
#import "Game.h"


@implementation Helicopter
- (NSInteger)pieceType {
    return FriendlyPiece;
}

- (id)initInGame:(Game *)g {
    if (!(self = [self initInGame:g imageName:@"helicopter" numFrames:4])) return nil;
    return self;
}

- (void)startFiring {
    fireRequested = YES;
}

- (void)stopFiring {
    if (fireRequested) {
	nextFireTime = [Game minInt:nextFireTime :[game updateTime] + TIMETORECHARGE / 4];
	fireRequested = NO;
    }
}

- (BOOL)fireRequested {
    return fireRequested;
}

- (void)setVelocity:(NSSize)newVelocity {
    NSSize newVel = NSMakeSize([Game maxFloat:0.0 :[Game minFloat:MAXVELX :newVelocity.width]], [Game restrictValue:newVelocity.height toPlusOrMinus:MAXVELY]);
    if ((newVel.height > 0.0 && vel.height > 0.0 && newVel.height < vel.height && newVel.height < ZEROVELTHRESHOLD) ||
	(newVel.height < 0.0 && vel.height < 0.0 && newVel.height > vel.height && newVel.height > -ZEROVELTHRESHOLD)) {
	newVel.height = 0.0;
    }
    if (newVel.width < vel.width && newVel.width < ZEROVELTHRESHOLD) {
    	newVel.width = 0.0;
    }
    [super setVelocity:newVel];
}

- (void)setCommand:(NSInteger)cmd {
    command = cmd;
}

- (NSSize)acceleration {
    CGFloat dw = 0.0, dh = 0.0;
    switch (command) {
        case StopCommand:		dw = -7 * vel.width; dh = -7 * vel.height; break;
        case GoDownLeftCommand:	dw = dh = -HELICOPTERACCVALUE; break;
        case GoDownCommand:	dh = -HELICOPTERACCVALUE; break;
        case GoDownRightCommand:	dw = HELICOPTERACCVALUE; dh = -HELICOPTERACCVALUE; break;
        case GoLeftCommand:	dw = -HELICOPTERACCVALUE; break;
        case GoRightCommand:	dw = HELICOPTERACCVALUE; break;
        case GoUpLeftCommand:	dw = -HELICOPTERACCVALUE; dh = HELICOPTERACCVALUE; break;
        case GoUpCommand:		dh = HELICOPTERACCVALUE; break;
        case GoUpRightCommand:	dw = HELICOPTERACCVALUE; dh = HELICOPTERACCVALUE; break;
        default:			break;
    }
    return NSMakeSize(acc.width + dw, acc.height + dh);
}

- (void)updatePiece {
    if ([self fireRequested] && [game updateTime] > nextFireTime) {
        GamePiece *bullet = [[Bullet alloc] initInGame:game];
        [game playFriendlyFireSound];
        [bullet setVelocity:NSMakeSize(vel.width + BULLETVEL, vel.height)];
        [bullet setLocation:NSMakePoint(NSMaxX(pos) - 8, pos.origin.y)];
	[game addGamePiece:bullet];
	nextFireTime = [game updateTime] + TIMETORECHARGE;
    }
    [super updatePiece];
}

- (void)playExplosionSound {
    [game playLoudExplosionSound];
}

- (void)explode {
    GamePiece *explosion = [[HelicopterExplosion alloc] initInGame:game];
    [game setFocusObject:explosion];
    [self explode:explosion];
}

// Touch rects for the helicopter pointing right.

#define NUMHELICOPTERRECTS 5

static NSRect helicopterRects[NUMHELICOPTERRECTS] = {
    {{27, 0}, {18, 11}},	// Bottom
    {{0, 8}, {4, 11}},		// Tail
    {{0, 16}, {50, 1}},
    {{22, 5}, {18, 12}},	// Body
    {{0, 10}, {42, 3}}
};

- (BOOL)touches:(GamePiece *)obj {
    if (![super touches:obj]) return NO;	// Easy case 
    NSInteger cnt;
    for (cnt = 0; cnt < NUMHELICOPTERRECTS; cnt++) {
        NSRect rect = helicopterRects[cnt];
        if ([obj touchesRect:NSMakeRect(rect.origin.x + pos.origin.x, rect.origin.y + pos.origin.y, rect.size.width, rect.size.height)]) return YES;
    }
    return NO;
}

- (BOOL)touchesRect:(NSRect)r {
    if (![super touchesRect:r]) return NO;	// Easy case
    NSInteger cnt;
    for (cnt = 0; cnt < NUMHELICOPTERRECTS; cnt++) {
        NSRect rect = helicopterRects[cnt];
        if ([GamePiece intersectsRects:r :NSMakeRect(rect.origin.x + pos.origin.x, rect.origin.y + pos.origin.y, rect.size.width, rect.size.height)]) return YES;
    }
    return NO;
}
@end
