/*
        File: MyViewController.m
    Abstract: Demonstrates using the AUTimePitch.
     Version: 1.0.1
    
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

#import "MyViewController.h"

@implementation MyViewController

@synthesize bus0Switch, bus0VolumeSlider, outputVolumeSlider, graphController;

#pragma mark-

- (void)awakeFromNib
{
    // load UI tick sound
    AudioServicesCreateSystemSoundID((CFURLRef)[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"tick" ofType:@"aiff"]], &tickSound);
    
    [levelIndicator setFrameRotation: 90.0];
    
    [self setValue:[NSNumber numberWithInt:1] forKeyPath:@"self.busEnabled"];
}

- (void)dealloc
{ 
    AudioServicesDisposeSystemSoundID(tickSound);
        
    [graphController release];
    
	[super dealloc];
}

#pragma mark-

// set the au values according to the UI state
- (void)setUIDefaults
{
    [self enableInput:bus0Switch];
    [self setInputVolume:bus0VolumeSlider];
    [self setOutputVolume:outputVolumeSlider];
    [graphController setTimeRate:1.0];
    oldValue = 1.0;
}

// update meter values
- (void)myTimerFireMethod:(NSTimer*)theTimer
{
    Float32 value = [graphController getMeterLevel];
    
    if (!isfinite(value)) value = -120;

    [levelIndicator setIntValue:roundtol(value)];
}

// toggle the metering timer
- (void)toggleTimer
{
   if ((YES == busEnabled) && (NSOnState == buttonState)) {
        if (nil == timer) {
            timer = [NSTimer timerWithTimeInterval:1.0/15 target:self selector:@selector(myTimerFireMethod:) userInfo:nil repeats:YES];
        
            [[NSRunLoop currentRunLoop] addTimer:timer forMode:(NSString *)kCFRunLoopCommonModes];
            printf("Metering Timer On\n");
        }
    } else {
        [timer invalidate];
        timer = nil;
        [levelIndicator setIntValue:-120]; // clear it
        printf("Metering Timer Off\n");
    }
}

#pragma mark- Actions

// handle input on/off switch action
- (IBAction)enableInput:(NSButton *)sender
{
    UInt32 inputNum = [sender tag];
    AudioUnitParameterValue isOn = (AudioUnitParameterValue)sender.intValue;
                                    
    [graphController enableInput:inputNum isOn:isOn];
    [self toggleTimer];
}

// handle input volume changes
- (IBAction)setInputVolume:(NSSlider *)sender
{
	UInt32 inputNum = [sender tag];
    AudioUnitParameterValue value = sender.floatValue;
    
    [graphController setInputVolume:inputNum value:value];
}

// handle output volume changes
- (IBAction)setOutputVolume:(NSSlider *)sender
{
    AudioUnitParameterValue value = sender.floatValue;
    
    [graphController setOutputVolume:value];
}

// set the rate
- (IBAction)setTimeRate:(NSSlider *)sender
{
    AudioUnitParameterValue value = sender.floatValue;
    
    if (0.0 == value) value = 0.25; // very slow
    
    if (value != oldValue) {
        oldValue = value;
        
        [graphController setTimeRate:value];
        
        AudioServicesPlaySystemSound(tickSound);
    }
}

// handle the button press
- (IBAction)buttonPressedAction:(NSButton *)sender
{
    [graphController runAUGraph];
    [self toggleTimer];
}

@end