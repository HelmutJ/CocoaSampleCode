/*
     File: Game.h
 Abstract: Subclass of NSView implementing main game loop. An MVC design would have split the view from the game.
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

#import <Cocoa/Cocoa.h>
#import "GamePiece.h"

@class Background;
@class Helicopter;
@class GamePiece;
@class RemainingHelicopters;
@class InputIndicator;

enum {
    /* User commands */
    NoCommand = 0,
    GoUpCommand = 1,
    GoUpRightCommand = 2,
    GoRightCommand = 3,
    GoDownRightCommand = 4,
    GoDownCommand = 5,
    GoDownLeftCommand = 6,
    GoLeftCommand = 7,
    GoUpLeftCommand = 8,
    StopCommand = 9,
    FireCommand = 10,
    NumCommands = 11
};

enum {
    /* Maximum velocity (in pixel/seconds) for any object in the game */
    MAXVELX = 65,
    MAXVELY = 65,
    MINVELX = 1,
    MINVELY = 1
};

enum {
    HELICOPTERSTARTX = 2,
    HELICOPTERSTARTY = 80
};

enum {
    /* Maximum time a frame can take. This is the maximum value returned by the elapsedTime method. */
    MAXUPDATETIME = 100
};

enum {
    TIMING = 0
};

#define ANIMATIONINTERVAL (0.04)
#define RANDINT(n) [Game randInt:(n)]

enum {
    MAXBONUSTIME = 120000,	/* ms */
    /* Bonus for finishing a level in under MAXBONUSTIME */
    BONUS = 10
};


@interface Game:NSView {
    /* Timing related */
    BOOL timing;
    NSInteger timingTime;
    NSInteger timingFrames;
    NSInteger timingMissed;

    /* "Cheat" (or "test") mode. If not zero, this stores the number of times hit while in cheat mode. */
    NSInteger cheating;	

    /* Vectors of GamePieces, grouped by piece type */
    NSMutableArray *pieces[LastGamePiece]; 

    /* References to some special pieces... */
    Background *background;
    Helicopter *helicopter;
    GamePiece *focusObject;

    /* Outlets to UI elements */
    IBOutlet __weak NSTextField *statusField;
    IBOutlet __weak NSTextField *scoreField;
    IBOutlet __weak RemainingHelicopters *livesField;
    IBOutlet __weak NSTextField *levelField;
    IBOutlet __weak NSTextField *highscoreField;
    IBOutlet __weak InputIndicator *inputIndicator;
    IBOutlet __weak NSButton *pauseButton;

    /* The next four are UI gadgets in the Prefs panel */
    IBOutlet __weak NSMatrix *levelMatrix;
    IBOutlet __weak NSSlider *levelSlider;
    IBOutlet __weak NSTextField *levelPrefsIndicator;
    IBOutlet __weak NSButton *soundPrefItem;

    /* Game variables */
    NSTimer *timer;
    NSPoint lastOrigin;
    BOOL gameOver;	
    BOOL bonusGiven;	
    BOOL newHighScore;	// Indicates a new high score was reached
    BOOL started;	// If true, indicates the helicopter started moving in this level
    NSInteger score, lives, level, highScore, highLevel, numFrames;

    /*
        updateTime is the game clock; only stops when paused.
        updateTime is updated only between frames.
        elapsedTime is the time since last frame.
        timeStopped is the time game was stopped (including overrun frames)
        pausedAt is the time at which the game was paused.
        levelStartedAt is the time at which the helicopter started moving
        at this level. Used in determining bonus points. If -1, then the
        helicopter is still at the start of the level.
    */
    NSInteger updateTime, elapsedTime, timeStopped, pausedAt, levelStartedAt;	/* ms */
    NSDate *gameStartTime;
    NSInteger lastCommand;

    BOOL isDemo;
}

/* ??? These need to be made into functions */
+ (NSInteger)randInt:(NSInteger)n;
+ (BOOL)oneIn:(NSInteger)n;
+ (double)timeInSeconds:(NSInteger)ms;
+ (NSInteger)secondsToMilliseconds:(double)seconds;
+ (CGFloat)restrictValue:(CGFloat)val toPlusOrMinus:(CGFloat)max;
+ (CGFloat)distanceBetweenPoint:(NSPoint)p1 andPoint:(NSPoint)p2;
+ (NSInteger)minInt:(NSInteger)a :(NSInteger)b;
+ (NSInteger)maxInt:(NSInteger)a :(NSInteger)b;
+ (CGFloat)minFloat:(CGFloat)a :(CGFloat)b;
+ (CGFloat)maxFloat:(CGFloat)a :(CGFloat)b;

+ (BOOL)setUpSounds;

- (NSInteger)timeInMsSinceGameBegan;
- (NSInteger)updateTime;
- (NSInteger)elapsedTime;

- (Helicopter *)helicopter;
- (Background *)background;
- (NSArray *)piecesOfType:(NSInteger)type;

- (void)removeGamePiece:(GamePiece *)piece;
- (void)addGamePiece:(GamePiece *)piece;
- (void)setFocusObject:(GamePiece *)piece;
- (NSRect)currentBackgroundPosition;

- (void)addScore:(NSInteger)points;

- (void)playEnemyFireSound;
- (void)playFriendlyFireSound;
- (void)playExplosionSound;
- (void)playLoudExplosionSound;

- (void)markGameAsRunning;

- (IBAction)startGame:(id)sender;
- (void)startGame:(id)sender atLevel:(NSInteger)startingLevel;

- (IBAction)stop:(id)sender;
- (IBAction)go:(id)sender;
- (IBAction)togglePause:(id)sender;
- (BOOL)isPaused;

- (void)stopLastCommand;

- (void)stopGameFor:(NSInteger)timeAdj;

- (void)startLevel:(NSInteger)newLevel;
- (void)restartLevel;

- (void)setDemo:(BOOL)flag;
- (BOOL)isDemo;

- (IBAction)showPrefs:(id)sender;

- (void)readHighScore;
- (void)updateHighScore;
- (void)updateSoundPref;

- (void)setSoundRequested:(BOOL)flag;

- (void)displayRunningMessage;

@end

