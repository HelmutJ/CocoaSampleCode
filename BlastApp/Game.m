/*
     File: Game.m
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

/*
All time values in milliseconds
All distances in points (and 3 points = 1 meter, but that doesn't really matter)
*/



#import "Game.h"
#import "GamePiece.h"
#import "Helicopter.h"
#import "AutoPilotHelicopter.h"
#import "RemainingHelicopters.h"
#import "Background.h"
#import "InputIndicator.h"
#import "AwardView.h"

@implementation Game
+ (NSInteger)randInt:(NSInteger)n {	// Random integer 0..n (inclusive)
    return (rand() % (n+1));		// Random integer 0..n
}

+ (BOOL)oneIn:(NSInteger)n {	// Returns true one in n times
    return (rand() % (n)) == 0;
}

+ (double)timeInSeconds:(NSInteger)ms {
    return ms / 1000.0f;
}

+ (NSInteger)secondsToMilliseconds:(double)seconds {
    return (NSInteger)(seconds * 1000.0f);
}

+ (CGFloat)restrictValue:(CGFloat)val toPlusOrMinus:(CGFloat)max {
    if (val > max) return max;
    else if (val < -max) return -max;
    else return val;
}

+ (CGFloat)distanceBetweenPoint:(NSPoint)p1 andPoint:(NSPoint)p2 {
    return sqrt((p1.x - p2.x) * (p1.x - p2.x) + (p1.y - p2.y) * (p1.y - p2.y));
}

+ (NSInteger)minInt:(NSInteger)a :(NSInteger)b {
    if (a < b) return a;
    return b;
}

+ (NSInteger)maxInt:(NSInteger)a :(NSInteger)b {
    if (a > b) return a;
    return b;
}

+ (CGFloat)minFloat:(CGFloat)a :(CGFloat)b {
    if (a < b) return a;
    return b;
}

+ (CGFloat)maxFloat:(CGFloat)a :(CGFloat)b {
    if (a > b) return a;
    return b;
}

// Sound stuff

static BOOL soundRequested = NO;
static NSSound *fireSound = nil;
static NSSound *explosionSound = nil;
static NSSound *loudExplosionSound = nil;

+ (BOOL)setUpSounds {
    if (fireSound != nil) return YES;	// Already done...
    fireSound = [NSSound soundNamed:@"EnemyFire"];
    explosionSound = [NSSound soundNamed:@"LowExplosion"];
    loudExplosionSound = [NSSound soundNamed:@"LoudExplosion"];
    return fireSound != nil && explosionSound != nil && loudExplosionSound != nil;
}

- (void)playEnemyFireSound {
    if (soundRequested) [fireSound play];
}

- (void)playFriendlyFireSound {
    if (soundRequested) [fireSound play];	// For now, the same sound...
}

- (void)playExplosionSound {
    if (soundRequested) [explosionSound play];
}

- (void)playLoudExplosionSound {
    if (soundRequested) [loudExplosionSound play];
}

// We initialize some pieces ahead of time to prevent jerkiness during the game.
// This should really be done more dynamically...


+ (void)doNonLazyInitialization {
    static BOOL nonLazyInitDone = NO;

    if (nonLazyInitDone) return;

    nonLazyInitDone = YES;

    [GamePiece cacheImageNamed:@"bullet"];
    [GamePiece cacheImageNamed:@"missile"];
    [GamePiece cacheImageNamed:@"smartmissile"];
    [GamePiece cacheImageNamed:@"arrowbaseexplosion"];
    [GamePiece cacheImageNamed:@"backshooterexplosion"];
    [GamePiece cacheImageNamed:@"bigexplosion"];
    [GamePiece cacheImageNamed:@"dropshipexplosion"];
    [GamePiece cacheImageNamed:@"hexplosion"];
    [GamePiece cacheImageNamed:@"hbexplosion"];
    [GamePiece cacheImageNamed:@"mbexplosion"];
    [GamePiece cacheImageNamed:@"smallexplosion"];
    [GamePiece cacheImageNamed:@"smallmineexplosion"];
    [GamePiece cacheImageNamed:@"smartmbexplosion"];
    [GamePiece cacheImageNamed:@"smartmineexplosion"];
    
    srand((unsigned)(fabs(fmod([NSDate timeIntervalSinceReferenceDate], (double)INT_MAX))));
}


// Methods...

// Mostly a hack; assures that the second game we create is a "demo"
static BOOL alreadyLoadedAGame = NO;

- (id)initWithFrame:(NSRect)rect {
    if (!(self = [super initWithFrame:rect])) return nil;

    [self allocateGState];

    if (!alreadyLoadedAGame) {	// Hack; just allow one game
        alreadyLoadedAGame = YES;
    } else {
        [self setDemo:YES];
    }
    
    background = [[Background alloc] initInGame:self];

    NSInteger cnt;
    for (cnt = 0; cnt < LastGamePiece; cnt++) {
        pieces[cnt] = [[NSMutableArray alloc] init];
    }

    [self readHighScore];

    BOOL soundDisabled = [[NSUserDefaults standardUserDefaults] boolForKey:@"SoundDisabled"];
    [self setSoundRequested:!soundDisabled];

    [[self class] doNonLazyInitialization];
    
    return self;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (BOOL)isOpaque {
    return YES;
}

- (void)setDemo:(BOOL)flag {
    isDemo = flag;
}

- (BOOL)isDemo {
    return isDemo;
}

- (NSInteger)timeInMsSinceGameBegan {
    return 1000 * [[NSDate date] timeIntervalSinceDate:gameStartTime];
}

- (void)setHighscoreField:(NSTextField *)anObject {
    highscoreField = anObject;
    [highscoreField setIntegerValue:highScore];
}

- (void)markGameAsRunning {
    if (started == NO) {
        started = YES;
        [self displayRunningMessage];
        if (levelStartedAt == -1) levelStartedAt = updateTime;
    }
}

/* Convert a keypress to a command. Note that because the game uses the numberic keypad, and because we want the keys to work whether or not "NumLock" is enabled, we check the various function keys corresponding to the numbers on the keypad. 
*/
- (NSInteger)commandForKey:(NSInteger)key {
    switch (key) {
        case '8': case NSUpArrowFunctionKey:		
	    return GoUpCommand; 
        case '6': case NSRightArrowFunctionKey:	
	    return GoRightCommand; 
        case '2': case NSDownArrowFunctionKey:	
	    return GoDownCommand; 
        case '4':
	    return GoLeftCommand; 
        case '9': case NSPageUpFunctionKey:
	    return GoUpRightCommand; 
        case '3': case NSPageDownFunctionKey:
	    return GoDownRightCommand; 
        case '1': case NSEndFunctionKey:
	    return GoDownLeftCommand; 
        case '7': case NSHomeFunctionKey:
	    return GoUpLeftCommand; 
        case '5': case '0': case NSInsertFunctionKey: case NSLeftArrowFunctionKey:
	    return StopCommand; 
        case ' ': case '.': case NSDeleteFunctionKey:
	    return FireCommand; 
        default:
	    return NoCommand;
    }
}

/* Recognize a certain sequence of input keys to go into "cheat" mode */
static char bugCmd = '*';

- (void)keyDown:(NSEvent *)event {

    if ([self isPaused]) {
        [super keyDown:event];
    } else {
        NSInteger key = ([[event characters] length] < 1) ? '\0' : [[event characters] characterAtIndex:0];
        NSInteger command = [self commandForKey:key];

        switch (command) {
        case NoCommand:	// Cheat mode?
            if ((key == 'B' && bugCmd == '*') || (key == 'u' && bugCmd == 'B') || (key == 'g' && bugCmd == 'u')) {
                bugCmd = key;
                if (bugCmd == 'g') {
                    bugCmd = '*';
                    if (cheating != 0) {
                        [statusField setIntegerValue:cheating - 1];     // This displays the number of times the helicopter would have been destroyed
                        cheating = 0;
                    } else {
                        [statusField setStringValue:NSLocalizedString(@"Hey!", "Message displayed when the user switches into invincible mode")];
                        cheating = 1;
                    }
                }
            } else {
                bugCmd = '*';
                if (key == 'h') {	// Quick hide
                    [[NSApplication sharedApplication] hide:nil];
                } else {
                    [super keyDown:event];
                }
            }
            break;

        case FireCommand:
            [self markGameAsRunning];
            if (helicopter != nil) [helicopter startFiring];
            break;

        default:
            if (lastCommand != command) {
                if (lastCommand != NoCommand) {
                    [self stopLastCommand];
                }
                lastCommand = command;
                [self markGameAsRunning];
                if (helicopter != nil) [helicopter setCommand:lastCommand];
                [inputIndicator turnOn:command];
            }
            break;
        }
    }
}

- (void)keyUp:(NSEvent *)event {
    if ([self isPaused]) {
        [super keyUp:event];
    } else {
        NSInteger key = ([[event characters] length] < 1) ? '\0' : [[event characters] characterAtIndex:0];
        NSInteger command = [self commandForKey:key];

        if (command == FireCommand) {
            if (helicopter != nil) [helicopter stopFiring];
        } else if (command == lastCommand) {
            [self stopLastCommand];
        } else {
            [super keyUp:event];
        }
    }
}    

- (void)stopLastCommand {
    if (helicopter != nil) [helicopter setCommand:NoCommand];
    [inputIndicator turnOff:lastCommand];
    lastCommand = NoCommand; 
}

- (Helicopter *)helicopter {
    return helicopter;
}

- (Background *)background {
    return background;
}

- (void)updatePieces {
    NSInteger cnt;
    for (cnt = 0; cnt < LastGamePiece; cnt++) {
        NSInteger objectCnt = [pieces[cnt] count];
        while (objectCnt-- != 0) {
	    [[pieces[cnt] objectAtIndex:objectCnt] updatePiece];
        }
    } 
}

- (NSArray *)piecesOfType:(NSInteger)type {
    return pieces[type];
}

- (void)drawPieces {
    NSRect drawRect = [self currentBackgroundPosition];
    NSInteger pieceCnt; 

    [background draw:drawRect];

    for (pieceCnt = 0; pieceCnt < LastGamePiece; pieceCnt++) {
	NSInteger cnt;
	NSArray *pieceList = pieces[pieceCnt];
	for (cnt = [pieceList count] - 1; cnt >= 0; cnt--) {
            [[pieceList objectAtIndex:cnt] draw:drawRect];
	}
    }
}

- (void)drawRect:(NSRect)rect {
    [self drawPieces];
}

- (void)checkCollisions {
    NSInteger cnt;

    // Check friendly pieces against background and enemy bases

    for (cnt = [pieces[FriendlyPiece] count] - 1; cnt >= 0; cnt--) {
	BOOL hit = NO;
	NSInteger objCnt;
        GamePiece *piece = [pieces[FriendlyPiece] objectAtIndex:cnt];

	// If two friendly objects hit the same enemy object, second one won't blow up.

        for (objCnt = [pieces[StationaryEnemyPiece] count] - 1; objCnt >= 0; objCnt--) {
            GamePiece *enemy = [pieces[StationaryEnemyPiece] objectAtIndex:objCnt];
	    if ([piece touches:enemy]) {
		[enemy explode];
                hit = YES;
	    }
	}
        for (objCnt = [pieces[MobileEnemyPiece] count] - 1; objCnt >= 0; objCnt--) {
            GamePiece *enemy = [pieces[MobileEnemyPiece] objectAtIndex:objCnt];
	    if ([piece touches:enemy]) {
		[enemy explode];
		hit = YES;
	    }
	}

        if (hit || [piece touches:background]) {
	    if (helicopter == piece) {
                if (![self isDemo]) {
                    if (cheating == 0) {
                        [helicopter explode];
                        helicopter = nil;
                        lives--;
                        [livesField setIntegerValue:lives];
                    } else {
                        cheating++;
                    }
                }
	    } else {
                [piece explode];
	    }
	}
    }

    // Check mobile enemy against background

    for (cnt = [pieces[MobileEnemyPiece] count] - 1; cnt >= 0; cnt--) {
        GamePiece *piece = (GamePiece *)([pieces[MobileEnemyPiece] objectAtIndex:cnt]);
        if ([piece touches:background]) {
            [piece explode];
	}
    }
}

- (void)removeGamePiece:(GamePiece *)piece {
    [pieces[[piece pieceType]] removeObject:piece];
    if (piece == focusObject) focusObject = nil;
}

- (void)addGamePiece:(GamePiece *)piece {
    [pieces[[piece pieceType]] addObject:piece];
}

- (void)setFocusObject:(GamePiece *)piece {
    focusObject = piece;
}

- (NSInteger)updateTime {
    return updateTime;
}

- (NSInteger)elapsedTime {
    return elapsedTime;
}

- (NSRect)currentBackgroundPosition {
    NSRect rect = NSZeroRect;
    rect.size = [self bounds].size;
    if (focusObject == nil) {
        rect.origin = lastOrigin;
    } else {
        NSRect focusObjectRect = [focusObject rect];
        rect.origin.x = floor(NSMidX(focusObjectRect) - rect.size.width / 2.0);
        rect.origin.y = floor(NSMidY(focusObjectRect) - rect.size.height / 2.0);
        rect.origin.x = MAX(0.0, MIN(rect.origin.x, [background gameRect].size.width - rect.size.width));
	rect.origin.y = MAX(0.0, MIN(rect.origin.y, [background gameRect].size.height - rect.size.height));
	lastOrigin = rect.origin;
    }
    return rect;
}

- (void)doAward {
    NSRunAlertPanel(NSLocalizedString(@"BlastApp Completed", "Title of alert displayed when the game is successfully completed"), 
		    [NSString stringWithFormat:NSLocalizedString(@"Congratulations! You finished BlastApp with a score of %ld.", "Displayed when game is completed successfully"), (long)score],
		    NSLocalizedString(@"Great!", "Button of alert displayed when game is successfully completed"), nil, nil);
    if ([background levelFileIdentifier] == nil) {
	if (NSRunAlertPanel(NSLocalizedString(@"BlastApp Completed", "Title of alert displayed when the game is successfully completed"), 
			    NSLocalizedString(@"Would you like a certificate documenting your victory?  (Even if you don't have a printer you can save the certificate as a PDF file and print it later.)", "Displayed when game is completed successfully"), @"Yes", @"No", nil) == NSAlertDefaultReturn) {
	    [AwardView makeNewAwardForLevels:[background numLevels] score:score];
	}
    }
}

/*
  The main game loop
  This method is called at the desired frame rate (or lower...)
  elapsedTime allows us to compute travelled distances, etc correctly
*/
- (void)step:(NSTimer *)obj {
    NSInteger scoreBefore = score;

    numFrames++;
    elapsedTime = [self timeInMsSinceGameBegan] - updateTime;
    updateTime += elapsedTime;
	
    if (timing) {
        if (elapsedTime < 2000) {
            timingTime += elapsedTime;
            timingFrames += 1;
        }
    }

    if (elapsedTime > MAXUPDATETIME) {	// Upper bound on elaspedTime (otherwise objects start going through each other)
	if (timing) {
            timingMissed++;
	}
        [self stopGameFor:elapsedTime - MAXUPDATETIME];
        elapsedTime = MAXUPDATETIME;
    }


    [self updatePieces];

    [self checkCollisions];

    [self setNeedsDisplay:YES];

    if (!gameOver) {	// Check to see if the game is over
        if (helicopter != nil) {
            NSRect helicopterRect = [helicopter rect];
            if (![GamePiece intersectsRects:[background gameRect] :helicopterRect]) {  // Out of bounds
		if ([self isDemo]) {
                    [statusField setStringValue:NSLocalizedString(@"Level completed.", "Displayed in the status area when a level is completed in the demo version")];
		} else if (updateTime - timeStopped - levelStartedAt < MAXBONUSTIME) {
                    [self addScore:BONUS];
                    [statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Level %ld completed with bonus points!", "Displayed in the status area when a level is completed"), (long)level]];
                } else {
                    [statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Level %ld completed.", "Displayed in the status area when a level is completed"), (long)level]];
                }
		if ([self isDemo]) {
		    [self startLevel:(level < [background numLevels]) ? level + 1 : 1];
		} else if (level == [background numLevels]) {
                    gameOver = YES;
                    [self removeGamePiece:helicopter];
                    helicopter = nil;
                    [self updateHighScore];
                    [scoreField setIntegerValue:score];
                    [self doAward];
                    [statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Game completed with a score of %ld.", "Displayed in the status area when the game is completed"), (long)score]];
                } else {
                    [self startLevel:level + 1];
                }
            }
        }

        [self updateHighScore];
        
        if (focusObject == nil && !gameOver) {
            if (lives != 0) {
                if (lives == 1) {
                    [statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"One helicopter left. Ready to start.", "Displayed in the status area after a helicopter is destroyed but there is one left"), (long)lives]];
                } else {
                    [statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"%ld helicopters left. Ready to start.", "Displayed in the status area after a helicopter is destroyed but there is more than one left"), (long)lives]];
                }
                [self restartLevel];
            } else if (!bonusGiven && score >= 1000) {
                lives = 1;
                bonusGiven = YES;
                [statusField setStringValue:NSLocalizedString(@"You get a Bonus Helicopter!", "Displayed in the status area when the user gets a bonus helicopter after the last one is destroyed")];
                [self restartLevel];
            } else {
                [statusField setStringValue:newHighScore ? NSLocalizedString(@"Game over with a new high score.", "Displayed in the status area") : NSLocalizedString(@"All helicopters destroyed. Game Over.", "Displayed in the status area after the last helicopter is destroyed and there is none left")];
                gameOver = YES;
            }
        }
    }

    if (score != scoreBefore) {
        [scoreField setIntegerValue:score];
    }   

}

// The stop method will pause a running game. The go method will start it up
// again. They can be assigned to buttons or other appkit objects through IB.

- (void)go:(id)sender {
    if (timer == nil) {
    	if (lives != 0) {
            [self displayRunningMessage];
	} else {
            [statusField setStringValue:NSLocalizedString(@"Game Over.", "Displayed in the status area if user unpauses a game but has no helicopters left")];
	}

        timer = [NSTimer scheduledTimerWithTimeInterval:ANIMATIONINTERVAL target:self selector:@selector(step:) userInfo:self repeats:YES];

        [pauseButton setState:0];

        if (timing) {
            timingTime = 0;
            timingFrames = 0;
            timingMissed = 0;
        }
    }
    [[self window] makeFirstResponder:self];
}

- (void)stop:(id)sender {
    if (timer != nil) {
        [timer invalidate];
        timer = nil;

        pausedAt = [self timeInMsSinceGameBegan];
        [statusField setStringValue:NSLocalizedString(@"Paused.", "Displayed in the status area when the game is paused")];
        [pauseButton setState:1];
    }
}

- (BOOL)isPaused {
    return timer == nil;
}

- (void)togglePause:(id)sender {
    if (timer != nil) {
        [self stop:sender];
    } else {
 	NSInteger timeAdj = [self timeInMsSinceGameBegan] - pausedAt;
        [self stopGameFor:[Game maxInt:timeAdj :0]];
	[self go:sender];
    }
}

- (void)stopGameFor:(NSInteger)timeAdj {
    timeStopped += timeAdj;
}

- (void)startLevel:(NSInteger)newLevel {
    NSInteger cnt;

    level = MIN(newLevel, [background numLevels]);
    [levelField setIntegerValue:level];
    [self updateHighScore];

    for (cnt = 0; cnt < LastGamePiece; cnt++) {
        [pieces[cnt] removeAllObjects];
    }
    helicopter = nil;

    [background setLevel:level];

    [self restartLevel];
}

- (void)startGame:(id)sender {
    NSInteger startingLevel = (!levelMatrix || ([levelMatrix selectedTag] == 0)) ? highLevel : [levelSlider integerValue];
    [self startGame:sender atLevel:startingLevel];
}

- (void)startGame:(id)sender atLevel:(NSInteger)startingLevel {
    [self updateHighScore];

    lives = 3;
    score = 0;
    
    [livesField setIntegerValue:lives];
    [scoreField setIntegerValue:score];
        
    gameStartTime = [NSDate date];

    timeStopped = 0;	// Amount of time game was stopped (including overrun frames)

    updateTime = 0;	// The game clock, updated at start of the step method

    [self startLevel:startingLevel];
    [self go:nil];

    if (highScore == 0 && highLevel == 1) {
        [statusField setStringValue:NSLocalizedString(@"Welcome! See About Box for help.", "Displayed in the status area for a brand new user when a new game is started")];
    } else {
        [statusField setStringValue:NSLocalizedString(@"Ready to start new game.", "Displayed in the status area when a new game is started")];
    }
    gameOver = NO;
    newHighScore = NO;
    levelStartedAt = -1; 
}

/* 
  This method is called as a result of user action. If successful in changing the sound status, writes it out to the database. Thus if the user plays on a machine with no sound, their default setting won't be screwed up.
*/
- (void)toggleSound:(id)sender {
    BOOL newState = !soundRequested;
    [self setSoundRequested:newState];
    if (newState == soundRequested) {
	[[NSUserDefaults standardUserDefaults] setBool:!soundRequested forKey:@"SoundDisabled"];
    }
    [self updateSoundPref];
}

- (void)setSoundRequested:(BOOL)flag {
    soundRequested = flag && [[self class] setUpSounds];
}
    
- (void)setStartingLevel:(id)sender {
    [levelMatrix selectCellAtRow:1 column:0];
    [levelPrefsIndicator setIntegerValue:[sender integerValue]]; 
}

- (void)updateStartingLevelPrefs {
    if (levelMatrix != nil && [[levelMatrix window] isVisible]) {
        [levelSlider setMaxValue:(double)highLevel];
	if (highLevel < 2) {
            [levelSlider setEnabled:NO];
            [[levelMatrix cellAtRow:1 column:0] setEnabled:NO];
	} else {
            [levelSlider setEnabled:YES];
            [[levelMatrix cellAtRow:1 column:0] setEnabled:YES];
	}
    }
}

- (void)updateSoundPref {
    if (soundPrefItem != nil && [[soundPrefItem window] isVisible]) {
        [soundPrefItem setState:soundRequested ? 1 : 0];
    }
}

- (void)showPrefs:(id)sender {
    if (levelMatrix == nil) {
	if (![NSBundle loadNibNamed:@"Prefs" owner:self] || levelMatrix == nil) {
	    NSLog(@"Prefs.nib could not be loaded successfully.");
	}
        [(NSPanel *)[levelMatrix window] setBecomesKeyOnlyIfNeeded:YES];
    }
    [[levelMatrix window] makeKeyAndOrderFront:nil];
    [self updateStartingLevelPrefs];
    [self updateSoundPref];
}

static NSInteger hash (const char *str, NSInteger modBy) {
    NSInteger hash = 0;
    if (str) while (*str) hash = (hash + *str++) % modBy;
    return hash;
}

#define VERSIONWITHUSERNAME 'A'
#define VERSIONWITHOUTUSERNAME 'B'
#define MAGIC (MAXLEVELS+1)

- (void)writeHighScore {
    NSString *levelIdentifier = [background levelFileIdentifier];
    NSString *str = [NSString stringWithFormat:@"%c%ld", VERSIONWITHUSERNAME, (int)((highScore * MAGIC) + highLevel) * 99 + (hash([NSUserName() UTF8String], 49) + hash([levelIdentifier UTF8String], 50))];
    if (levelIdentifier) {
	[[NSUserDefaults standardUserDefaults] setObject:str forKey:[NSString stringWithFormat:@"HighScoreFor%@", levelIdentifier]];
    } else {
	[[NSUserDefaults standardUserDefaults] setObject:str forKey:@"HighScore"];
    }
}

- (void)readHighScore {
    NSString *tmpstr;
    NSString *levelIdentifier = [background levelFileIdentifier];

    highLevel = 1;
    highScore = 0;

    if (levelIdentifier) {
	tmpstr = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"HighScoreFor%@", levelIdentifier]];
    } else {
	tmpstr = [[NSUserDefaults standardUserDefaults] objectForKey:@"HighScore"];
    }

    if (tmpstr && [tmpstr length] > 1) {
	NSInteger value = [[tmpstr substringFromIndex:1] integerValue];
	NSString *userName = nil;
	switch ([tmpstr characterAtIndex:0]) {
	    case VERSIONWITHUSERNAME: userName = NSUserName(); break;
	    case VERSIONWITHOUTUSERNAME: userName = @"nousername"; break;
	}
	if (userName && ((value % 99) == (hash([userName UTF8String], 49) + hash([levelIdentifier UTF8String], 50)))) {
	    value /= 99;
	    highLevel = MAX(1, MIN(value % MAGIC, MAXLEVELS));
	    highScore = MAX(0, value / MAGIC);
	}
    }
}

- (void)updateHighScore {
    newHighScore = newHighScore || (score > highScore);
    if (score > highScore || level > highLevel) {
	highScore = MAX(score, highScore);
	highLevel = MAX(level, highLevel);
        [highscoreField setIntegerValue:highScore];
        [self updateStartingLevelPrefs];
        [self writeHighScore];
    }
}

- (void)restartLevel {
    NSPoint startLocation = NSMakePoint(HELICOPTERSTARTX, HELICOPTERSTARTY);
    NSSize zero = NSMakeSize(0.0, 0.0);

    if ([self isDemo]) {
	helicopter = [[AutoPilotHelicopter alloc] initInGame:self];
    } else {
	helicopter = [[Helicopter alloc] initInGame:self];
    }
    [self addGamePiece:helicopter];    
    [self setFocusObject:helicopter];
    [helicopter setLocation:startLocation];    
    [helicopter setVelocity:zero];    
    [helicopter setAcceleration:zero];

    started = NO;
    lastCommand = NoCommand;
}

- (void)addScore:(NSInteger)points {
    score += points * level;
}

- (void)displayRunningMessage {
    if (lives == 3) {
        [statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Welcome to %@", "Greeting in the status area in a freshly started game; the argument is the level description, for instance 'Level Five, the Easy Level'"), [background levelDescription]]];
    } else {
        [statusField setStringValue:[NSString stringWithFormat:NSLocalizedString(@"Running in %@", "Greeting in the status area after a level change; the argument is the level description, for instance 'Level Five, the Easy Level'"), [background levelDescription]]];
    }
}

// Delegate methods from window...

- (void)windowWillClose:(NSNotification *)notification {
    [self stop:nil];
}

- (void)windowDidMiniaturize:(NSNotification *)notification {
    [self stop:nil];
}
@end

