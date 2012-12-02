/*
     File: Hole.m
 Abstract: Hole, a subclass of Mine
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

#import "Hole.h"
#import "Helicopter.h"
#import "Game.h"

@implementation Hole
- (id)initInGame:(Game *)g {
    if (!(self = [self initInGame:g imageName:@"hole" numFrames:6 numPoses:1])) return nil;
    [self setPerFrameTime:100];
    return self;
}

- (void)updatePiece {
    Helicopter *helicopter = [game helicopter];
    NSSize heliAcc = NSZeroSize;

    if (helicopter != nil && [self isWithin:HOLEDISTANCE ofPiece:helicopter]) {
        NSRect hRect = [helicopter rect];
        CGFloat dist;
        NSPoint heliMidPoint;
        NSPoint holeMidPoint;
        heliMidPoint = NSMakePoint(NSMidX(hRect), NSMidY(hRect));
        holeMidPoint = NSMakePoint(NSMidX(pos), NSMidY(pos));
        dist = [Game distanceBetweenPoint:heliMidPoint andPoint:holeMidPoint];
        if (dist < HOLEDISTANCE) {
            CGFloat accMag = HOLEACCVALUE * (HOLEDISTANCE - dist) / HOLEDISTANCE;
            CGFloat xDelta = holeMidPoint.x - heliMidPoint.x;
            CGFloat yDelta = holeMidPoint.y - heliMidPoint.y;
            CGFloat tot = abs(xDelta) + abs(yDelta);
            heliAcc = NSMakeSize(accMag * xDelta / tot, accMag * yDelta / tot);
        }
    }
    if (helicopter != nil) [helicopter setAcceleration:heliAcc];	/* ??? Do this all the time? */
    [super updatePiece];
}

- (void)explode {
}

- (BOOL)touches:(GamePiece *)obj {
    if ([super touches:obj]) {
        return [obj touchesRect:NSMakeRect(NSMidX(pos) - 2.0, NSMidY(pos) - 2.0, 4.0, 4.0)];
    } else {
        return NO;
    }
}

- (BOOL)touchesRect:(NSRect)rect {
    if ([super touchesRect:rect]) {
        return [GamePiece intersectsRects:rect :(NSMakeRect(NSMidX(pos) - 2.0, NSMidY(pos) - 2.0, 4.0, 4.0))];
    } else {
        return NO;
    }
}
@end
