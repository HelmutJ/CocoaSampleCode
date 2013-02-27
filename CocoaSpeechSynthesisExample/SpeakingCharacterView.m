/*

File: SpeakingCharacterView.m

Abstract: The custom view holding the speaking character.

Version: 1.4

Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
Inc. ("Apple") in consideration of your agreement to the
following terms, and your use, installation, modification or
redistribution of this Apple software constitutes acceptance of these
terms.  If you do not agree with these terms, please do not use,
install, modify or redistribute this Apple software.

In consideration of your agreement to abide by the following terms, and
subject to these terms, Apple grants you a personal, non-exclusive
license, under Apple's copyrights in this original Apple software (the
"Apple Software"), to use, reproduce, modify and redistribute the Apple
Software, with or without modifications, in source and/or binary forms;
provided that if you redistribute the Apple Software in its entirety and
without modifications, you must retain this notice and the following
text and disclaimers in all such redistributions of the Apple Software. 
Neither the name, trademarks, service marks or logos of Apple Inc.
may be used to endorse or promote products derived from the Apple
Software without specific prior written permission from Apple.  Except
as expressly stated in this notice, no other rights or licenses, express
or implied, are granted by Apple herein, including but not limited to
any patent rights that may be infringed by your derivative works or by
other works in which the Apple Software may be incorporated.

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

Copyright © 2000-2007 Apple Inc. All Rights Reserved

*/

#import "SpeakingCharacterView.h"

// Expression Identifiers
NSString *	kCharacterExpressionIdentifierSleep			= @"ExpressionIdentifierSleep";
NSString *	kCharacterExpressionIdentifierIdle			= @"ExpressionIdentifierIdle";
NSString *	kCharacterExpressionIdentifierConsonant		= @"ExpressionIdentifierConsonant";
NSString *	kCharacterExpressionIdentifierVowel			= @"ExpressionIdentifierVowel";

// Frame dictionary keys
static NSString *	kCharacterExpressionFrameDurationKey		= @"FrameDuration";				// TimeInterval
static NSString *	kCharacterExpressionFrameImageFileNameKey	= @"FrameImageFileName";


@interface SpeakingCharacterView (PrivateSpeakingCharacterView)

- (void)animateNextExpressionFrame;
- (void)startIdleExpression;
- (void)loadChacaterByName:(NSString *)name;

@end

@implementation SpeakingCharacterView

/*----------------------------------------------------------------------------------------
	initWithFrame:
	 
	Our designated initializer.  We load the default character and set the expression to sleep.
----------------------------------------------------------------------------------------*/
- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
	
		[self loadChacaterByName:@"Buster"];
		[self setExpression:kCharacterExpressionIdentifierSleep];
    }
    return self;
}

/*----------------------------------------------------------------------------------------
    initWithFrdrawRectame:
        
    Our main draw routine.
----------------------------------------------------------------------------------------*/
- (void)drawRect:(NSRect)rect {

    NSPoint	thePointToDraw;
    NSSize	sourceSize = [_curFrameImage size];
    NSSize	destSize = rect.size;
    
    if (destSize.width >= sourceSize.width)
        thePointToDraw.x = (destSize.width - sourceSize.width) / 2;
    else
        thePointToDraw.x = 0;
    
    if (destSize.height >= sourceSize.height)
        thePointToDraw.y = (destSize.height - sourceSize.height) / 2;
    else
        thePointToDraw.y = 0;
    
    [_curFrameImage compositeToPoint:thePointToDraw operation:(NSCompositingOperation)NSCompositeSourceOver fraction:1.0];
}

/*----------------------------------------------------------------------------------------
    setExpressionForPhoneme:
        
    Sets the current expression to the expression corresponding to the given phoneme ID.
----------------------------------------------------------------------------------------*/
- (void)setExpressionForPhoneme:(NSNumber *)phoneme;
{
    int	phonemeValue = [phoneme shortValue];

    if (phonemeValue == 0 || phonemeValue == 1)
        [self setExpression:kCharacterExpressionIdentifierIdle];
    else if (phonemeValue >= 2 && phonemeValue <= 17)
        [self setExpression:kCharacterExpressionIdentifierVowel];
    else
        [self setExpression:kCharacterExpressionIdentifierConsonant];
}

/*----------------------------------------------------------------------------------------
    setExpression:
	 
    Sets the current expression to the named expresison identifier, then forces the
    character image on screen to be updated.
----------------------------------------------------------------------------------------*/
- (void)setExpression:(NSString *)expression
{
    // Set up to begin animating the frames
    [_expressionFrameTimer invalidate];
    _expressionFrameTimer = NULL;
    [_currentExpression release];
    _currentExpression = [expression retain];
    _curFrameArray = [_characterDescription objectForKey:_currentExpression];
    _curFrameIndex = 0;
    [self animateNextExpressionFrame];
    
    // If the expression we just set is NOT the idle or sleep expression, then set up the idle start timer.
    if (! ([expression isEqualToString:kCharacterExpressionIdentifierIdle] || [expression isEqualToString:kCharacterExpressionIdentifierSleep])) {
        [_idleStartTimer invalidate];
        _idleStartTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startIdleExpression) userInfo:NULL repeats:NO];
    }
    else {
        [_idleStartTimer invalidate];
        _idleStartTimer = NULL;
    }
}

/*----------------------------------------------------------------------------------------
    animateNextExpressionFrame
	 
    Determines the next frame to animate, loads the image and forces it to be drawn.  If 
    the expression contains multiple frames, sets up timer for the next frame to be drawn.
----------------------------------------------------------------------------------------*/
- (void)animateNextExpressionFrame
{
    _expressionFrameTimer = NULL;
    
    NSDictionary *	frameDictionary = [_curFrameArray objectAtIndex:_curFrameIndex];
    
    // Grab image and force draw.  Use cache to reduce disk hits
    NSString *	frameImageName = [frameDictionary objectForKey:kCharacterExpressionFrameImageFileNameKey];
    _curFrameImage = [_imageCache objectForKey:frameImageName];
    if (_curFrameImage == NULL) {
        _curFrameImage = [[NSImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:frameImageName ofType:@""]];
        [_imageCache setObject:_curFrameImage forKey:frameImageName];
        [_curFrameImage release];
    }
    [self display];
    
    // If there is more than one frame, then schedule drawing of the next and increment our frame index.
    if ([_curFrameArray count] > 0) {
        _curFrameIndex++;
        _curFrameIndex %= [_curFrameArray count];
        _expressionFrameTimer = [NSTimer scheduledTimerWithTimeInterval:[[frameDictionary objectForKey:kCharacterExpressionFrameDurationKey] floatValue] target:self selector:@selector(animateNextExpressionFrame) userInfo:NULL repeats:NO];
    }
}

/*----------------------------------------------------------------------------------------
    startIdleExpression
        
    Starts the idle expression.  Called by the idle timer after certain expressions (mainly
    phoneme expressions) expire.
----------------------------------------------------------------------------------------*/
- (void)startIdleExpression
{
    _idleStartTimer = NULL;
    
    [self setExpression:kCharacterExpressionIdentifierIdle];
}

/*----------------------------------------------------------------------------------------
    loadChacaterByName:
        
    Loads description dictionary for the named character and flushes any cached images.
----------------------------------------------------------------------------------------*/
- (void)loadChacaterByName:(NSString *)name
{
    [_imageCache release];
    _imageCache = [NSMutableDictionary new];
    [_characterDescription release];
    _characterDescription = [[NSDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:@"plist"]];
}

@end
