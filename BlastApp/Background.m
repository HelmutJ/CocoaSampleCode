/*
     File: Background.m
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

#import "Background.h"
#import "Game.h"
#import "Mine.h"
#import "HorizMine.h"


#define LANDSCAPEHEIGHT 175
#define MAXLEVELNAMELENGTH 80
#define MAXNUMLANDSCAPESPECS 150
#define LANDSCAPEWIDTHPERSPEC 25	/* pixels */

#define levelData ((const char *)[levelDataAsData bytes])


@implementation Background

- (CGFloat)codeToHeight:(NSInteger)code {
    return (CGFloat)(LANDSCAPEHEIGHT * (code - 'a') / (CGFloat)LANDSCAPEWIDTHPERSPEC);
}

- (NSInteger)codeToWidth:(NSInteger)code {
    return (NSInteger)(landscapeWidthInPixels * (code) / numLandscapeSpecs);
}

- (NSInteger)widthToPrevCode:(CGFloat)w {
    return (NSInteger)((w) / (landscapeWidthInPixels / numLandscapeSpecs));
}

- (NSInteger)widthToNextCode:(CGFloat)w {
    return (1 + (NSInteger)(((w) - 1) / (landscapeWidthInPixels / numLandscapeSpecs)));
}
        
- (id)initInGame:(Game *)g {
    NSString *levelFile;

    if ([g isDemo]) {
        levelFile = [[NSBundle mainBundle] pathForResource:@"DemoLevelData" ofType:@"txt"];
    } else {
        levelFile = [[NSUserDefaults standardUserDefaults] stringForKey:@"LevelFile"];
    }

    if (levelFile != nil) {
	levelFile = [levelFile stringByExpandingTildeInPath];
	if ([self initializeLevelData:[NSData dataWithContentsOfFile:levelFile]]) {
            if (![g isDemo]) {
                levelFileIdentifier = [[levelFile lastPathComponent] copy];
                NSLog(@"BlastApp: Using external level file %@.", levelFile);
            }
  	} else {
            NSRunAlertPanel(NSLocalizedString(@"Bad Level Data File", "Title of alert if the custom level data file is corrupt"), [NSString stringWithFormat:NSLocalizedString(@"The external level data file %@ doesn't exist or is illegal. Will use the default level data instead.", "Message in alert if the custom level data file is corrupt; the argument is the name of the level file"), levelFile], NSLocalizedString(@"Bummer", "Only button in the alert if the level data file is corrupt"), nil, nil);
	}
    }		

    if ([self numLevels] == 0) {	// Indicating we haven't read the level data yet...
        levelFile = [[NSBundle mainBundle] pathForResource:@"LevelData" ofType:@"txt"];
        if ((levelFile == nil) || ![self initializeLevelData:[NSData dataWithContentsOfFile:levelFile]]) {
	    NSLog(@"Bad level data, aborting.");
            [[NSApplication sharedApplication] terminate:nil];
	}
    }

    // Unfortunate that initInGame: is called so late, after some ivars are touched above (maxLevelSpecs, for instance)
    self = [self initInGame:g image:[[NSImage alloc] initWithSize:NSMakeSize(maxLevelSpecs * LANDSCAPEWIDTHPERSPEC, LANDSCAPEHEIGHT)] numFrames:1 numPoses:1 cache:NO];
    [self setPerFrameTime:10000000];

    bottom = malloc(maxLevelSpecs * LANDSCAPEWIDTHPERSPEC * sizeof(short));
    top = malloc(maxLevelSpecs * LANDSCAPEWIDTHPERSPEC * sizeof(short));

    return self;
}

- (void)dealloc {
    free(bottom);
    free(top);
}

- (NSRect)gameRect {
    return gameRect;
}

- (NSString *)levelFileIdentifier {
    return levelFileIdentifier;
}

- (NSInteger)numLevels {
    return numLevels;
}

// Returns the start of the next line; pins at end of the file or \0

static NSInteger advanceToNextLine(const char *ptr, NSInteger cnt) {
    while (ptr[cnt] != 0 && ptr[cnt++] != '\n');
    return cnt;
}

// Loads the data and sets number of levels; if data is bad, returns false

- (BOOL)initializeLevelData:(NSData *)data {
    levelDataAsData = [data copy];
    BOOL done = NO;
    NSInteger cnt = 0, tmp;
    while (!done) {
        switch ((char)levelData[cnt]) {
            case '%':
                cnt = advanceToNextLine(levelData, cnt);
                break;
            case '+':
                numLevels++;
                cnt = advanceToNextLine(levelData, cnt);
                cnt = advanceToNextLine(levelData, cnt);
                tmp = advanceToNextLine(levelData, cnt);
                if (tmp - cnt - 2 > maxLevelSpecs) maxLevelSpecs = tmp - cnt - 2;	/* 1 for end of line, 1 for the extra spec */
                cnt = tmp;
                cnt = advanceToNextLine(levelData, cnt);
                cnt = advanceToNextLine(levelData, cnt);
                break;
            case '$':
		done = YES;
		break;
            default:
                done = YES;
                numLevels = 0;
                break;
        }
    }
    return numLevels > 0;
}    

- (BOOL)getLevelData:(NSInteger)level {
    NSInteger cnt = 0;
    NSInteger levelCnt = 0;

    while (levelCnt != level) {
        switch ((char)levelData[cnt]) {
	case '%':
            cnt = advanceToNextLine(levelData, cnt);
	    break;
	case '+':
	    levelCnt++;
	    NSInteger nameLoc = cnt + 1;
            cnt = advanceToNextLine(levelData, cnt);
            NSInteger colorLoc = cnt;
	    cnt = advanceToNextLine(levelData, cnt);
	    topSpec = cnt;
            cnt = advanceToNextLine(levelData, cnt);
            bottomSpec = cnt;
            cnt = advanceToNextLine(levelData, cnt);
            gamePieces = cnt;
            cnt = advanceToNextLine(levelData, cnt);
	    if (levelCnt == level) {
                cnt = advanceToNextLine(levelData, nameLoc);
		levelDescription = [[NSString alloc] initWithBytes:levelData + nameLoc length:cnt - nameLoc - 1 encoding:NSUTF8StringEncoding];
                numLandscapeSpecs = bottomSpec - topSpec - 2;	/* One for EOL, one for the extra spec */
                landscapeWidthInPixels = numLandscapeSpecs * LANDSCAPEWIDTHPERSPEC;
                gameRect = NSMakeRect(0, 0, landscapeWidthInPixels, LANDSCAPEHEIGHT);

		const char *colorSpec = levelData + colorLoc;
		groundColor = [NSColor brownColor];
		NSInteger len = topSpec - colorLoc - 1;
		if (len > 6 && !strncmp(colorSpec, "random", 6)) {
		    groundColor = [NSColor colorWithCalibratedHue:[Game randInt:100]/100 saturation:1.0 brightness:1.0 alpha:1.0];
		} else {
		    float r, g, b;
		    if (sscanf(colorSpec, "%f %f %f", &r, &g, &b) == 3) groundColor = [NSColor colorWithCalibratedRed:r green:g blue:b alpha:1.0];
		}
	 	return YES;
	    }
	    break;
	default:
	    return NO;
        }
    }
    return NO;
}    
	
- (void)setLevel:(NSInteger)level {
    if (level > [self numLevels]) {
    	level = [self numLevels];
    }
    
    if (![self getLevelData:level]) {
	NSRunAlertPanel(NSLocalizedString(@"Bad Level Data", "Title of alert if a level in the level data file is corrupt"), [NSString stringWithFormat:NSLocalizedString(@"Sorry, level %ld is under construction.", "Message of alert if a level in the level data file is corrupt; the argument is the level number"), (long)level], NSLocalizedString(@"Bummer", "Only button in the alert if the level data file is corrupt"), nil, nil);
        while (--level != 0 && ![self getLevelData:level]);
	if (level == 0) {
	    NSLog(@"Bad level data file, aborting.");
            [[NSApplication sharedApplication] terminate:nil];
	}
    }

    currentLevel = level;

    [self createLandscape];
    [images lockFocus];
    [self drawLandscape];
    [images unlockFocus];
}

- (NSString *)levelDescription {
    return levelDescription;
}

- (void)washToBlack:(NSColor *)color size:(NSSize)size {
    CGFloat hue = [color hueComponent];
    CGFloat curHeight;
    NSRect rect = NSMakeRect(0.0, 0.0, size.width, 1.0);
    for (curHeight = 0; curHeight < size.height; curHeight++) {
        CGFloat brightness = 0.5 * (curHeight / size.height);
        [[NSColor colorWithCalibratedHue:hue saturation:1.0  brightness:brightness alpha:1.0] set];
        rect.origin.y = curHeight;
        [NSBezierPath fillRect:rect];
    }
}

- (void)washToWhite:(NSColor *)color size:(NSSize)size {
    CGFloat hue = [color hueComponent];
    CGFloat curHeight;
    NSRect rect = NSMakeRect(0.0, 0.0, size.width, 1.0);
    for (curHeight = 0; curHeight < size.height; curHeight++) {
        CGFloat saturation = 0.5 * (curHeight / size.height);
        [[NSColor colorWithCalibratedHue:hue saturation:saturation brightness:1.0 alpha:1.0] set];
        rect.origin.y = curHeight;
        [NSBezierPath fillRect:rect];
    }
}

- (void)drawLandscape {
    NSColor *color;
    NSInteger cnt;
    NSBezierPath *path;
    NSPoint point = NSZeroPoint;

    color = groundColor;

    [color set];
    [self washToBlack:color size:[self size]];
        
    path = [[NSBezierPath alloc] init];
    point.x = 0.0;
    point.y = 0.0;
    [path moveToPoint:point];
    for (cnt = 0; cnt <= numLandscapeSpecs; cnt++) {
        point.x = (CGFloat)[self codeToWidth:cnt];
        point.y = (CGFloat)[self codeToHeight:levelData[topSpec + cnt]];
        [path lineToPoint:point];
    }
    for (cnt = numLandscapeSpecs; cnt >= 0; cnt--) {
        point.x = (CGFloat)[self codeToWidth:cnt];
        point.y = (CGFloat)[self codeToHeight:levelData[bottomSpec + cnt]];
	[path lineToPoint:point];
    }
    [path closePath];
    [path setClip];
    
    [self washToWhite:color size:[self size]];
}

- (void)draw:(NSRect)rect {
    [images drawAtPoint:NSZeroPoint fromRect:rect operation:NSCompositeCopy fraction:1.0];
}

- (void)createLandscape {
    NSInteger spec, cnt;
    CGFloat vels[] = {MAXVELY/2.0, MAXVELY/3.0, MAXVELY/4.0, MAXVELY/5.0};	// vels is used to map 4 consecutive characters to velocities
    
    /* First create the elevation data to be used in collision detection. */
    
    for (spec = 0; spec < numLandscapeSpecs; spec++) {
        CGFloat bottomSlope = (CGFloat)([self codeToHeight:levelData[bottomSpec + spec + 1]] - [self codeToHeight:levelData[bottomSpec + spec]]) / (CGFloat)([self codeToWidth:spec + 1] - [self codeToWidth:spec]);
        CGFloat topSlope = (CGFloat)([self codeToHeight:levelData[topSpec + spec + 1]] - [self codeToHeight:levelData[topSpec + spec]]) / (CGFloat)([self codeToWidth:spec + 1] - [self codeToWidth:spec]);

	for (cnt = [self codeToWidth:spec]; cnt < [self codeToWidth:spec + 1]; cnt++) {
            bottom[cnt] = (short)([self codeToHeight:levelData[bottomSpec + spec]] + (bottomSlope * (cnt - [self codeToWidth:spec])));
            top[cnt] = (short)([self codeToHeight:levelData[topSpec + spec]] + (topSlope * (cnt - [self codeToWidth:spec])));
	}
    }

    spec = 0;
    while (spec < numLandscapeSpecs) {
	GamePiece *piece = nil;
        char cur = levelData[gamePieces + spec];
        CGFloat bottomHeight = floor([self codeToHeight:levelData[bottomSpec + spec]]);
        CGFloat topHeight = floor([self codeToHeight:levelData[topSpec + spec]]);

	switch (cur) {
            case '.':
                break;

            case 'a':
            case 'b':
            case 'F':
            case '2':
		switch((char)cur) {
                    case 'a': piece = [NSClassFromString(@"MissileBase") alloc]; break;
                    case 'b': piece = [NSClassFromString(@"SmartMissileBase") alloc];  break;
                    case 'F': piece = [NSClassFromString(@"RapidFireMissileBase") alloc];  break;
                    case '2': piece = [NSClassFromString(@"KillerMissileBase") alloc];  break;
		}
                piece = [piece initInGame:game];
                [piece setLocation:NSMakePoint(floor([self codeToWidth:spec] + [self codeToWidth:1] / 2.0)  - ([piece size].width / 2.0), bottomHeight)];
                [game addGamePiece:piece];
                break;

            case 'c':	
            case 'E': 	
            case 'J':	
            case '5':	
            case '6':
                switch((char)cur) {
                    case 'c': piece = [NSClassFromString(@"HangingBase") alloc]; break;
                    case 'E': piece = [NSClassFromString(@"RapidFireHangingBase") alloc]; break;	
                    case '5': piece = [NSClassFromString(@"DumHangingBase") alloc]; break;
                    case 'J': piece = [NSClassFromString(@"SmartHangingBase") alloc]; break;
                    case '6': piece = [NSClassFromString(@"SneakyHangingBase") alloc]; break;
                }
                piece = [piece initInGame:game];
		[piece setLocation:NSMakePoint(floor([self codeToWidth:spec] + [self codeToWidth:1] / 2.0) - ([piece size].width / 2), topHeight - ([piece size].height))];
                [game addGamePiece:piece];
	        break;

            case 'd':
            case 'e':
            case 'f':
            case 'g':
                [self putMine:[NSClassFromString(@"SmallMine") alloc] :spec :vels[cur - 'd']];
                break;

            case 'h':
                [self putMine:[NSClassFromString(@"SmallMine") alloc] :spec :MAXVELY * (RANDINT(60) / 100)];
                break;

            case 'j':
            case 'k':
            case 'l':
            case 'm':
                [self putMine:[NSClassFromString(@"Sentry") alloc] :spec :vels[cur - 'j']];
                break;

            case 'n':
                [self putMine:[NSClassFromString(@"Sentry") alloc] :spec :MAXVELY * ((10.0 + RANDINT(30)) / 100.0)];
                break;

            case 'o':
            case 'p':
            case 'q':
            case 'r':
                [self putMine:[NSClassFromString(@"FatSentry") alloc] :spec :vels[cur - 'o']];
                break;
            case 's':
                [self putMine:[NSClassFromString(@"FatSentry") alloc] :spec :MAXVELY * ((10.0 + RANDINT(40)) / 100.0)];
                break;

            case 't':
                [self putMine:[NSClassFromString(@"LargeMine") alloc] :spec :MAXVELY/14.0];
                break;

            case 'u':
                [self putMine:[NSClassFromString(@"Fog") alloc] :spec :([Game oneIn:2] ? (MAXVELY * (RANDINT(30) / 200.0)) : 0.0)];
                break;
	
            case 'w':
                [self putMine:[NSClassFromString(@"SmartMine") alloc] :spec :MAXVELY * ((.25 + RANDINT(30)) / 100.0)];
		break;

            case 'z':
                [self putMine:[NSClassFromString(@"RealSmartMine") alloc] :spec :MAXVELY * ((.4 + RANDINT(40)) / 100.0)];
                break;

            case 'v':	
                piece = [[NSClassFromString(@"BackShooter") alloc] initInGame:game];
		[piece setLocation:NSMakePoint(floor([self codeToWidth:spec] + [self codeToWidth:1] / 2.0) - ([piece size].width / 2.0), bottomHeight)];
                [game addGamePiece:piece];
                break;

            case 'A':
            case 'B':
            case 'C':
                [self putMine:[NSClassFromString(@"AmeobaMine") alloc] :spec :vels[cur - 'A']];
                break;

            case 'D':
                [self putMine:[NSClassFromString(@"StopMine") alloc] :spec :MAXVELY * ((10.0 + RANDINT(40)) / 100.0)];
                break;

            case 'G':
                [self putMine:[NSClassFromString(@"RandomMine") alloc] :spec :MAXVELY / 2.0];
                break;

            case 'H':
                [self putMine:[NSClassFromString(@"Throton") alloc] :spec :MAXVELY / 4.0];
                break;

            case '8':
                [self putMine:[NSClassFromString(@"Throton") alloc] :spec :MAXVELY / 3.0];
                break;

            case 'I':
                [self putMine:[NSClassFromString(@"Throton") alloc] :spec :MAXVELY * ((10.0 + RANDINT(40)) / 100.0)];
                break;

            case 'L':
                [self putMine:[NSClassFromString(@"ProximityMine") alloc] :spec :0.0 :0.0];
                break;

            case '@':
                [self putMine:[NSClassFromString(@"DonutMine") alloc] :spec :MAXVELY :0.5];
                break;

            case 'x': 	
            case 'K':
            case 'M':	
            case 'O':	
            case 'P':	
                switch((char)cur) {
                    case 'x': piece = [NSClassFromString(@"DropShip") alloc]; break;
                    case 'K': piece = [NSClassFromString(@"RapidFireDropShip") alloc]; break;	
                    case 'M': piece = [NSClassFromString(@"AttackShip") alloc]; break;
                    case 'O': piece = [NSClassFromString(@"BigAttackShip") alloc]; break;
                    case 'P': piece = [NSClassFromString(@"SmartAttackShip") alloc]; break;
                }
                piece = [piece initInGame:game];
		[piece setLocation:NSMakePoint(floor([self codeToWidth:spec] + [self codeToWidth:1] / 2.0), floor((bottomHeight + topHeight) / 2.0))];
                [game addGamePiece:piece];
                break;

            case 'y':
                piece = [[NSClassFromString(@"ArrowBase") alloc] initInGame:game];
		[piece setLocation:NSMakePoint(floor([self codeToWidth:spec] + [self codeToWidth:1] / 2.0) - ([piece size].width / 2.0), bottomHeight)];
                [game addGamePiece:piece];
                break;

            case '+':	
                piece = [[NSClassFromString(@"Switch") alloc] initInGame:game];
		[piece setLocation:NSMakePoint(floor([self codeToWidth:spec] + [self codeToWidth:1] / 2.0), bottomHeight + 5.0)];
                [game addGamePiece:piece];
		break;

            case 'N':
                [self putMine:[NSClassFromString(@"Gunes") alloc] :spec :MAXVELY * ((10.0 + RANDINT(30)) / 100.0)];
                break;

            case '&':
                [self putMine:[NSClassFromString(@"FourMines") alloc] :spec :MAXVELY / 4.0];
                break;

            case 'Q':
            case 'R':
                [self putMine:[NSClassFromString(@"TimedVertGate") alloc] :spec :(cur == 'Q') ? 0.0 : MAXVELY / 4.0 :0.5];
                break;

            case '*':
                [self putMine:[NSClassFromString(@"Hole") alloc] :spec :0.0 :0.5];
                break;

            case 'S':
                [self putHorizMine:[NSClassFromString(@"GoodSheep") alloc] :spec :MAXVELX / ([Game randInt:4] + 4.0) :0.0];
                break;

            case 'V':
                [self putHorizMine:[NSClassFromString(@"ToughGoodSheep") alloc] :spec :MAXVELX / ([Game randInt:4] + 4.0) :0.0];
                break;

            case '4':
                [self putHorizMine:[NSClassFromString(@"BadSheep") alloc] :spec :MAXVELX / ([Game randInt:4] + 4.0) :0.0];
                break;

            case 'U':
                [self putMine:[NSClassFromString(@"PassableVertGate") alloc] :spec :0.0 :0.5];
                break;

            case '9':
                [self putMine:[NSClassFromString(@"SwitchedVertGate") alloc] :spec :0.0 :0.5];
                break;

            case 'T':
                [self putMine:[NSClassFromString(@"TimedHorizGate") alloc] :spec :0.0 :0.5];	/* ??? Should this be putHorizMine */
                break;

            case 'W':
                [self putMine:[NSClassFromString(@"WaveGenerator") alloc] :spec :MAXVELY];
                break;

            case '$':
                [self putMine:[NSClassFromString(@"KillerWaveGenerator") alloc] :spec :MAXVELY];
                break;

            case '3':
                [self putMine:[NSClassFromString(@"BombGenerator") alloc] :spec :0.0];
                break;

            case 'Y':
                [self putMine:[NSClassFromString(@"BoingBall") alloc] :spec :0.0 :0.8];
                break;

            case 'X':
                [self putMine:[NSClassFromString(@"BubbleMine") alloc] :spec :0.0 :((2.0 + RANDINT(6)) / 10.0)];
                break;

            case 'Z':
                [self putMine:[NSClassFromString(@"BouncingBoingBall") alloc] :spec :MAXVELY :0.0];
                break;

            case '7':
                [self putMine:[NSClassFromString(@"SneakyBoingBall") alloc] :spec :0.0 :0.95f];
                break;

            case '0':
                [self putHorizMine:[NSClassFromString(@"Spider") alloc] :spec :MAXVELX / 3.0 :0.0];
                break;

            case '1':
                [self putHorizMine:[NSClassFromString(@"ToughSpider") alloc] :spec :MAXVELX / 2.8f :0.0];
                break;

            default:
                NSLog(@"Unknown game piece indicator '%c'", cur);
                break;
            
	}
	spec++;
    }

}

// If locFromBottomPercentage >= 1.0, then random placement.

- (void)putMine:(Mine *)mine :(NSInteger)loc :(CGFloat)yVel :(CGFloat)locFromBottomPercentage {
    CGFloat bottomHeight = 0.0;
    CGFloat topHeight = 100000.0;
    NSPoint mineLocation = NSMakePoint([self codeToWidth:loc], 0.0);
    NSSize mineVelocity = NSMakeSize(0.0, yVel);
    NSSize mineSize;
    NSInteger cnt;

    mine = [mine initInGame:game];
    mineSize = [mine size];
    for (cnt = loc; cnt <= loc + [self widthToNextCode:mineSize.width]; cnt++) {
        bottomHeight = [Game maxFloat:bottomHeight :[self codeToHeight:levelData[bottomSpec + cnt]]];
        topHeight = [Game minFloat:topHeight :[self codeToHeight:levelData[topSpec + cnt]]];
    }
    bottomHeight += 2.0;
    topHeight -= 2.0;
    if (bottomHeight >= topHeight) {
	NSLog(@"Can't place mine %@ at %ld.", mine, (long)loc);
	return;
    }

    if (locFromBottomPercentage >= 1.0) {
	mineLocation.y = bottomHeight + RANDINT((NSInteger)(topHeight - bottomHeight));
    } else {
        mineLocation.y = bottomHeight + (NSInteger)((topHeight - mineSize.height - bottomHeight) * locFromBottomPercentage);
    }
    [mine setHigh:topHeight low:bottomHeight];
    [mine setVelocity:mineVelocity];
    [mine setLocation:mineLocation]; 
    [game addGamePiece:mine];
}

- (void)putHorizMine:(HorizMine *)mine :(NSInteger)loc :(CGFloat)xVel :(CGFloat)locFromBottomPercentage {
    CGFloat bottomHeight = [self codeToHeight:levelData[bottomSpec + loc]];
    CGFloat topHeight = 100000.0;
    CGFloat leftLoc = 100000.0;
    CGFloat rightLoc = -100000.0;
    NSPoint mineLocation = NSMakePoint([self codeToWidth:loc], 0.0);
    NSSize mineVelocity = NSMakeSize(xVel, 0.0);
    NSSize mineSize;
    NSInteger cnt;

    mine = [mine initInGame:game];
    mineSize = [mine size];
    for (cnt = loc; cnt <= loc + [self widthToNextCode:mineSize.width]; cnt++) {
        topHeight = [Game minFloat:topHeight :[self codeToHeight:levelData[topSpec + cnt]]];
    }
    cnt = loc;
    while (cnt > 1 && (levelData[bottomSpec + loc] == levelData[bottomSpec + cnt - 1])) cnt--;
    leftLoc = [self codeToWidth:cnt];
    cnt = loc;
    while (cnt < numLandscapeSpecs - 1 && (levelData[bottomSpec + loc] == levelData[bottomSpec + cnt + 1])) cnt++;
    rightLoc = [self codeToWidth:cnt];

    if (locFromBottomPercentage >= 1.0) {
	mineLocation.y = bottomHeight + RANDINT((NSInteger)(topHeight - mineSize.height - bottomHeight));
    } else {
        mineLocation.y = bottomHeight + (NSInteger)((topHeight - bottomHeight) * locFromBottomPercentage);
    }
    [mine setLeft:leftLoc right:rightLoc];
    [mine setVelocity:mineVelocity];
    [mine setLocation:mineLocation];
    [game addGamePiece:mine];
}

- (void)putMine:(Mine *)mine :(NSInteger)loc :(CGFloat)yVel {
    [self putMine:mine :loc :yVel :1.0];
}

- (BOOL)touches:(GamePiece *)obj {
    return (obj != self && [obj touches:self]);
}
 
- (BOOL)touchesRect:(NSRect)rect {
    NSInteger from = [Game minInt:[Game maxInt:0 :(NSInteger)rect.origin.x] :landscapeWidthInPixels-1];
    NSInteger to = [Game minInt:[Game maxInt:0 :(NSInteger)NSMaxX(rect)] :landscapeWidthInPixels-1];

    while (from <= to) {
	if ((bottom[from] >= rect.origin.y) || (top[from] <= NSMaxY(rect))) return YES;
	from++;
    }

    return NO;
}

// Returns the area that is clear between the specified start and end locations...

- (NSRect)clearRectFrom:(CGFloat)startLoc to:(CGFloat)endLoc {
    NSInteger to = [Game maxInt:0 :[Game minInt:(NSInteger)endLoc :landscapeWidthInPixels - 1]];
    NSInteger from = [Game maxInt:0 :[Game minInt:(NSInteger)startLoc :landscapeWidthInPixels - 1]];
    NSInteger tmp;    
    CGFloat y1 = 0;
    CGFloat y2 = LANDSCAPEHEIGHT;

    for (tmp = from; tmp <= to; tmp++) {
        if (bottom[tmp] > y1) y1 = bottom[tmp];
	if (top[tmp] < y2) y2 = top[tmp];
    }
    return NSMakeRect(from, y1, to - from, y2 - y1);
}
@end

