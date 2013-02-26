/*

File: FrequencyLevelsLayer.m

Abstract: Container that creates and handles the frequency levels 

Version: 1.0

Disclaimer: IMPORTANT:  This Apple software is supplied to you by 
Apple Inc. ("Apple") in consideration of your agreement to the
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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/ 

#import "FrequencyLevels.h"

#define LEVEL_OFFSET		8
#define LEVEL_WIDTH		30
#define LEVEL_HEIGHT		240

static UInt32 numberOfBandLevels    = 8;       // increase this number for more frequency bands
static UInt32 numberOfChannels       = 2;       // for StereoMix - If using DeviceMix, you need to get the channel count of the device.

@interface FrequencyLevels (internal)
    - (void)levelTimerMethod:(NSTimer*)theTimer;
@end

@implementation FrequencyLevels

//--------------------------------------------------------------------------------------------------

+ (FrequencyLevels*)levelsWithMovie:(QTMovie *)movie
{
    FrequencyLevels	*levels;

    levels = [[FrequencyLevels alloc] init];
    
    [levels setMovie:movie];
    
    return [levels autorelease];
}

//--------------------------------------------------------------------------------------------------

- (id)init
{
    CGImageRef freqLevelImage = nil;

    self = [super init];
	
    // allocate memory for the QTAudioFrequencyLevels struct and set it up
    // depending on the number of channels and frequency bands you want    
    mFreqResults = malloc(offsetof(QTAudioFrequencyLevels, level[numberOfBandLevels * numberOfChannels]));

    mFreqResults->numChannels = numberOfChannels;
    mFreqResults->numFrequencyBands = numberOfBandLevels;
    
    // create an array and load up the UI elements, each NSLevelIndicator has
    // the appropriate tag added in IB
    mFrequencyLayers = [NSMutableArray array];
    [mFrequencyLayers retain];

    // load image for the level indicator layers
    NSURL *imageURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"penguin" ofType:@"png"]];

    CGImageSourceRef source = CGImageSourceCreateWithURL((CFURLRef)imageURL, nil);
    freqLevelImage = CGImageSourceCreateImageAtIndex(source, 0, nil);
    CFRelease (source);

    // create the layers
    mContainer = [[CALayer layer] retain];
    [mContainer setBounds:CGRectMake (0, 0, ((numberOfBandLevels * numberOfChannels) * (LEVEL_WIDTH + LEVEL_OFFSET)) + LEVEL_OFFSET, LEVEL_HEIGHT)];

    int			i, j;
    // setup the center of the first layer
    CGFloat		x = LEVEL_OFFSET + (LEVEL_WIDTH * 0.5);

    for(j = 0; j < numberOfChannels; j++)
    {
        for(i = 0; i < numberOfBandLevels; i++)
        {
            CALayer *levelLayer = [CALayer layer];
            
            [levelLayer setBounds:CGRectMake (0, 0, LEVEL_WIDTH, LEVEL_HEIGHT)];
            // add some shadow
            levelLayer.shadowOpacity = 0.75;
            
            // save the layer in our frequency layer's array
            [mFrequencyLayers addObject:levelLayer];
            
            // append the layer to the container's sublayers array
            [mContainer addSublayer:levelLayer];
            
            // position the layer
            levelLayer.position = CGPointMake(x, 0);
            // set image as the default content
            levelLayer.contents = (id)freqLevelImage;
            
            if(j > 0)	// flip the right channel horizontally so the images are facing each other
                levelLayer.transform = CATransform3DMakeScale(-1.0, 1.0, 1.0);

            x += LEVEL_OFFSET + LEVEL_WIDTH;
        }
    }
    
    return self;
}

//--------------------------------------------------------------------------------------------------

- (void)dealloc
{
    // cleanup
    
    [mContainer release];
    
    [mFrequencyLayers release];
    
    free(mFreqResults);
    
    [super dealloc];
}

//--------------------------------------------------------------------------------------------------
//--------------------------------------------------------------------------------------------------

- (void)invalidate
{
    if ([[mMovie attributeForKey:QTMovieHasAudioAttribute] boolValue]) 
    {
        // do this once per movie to establish metering
        (void)SetMovieAudioFrequencyMeteringNumBands([mMovie quickTimeMovie], kQTAudioMeter_StereoMix, &numberOfBandLevels);
    }
}

//--------------------------------------------------------------------------------------------------

- (void)setMovie:(QTMovie *)inMovie
{
    mMovie = inMovie;
    if (mMovie)
    {
        [self invalidate];
        
        [mContainer setNeedsDisplay];
    }
}

//--------------------------------------------------------------------------------------------------

- (CALayer*)layer
{
    return mContainer;
}

//--------------------------------------------------------------------------------------------------

// called when the button is pressed - turns the level meters on/off by setting up a timer
- (void)toggleFreqLevels:(NSCellStateValue)state
{
    if (NSOnState == state) 
    {
    	// turning it on, set up a timer and add it to the run loop
        mTimer = [NSTimer timerWithTimeInterval:1.0/15 target:self selector:@selector(levelTimerMethod:) userInfo:nil repeats:YES];
        
        [[NSRunLoop currentRunLoop] addTimer:mTimer forMode:(NSString *)kCFRunLoopCommonModes];
		mContainer.hidden = NO;
    } 
    else 
    {
        // turning it off, stop the timer and hide the level layers
        [mTimer invalidate];
        mContainer.hidden = YES;
    }
}


//--------------------------------------------------------------------------------------------------

- (void)levelTimerMethod:(NSTimer*)theTimer
{
    UInt8 i, j;
    NSEnumerator *enumerator = [mFrequencyLayers objectEnumerator]; // get a enumerator for the array of NSLevelIndicator objects
    
    // get the levels from the movie
    OSStatus err = GetMovieAudioFrequencyLevels([mMovie quickTimeMovie], kQTAudioMeter_StereoMix, mFreqResults);
    if (!err) 
    {
        // iterate though the frequency level array and though the UI elements getting
        // and setting the levels appropriately
        for (i = 0; i < mFreqResults->numChannels; i++) 
        {
            for (j = 0; j < mFreqResults->numFrequencyBands; j++) 
            {
                // the frequency levels are Float32 values between 0. and 1.
                Float32 value = (mFreqResults->level[(i * mFreqResults->numFrequencyBands) + j]) * LEVEL_HEIGHT;
                CALayer		*layer = [enumerator nextObject];
                layer.bounds = CGRectMake(0, 0, LEVEL_WIDTH, value);
            }
        }
    }
}

@end
