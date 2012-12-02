/*
     File: AutoPilotHelicopter.m
 Abstract: AutoPilotHelicopter, a subclass of Helicopter. One of the interesting subclasses of GamePiece, implementing the demo helicopter.
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

#import "AutoPilotHelicopter.h"
#import "Background.h"
#import "Helicopter.h"
#import "Game.h"

enum {
     AUTOPILOTSTARTTIME = 2000,		/* ms */
     AUTOPILOTTAKEOVERTIME = 4000,	/* ms */
     AUTOPILOTHELICOPTERSPEED = (MAXVELX * 3) / 4
};



@implementation AutoPilotHelicopter
- (id)initInGame:(Game *)g {
    if (!(self = [super initInGame:g])) return nil;
    autopilotTakeoverTime = [game updateTime] + AUTOPILOTSTARTTIME;
    return self;
}

- (void)setCommand:(NSInteger)cmd {
    autopilot = NO;
    autopilotTakeoverTime = [game updateTime] + AUTOPILOTTAKEOVERTIME;
    [super setCommand:cmd];
}

- (void)startFiring {
    autopilot = NO;
    autopilotTakeoverTime = [game updateTime] + AUTOPILOTTAKEOVERTIME * 10;
    [super startFiring];
}

- (void)stopFiring {
    autopilot = NO;
    autopilotTakeoverTime = [game updateTime] + AUTOPILOTTAKEOVERTIME;
    [super stopFiring];
}

- (BOOL)fireRequested {
    if (autopilot) {
	return [Game oneIn:50];
    } else {
	return [super fireRequested];
    }
}

- (void)updatePiece {
    if (!autopilot && [game updateTime] >= autopilotTakeoverTime) {
	autopilot = YES;
        [game markGameAsRunning];
        [self setVelocity:NSMakeSize(AUTOPILOTHELICOPTERSPEED, 0.0)];
	[self setAcceleration:NSMakeSize(0.0, 0.0)];
    }
    [super updatePiece];
    // Prevent a crash...
    NSRect rect = [[game background] clearRectFrom:pos.origin.x to:NSMaxX(pos) + 4.0];
    if (NSMaxY(pos) >= NSMaxY(rect)) {	// Oops, need to adjust
        [self setLocation:NSMakePoint(pos.origin.x, NSMaxY(rect) - pos.size.height - 1.0)];
    } else if (pos.origin.y <= rect.origin.y) {	// Oops, need to adjust
        [self setLocation:NSMakePoint(pos.origin.x, rect.origin.y + 1.0)];
    } else {
        rect = [[game background] clearRectFrom:pos.origin.x to:NSMaxX(pos) + 20.0f];
        if (NSMaxY(pos) >= NSMaxY(rect) - 2.0) {	// Oops, need to adjust
            [self setLocation:NSMakePoint(pos.origin.x, pos.origin.y - 1.0)];
        } else if (pos.origin.y < rect.origin.y + 2.0) {	// Oops, need to adjust
            [self setLocation:NSMakePoint(pos.origin.x, pos.origin.y + 1.0)];
        } else if (!autopilot && [Game oneIn:100]) {
            [self setLocation:NSMakePoint(pos.origin.x, pos.origin.y + [Game randInt:2] - 1.0)];	// random drift
        }
    }
}
@end
