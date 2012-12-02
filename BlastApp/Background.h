/*
     File: Background.h
 Abstract: Background. The background image for the game. Reads and maintains landscape info; computes collisions with the background.
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

@class Mine;
@class HorizMine;

#define MAXLEVELS 30	/* Changing this will make highscores incompatible! */

@interface Background:GamePiece {   
    NSInteger maxLevelSpecs;                  /* Maximum number of code points in any level */
    NSInteger numLandscapeSpecs;		/* Number of code points specified in cur level (actually one less) */
    NSInteger landscapeWidthInPixels;         /* Total width of landscape, and hence the background image; numLandscapeSpecs * LANDSCAPEWIDTHPERSPEC */
    NSRect gameRect;			/* Rect describing the current level game area */

    short *bottom;                      /* Describes the ceiling in the current level */
    short *top;                         /* Describes the ground in the current level */
    NSInteger bottomSpec;                     /* Location of current level bottom spec in levelData */
    NSInteger topSpec;                        /* Location of current level top spec in levelData */
    NSInteger gamePieces;                     /* Location of current level pieces spec in levelData */
    NSString *levelDescription;
    NSString *levelFileIdentifier;
    NSData *levelDataAsData;
    NSInteger currentLevel;
    NSInteger numLevels;
    NSColor *groundColor;
}

- (BOOL)initializeLevelData:(NSData *)data;
- (NSInteger)numLevels;
- (void)setLevel:(NSInteger)level;
- (NSString *)levelDescription;
- (NSString *)levelFileIdentifier;  // Non-nil only for custom level files

- (NSRect)clearRectFrom:(CGFloat)startLoc to:(CGFloat)endLoc;

- (NSRect)gameRect;

- (void)createLandscape;
- (void)drawLandscape;
- (void)washToBlack:(NSColor *)color size:(NSSize)size;
- (void)washToWhite:(NSColor *)color size:(NSSize)size;

- (void)putMine:(Mine *)mine :(NSInteger)loc :(CGFloat)yVel;
- (void)putMine:(Mine *)mine :(NSInteger)loc :(CGFloat)yVel :(CGFloat)locFromBottomPercentage;
- (void)putHorizMine:(HorizMine *)mine :(NSInteger)loc :(CGFloat)yVel :(CGFloat)locFromBottomPercentage;

@end

