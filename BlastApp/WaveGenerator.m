/*
     File: WaveGenerator.m
 Abstract: WaveGenerator, a subclass of Mine
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

#import "WaveGenerator.h"
#import "Wave.h"
#import "Helicopter.h"
#import "Game.h"

@implementation WaveGenerator
- (NSInteger)pieceType {
    return OtherPiece;
}

- (id)initInGame:(Game *)g {
    if (!(self = [self initInGame:g image:nil numFrames:0 numPoses:0])) return nil;
    [self setSize:NSMakeSize(0.0, 6.0)];
    [self setPerFrameTime:10000000];
    return self;
}

- (GamePiece *)wave {
    GamePiece *wave = [[Wave alloc] initInGame:game];
    return wave;
}

- (void)updatePiece {
    NSRect gameBounds;
    Helicopter *helicopter = [game helicopter];

    gameBounds = [game bounds];
    if (helicopter != nil && [game updateTime] > nextFireTime && [self isInFrontAndBetween:gameBounds.size.width and:gameBounds.size.width/2.0 ofPiece:helicopter]) {
        GamePiece *wave = [self wave];
        [wave setLocation:NSMakePoint(pos.origin.x, pos.origin.y)];
        [game addGamePiece:wave];
        nextFireTime = [game updateTime] + (TIMETORECHARGEWAVEGENERATOR * 3) / 4 + [Game randInt:TIMETORECHARGEWAVEGENERATOR / 2];
    }
    [super updatePiece];
}
@end
