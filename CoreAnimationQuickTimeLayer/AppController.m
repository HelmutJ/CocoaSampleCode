/*

File: AppController.m

Abstract: Main app controller

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

#import "AppController.h"

@interface AppController (private)

- (void)loadMovie:(NSString *)path;

@end

@implementation AppController

//--------------------------------------------------------------------------------------------------

- (void)awakeFromNib
{
    // setup the content view to use layers
    [[contentWindow contentView] setWantsLayer:YES];
    
    // create a root layer to contain all of our layers
    CALayer *root = [[contentWindow contentView] layer];
    // use constraint layout to allow sublayers to center themselves
    root.layoutManager = [CAConstraintLayoutManager layoutManager];

    // create a new layer which will contain all our sublayers
    mContainer = [CALayer layer];
    mContainer.bounds = root.bounds;
    mContainer.frame = root.frame;
    mContainer.position = CGPointMake(root.bounds.size.width * 0.5, root.bounds.size.height * 0.5);
    
    // insert layer on the bottom of the stack so it is behind the controls
    [root insertSublayer:mContainer atIndex:0];
    
    // make it resize when its superlayer does
    root.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
    
    // make it resize when its superlayer does
    mContainer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
}

//--------------------------------------------------------------------------------------------------

- (void)applicationWillFinishLaunching:(NSNotification *)note
{
    mQTMovie = nil;
	
    // See if we have a known pathname
    NSString *moviePath = [[NSUserDefaults standardUserDefaults] stringForKey:@"MoviePath"];
    if(moviePath)
    {
        // load movie from known path
        [self loadMovie:moviePath];
    } 
    else 
    {
        // prompt user for a new movie file
        [self performSelector:@selector(openMovie:) withObject:self afterDelay:0];
    }
}

//--------------------------------------------------------------------------------------------------

- (void)openMovie:(id)sender
{
    NSOpenPanel *openPanel;
    // setup open panel dialog params
    openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setResolvesAliases:YES];
    [openPanel setCanChooseFiles:YES];
    [openPanel setTitle:@"Select a movie with audio"];
    
    // ask user to select a new movie file
    int rv = [openPanel runModalForTypes:nil];
    if(rv == NSFileHandlingPanelOKButton)
    {
        [self loadMovie:[openPanel filename]];
    }
}

//--------------------------------------------------------------------------------------------------

- (void)loadMovie:(NSString *)path
{
    NSError	*error;
        
    [mQTMovie release];
    
    // create QTMovie object for the selected movie file
    mQTMovie = [[QTMovie movieWithFile:path error:&error] retain];
    if(mQTMovie)
    {
        // if we already have a movie layer, just set the movie on it
        if(mMovieLayer)
        {
            [mMovieLayer setMovie:mQTMovie];
            
            // size the layer
            mMovieLayer.frame = mContainer.frame;
        } 
        else 
        {
            // create our movie layer
            mMovieLayer = [QTMovieLayer layerWithMovie:mQTMovie];
            // size the layer
            mMovieLayer.frame = mContainer.frame;
            // scale the movie layer with the container (it will resize with the window)
            mMovieLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;
            
            // insert layer on the bottom of the stack
            [mContainer insertSublayer:mMovieLayer atIndex:0];
            
            // center it on the mContainer
            mMovieLayer.position = mContainer.position;
        }
        
        // start the movie playing
        [mQTMovie play];

        // if we already have a frequency level container, just set the movie on it
        if(mLevels)
        {
            [mLevels setMovie:mQTMovie];
        } 
        else 
        {
            // create frequency level container
            mLevels = [[FrequencyLevels levelsWithMovie:mQTMovie] retain];
            
            // keep the levels layer at the same size
            [mLevels layer].autoresizingMask = kCALayerMinXMargin | kCALayerMaxXMargin | kCALayerMinYMargin | kCALayerMaxYMargin;
            
            [mContainer addSublayer:[mLevels layer]];
            
            [mLevels layer].position = mContainer.position;
            [mLevels toggleFreqLevels:[frequencyLevels state]];
        }
        
        // save movie path as default for next time
        [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"MoviePath"];
        [[NSUserDefaults standardUserDefaults] synchronize];

        // set window title
        [contentWindow setTitleWithRepresentedFilename:path];
    }
}

//--------------------------------------------------------------------------------------------------

- (IBAction)setOpacity:(id)sender
{
    // set the opacity of the movie layer
    mMovieLayer.opacity = [sender floatValue];
}

//--------------------------------------------------------------------------------------------------

- (IBAction)toggleBackgroundFilter:(id)sender
{
    if ([sender state] == NSOnState)
    {
        CIFilter    *effect;
        
        // create effect filter
        effect = [CIFilter filterWithName:@"CIKaleidoscope"];
        
        // make sure all paramters are set to something reasonable
        [effect setDefaults];
        // set the center of the effect to be the center of the layer 
        [effect setValue:[CIVector vectorWithX:mMovieLayer.bounds.size.width * 0.5 Y:mMovieLayer.bounds.size.height * 0.5] forKey:kCIInputCenterKey];	       
        
        // set the effect on the layer
        [mMovieLayer setFilters:[NSArray arrayWithObject:effect]];
    } 
    else 
    {
        // remove the effect
        [mMovieLayer setFilters:nil];
    }

}

//--------------------------------------------------------------------------------------------------

- (IBAction)toggleForegroundFilter:(id)sender
{
    if ([sender state] == NSOnState)
    {
        CIFilter    *effect;
        
        // create effect filter
        effect = [CIFilter filterWithName:@"CIBloom"];
        // make sure all paramters are set to something reasonable
        [effect setDefaults];
        
        // set the effect on the layer
        [mContainer setFilters:[NSArray arrayWithObject:effect]];
    } 
    else 
    {
        // remove the effect
        [mContainer setFilters:nil];
    }
}

//--------------------------------------------------------------------------------------------------

- (IBAction)toggleFrequenceyLevels:(id)sender
{
    [mLevels toggleFreqLevels:[sender state]];
}

//--------------------------------------------------------------------------------------------------
#pragma mark Application delegate
//--------------------------------------------------------------------------------------------------

// quit when window is closed
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


@end
