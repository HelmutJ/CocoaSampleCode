/*
     File: DropShip.m
 Abstract: DropShip, a subclass of GamePiece
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

#import "DropShip.h"
#import "DropShipExplosion.h"
#import "EnemyBullet.h"
#import "Helicopter.h"
#import "Game.h"

@implementation DropShip
- (id)initInGame:(Game *)g {
    if (!(self = [self initInGame:g imageName:@"dropship" numFrames:1])) return nil;
    [self setPerFrameTime:100000000];
    return self;
}

/* 4x4 rectangle under the nose section is untouchable... */

- (BOOL)touches:(GamePiece *)obj {
    if ([super touches:obj]) {
        return [obj touchesRect:NSMakeRect(pos.origin.x, pos.origin.y + 4.0, pos.size.width, pos.size.height - 4.0)] ||
	       [obj touchesRect:NSMakeRect(pos.origin.x + 4.0, pos.origin.y, pos.size.width - 4.0, 4.0)];
    } else {
        return NO;
    }
}

- (BOOL)touchesRect:(NSRect)rect {
    if ([super touchesRect:rect]) {
        return [GamePiece intersectsRects:rect :NSMakeRect(pos.origin.x, pos.origin.y + 4.0, pos.size.width, pos.size.height - 4.0)] ||
	       [GamePiece intersectsRects:rect :NSMakeRect(pos.origin.x + 4.0, pos.origin.y, pos.size.width - 4.0, 4.0)];
    } else {
        return NO;
    }
}

- (void)explode {
    id exp = [[DropShipExplosion alloc] initInGame:game];
    [game addScore:DROPSHIPSCORE];
    [self explode:exp];
}


- (void)updatePiece {
   if ([game updateTime] > nextFireTime) {
        Helicopter *helicopter = [game helicopter];
	NSSize newVelocity = NSZeroSize;
        if (helicopter != nil && [self isInFrontAndWithin:DROPSHIPDISTANCE ofPiece:helicopter]) {            
            NSRect helicopterRect = [helicopter rect];
            GamePiece *missile = [[EnemyBullet alloc] initInGame:game];
            NSPoint bulletLocation = NSMakePoint(pos.origin.x, pos.origin.y + 7.0);
            NSSize bulletVelocity = NSMakeSize(-BULLETVEL, 0.0);
            if (NSMaxY(helicopterRect) < pos.origin.y) {
                bulletVelocity.height = -BULLETVEL/5.0;
            } else if (helicopterRect.origin.y > NSMaxY(pos)) {
                bulletVelocity.height = BULLETVEL/5.0;
            }
            [missile setVelocity:bulletVelocity];
            [missile setLocation:bulletLocation];
            [game addGamePiece:missile];
            [game playEnemyFireSound];
            newVelocity = NSMakeSize(0.0, (NSMidY(helicopterRect) - NSMidY(pos)) / (CGFloat)[Game timeInSeconds:TIMETOADJUSTDROPSHIP]);
            nextFireTime = [game updateTime] + TIMETOADJUSTDROPSHIP;
        }
        [super updatePiece];
        [self setVelocity:newVelocity];
    } else {
        [super updatePiece];
    }
}
@end
