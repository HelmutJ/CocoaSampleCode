/*
     File: AVSEDocument.m
 Abstract: The players document class. It sets up the AVPlayer, AVPlayerLayer, manages adjusting the playback rate, enables and disables UI elements as appropriate, sets up a time observer for updating the current time (which the UI's time slider is bound to), and handles the AVMutableComposition, AVMutableVideoComposition, AVMutableAudioMix items across different edits.
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


#import "AVSEDocument.h"
#import "AVSECommand.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreMedia/CoreMedia.h>

static void *AVSEPlayerItemStatusContext = &AVSEPlayerItemStatusContext;
static void *AVSEPlayerRateContext = &AVSEPlayerRateContext;
static void *AVSEPlayerLayerReadyForDisplay = &AVSEPlayerLayerReadyForDisplay;

#define kTrimTag            0
#define kRotateTag          1
#define kCropTag            2
#define kAddMusicTag        3
#define kAddWatermarkTag    4
#define kExportTag          5

@interface AVSEDocument ()

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys;
- (void)stopLoadingAnimationAndHandleError:(NSError *)error;

@end

@implementation AVSEDocument

@synthesize player;
@synthesize playerLayer;
@synthesize playerView;

@synthesize composition;
@synthesize videoComposition;
@synthesize audioMix;
@synthesize watermarkLayer;
@synthesize inputAsset;
@synthesize myWindowController;
@synthesize toolbarItemState;
@synthesize timeObserverToken;
@synthesize timeSlider;
@synthesize timeElapsed;
@synthesize unplayableLabel;
@synthesize noVideoLabel;
@synthesize loadingSpinner;
@synthesize progressBar;

@synthesize playPauseButton;
@synthesize exportToMovie;

#pragma mark - Document Controls

- (NSString *)windowNibName
{
    return @"AVSEDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController
{
	[super windowControllerDidLoadNib:windowController];
	[[windowController window] setMovableByWindowBackground:YES];
    myWindowController = windowController;
	[[[self playerView] layer] setBackgroundColor:CGColorGetConstantColor(kCGColorBlack)];
	[[self loadingSpinner] startAnimation:self];
    [[self progressBar] setHidden:YES];
    
    toolbarItemState = [[NSMutableArray alloc] initWithCapacity:6];
    [self resetToolBar];
    
	// Create AVPlayer, add rate and status observers
	[self setPlayer:[[AVPlayer alloc] init]];
	[self addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew context:AVSEPlayerRateContext];
	[self addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVSEPlayerItemStatusContext];
	
	// Create an asset with fileURL, asynchronously load its tracks, its duration, and whether it's playable or protected.
    AVURLAsset *asset = [AVAsset assetWithURL:[self fileURL]];
	NSArray *assetKeysToLoadAndTest = [NSArray arrayWithObjects:@"playable", @"hasProtectedContent", @"tracks", @"duration", nil];
	[asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest completionHandler:^(void) {
		// The asset invokes its completion handler on an arbitrary queue when loading is complete.
		dispatch_async(dispatch_get_main_queue(), ^(void) {
			[self setUpPlaybackOfAsset:asset withKeys:assetKeysToLoadAndTest];
		});
	}];
  
    inputAsset = asset;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(reloadNotificationReceiver:) 
                                                 name:AVSEReloadNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(exportNotificationReceiver:)
                                                 name:AVSEExportNotification
                                               object:nil];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
    }
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return YES;
}

#pragma mark - Playback

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys
{
	// This method is called when AVAsset has completed loading the specified array of keys.
	// playback of the asset is set up here.
	
	// Check whether the values of each of the keys we need has been successfully loaded.
	for (NSString *key in keys)
	{
		NSError *error = nil;
		
		if ([asset statusOfValueForKey:key error:&error] == AVKeyValueStatusFailed)
		{
			[self stopLoadingAnimationAndHandleError:error];
			return;
		}
	}
	
	if (![asset isPlayable] || [asset hasProtectedContent])
	{
		// Asset cannot be played. Display the "Unplayable Asset" label.
		[self stopLoadingAnimationAndHandleError:nil];
		[[self unplayableLabel] setHidden:NO];
		return;
	}
	
	// Set up an AVPlayerLayer 
	if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0)
	{
		// Create an AVPlayerLayer and add it to the player view if there is video, but hide it until it's ready for display
		AVPlayerLayer *newPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
		[newPlayerLayer setFrame:[[[self playerView] layer] bounds]];
		[newPlayerLayer setAutoresizingMask:kCALayerWidthSizable | kCALayerHeightSizable];
		[newPlayerLayer setHidden:YES];
		[[[self playerView] layer] addSublayer:newPlayerLayer];
		[self setPlayerLayer:newPlayerLayer];
		[self addObserver:self forKeyPath:@"playerLayer.readyForDisplay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AVSEPlayerLayerReadyForDisplay];
	}
	else
	{
		// This asset has no video tracks. Show the "No Video" label.
		[self stopLoadingAnimationAndHandleError:nil];
		[[self noVideoLabel] setHidden:NO];
	}
	
	// Create a new AVPlayerItem and make it the player's current item.
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:asset];
	[[self player] replaceCurrentItemWithPlayerItem:playerItem];

    // Use custom queue to prevent flooding the main_queue
    dispatch_queue_t timeObserverQueue1 = dispatch_queue_create("Time Observation Queue1", NULL);
	[self setTimeObserverToken:[[self player] addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:timeObserverQueue1 usingBlock:^(CMTime time) {
		[[self timeSlider] setDoubleValue:CMTimeGetSeconds(time)];
        //set elapsed time
        UInt64 currentTimeSec = time.value / time.timescale;
        UInt64 minutes = currentTimeSec / 60;
        UInt64 seconds = currentTimeSec % 60;
        NSString *playbackTimeLabel = [NSString stringWithFormat:
                                  @"%02lld:%02lld", minutes, seconds];
        [[self timeElapsed] setStringValue:playbackTimeLabel];
	}]];
}

- (void)stopLoadingAnimationAndHandleError:(NSError *)error
{
	[[self loadingSpinner] stopAnimation:self];
	[[self loadingSpinner] setHidden:YES];
	if (error)
	{
		[self presentError:error
			modalForWindow:[self windowForSheet]
				  delegate:nil
		didPresentSelector:NULL
			   contextInfo:nil];
	}
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVSEPlayerItemStatusContext)
	{
		AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
		BOOL enable = NO;
		switch (status)
		{
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
				enable = YES;
				break;
			case AVPlayerItemStatusFailed:
				[self stopLoadingAnimationAndHandleError:[[[self player] currentItem] error]];
                break;
		}
		
		[[self playPauseButton] setEnabled:enable];
    }
	else if (context == AVSEPlayerRateContext)
	{
		float rate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
		if (rate != 1.f)
		{
			[[self playPauseButton] setTitle:@"Play"];
		}
		else
		{
			[[self playPauseButton] setTitle:@"Pause"];
		}
	}
	else if (context == AVSEPlayerLayerReadyForDisplay)
	{
		if ([[change objectForKey:NSKeyValueChangeNewKey] boolValue] == YES)
		{
			// The AVPlayerLayer is ready for display. Hide the loading spinner and show the video.
			[self stopLoadingAnimationAndHandleError:nil];
			[[self playerLayer] setHidden:NO];
		}
	}
	else
	{
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

+ (NSSet *)keyPathsForValuesAffectingDuration
{
	return [NSSet setWithObjects:@"player.currentItem", @"player.currentItem.status", nil];
}

- (double)duration
{
	AVPlayerItem *playerItem = [[self player] currentItem];
	
	if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
		return CMTimeGetSeconds([[playerItem asset] duration]);
	else
		return 0.f;
}

- (double)currentTime
{
	return CMTimeGetSeconds([[self player] currentTime]);
}

- (void)setCurrentTime:(double)time
{
	[[self player] seekToTime:CMTimeMakeWithSeconds(time, 1)];
}


- (IBAction)playPauseToggle:(id)sender
{
	if ([[self player] rate] != 1.f)
	{
		if ([self currentTime] == [self duration])
			[self setCurrentTime:0.f];
		[[self player] play];
	}
	else
	{
		[[self player] pause];
	}
}

- (void)reloadPlayerView
{
    // This method is called every time a tool has been applied to a composition
    // It reloads the player view with the updated composition
    // Create a new AVPlayerItem and make it our player's current item.
    // Pause the player till the playerview is reloaded with the new playerItem
    [[self player] pause];
    self.videoComposition.animationTool = NULL;
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:composition];
    if ([[self noVideoLabel] isHidden]) {
        playerItem.videoComposition = videoComposition;
        playerItem.audioMix = audioMix;
    }
    if(watermarkLayer){
        NSWindowController *windowController = myWindowController;
        NSRect windowDimensions = [[windowController window] frame];
        watermarkLayer.position = CGPointMake(windowDimensions.size.width/2, windowDimensions.size.height/4);
        [[[self playerView] layer] addSublayer:watermarkLayer];
    }
    [[self player] replaceCurrentItemWithPlayerItem:playerItem];
   
    // Resize window to adjust for rotation 
	if(newSize.width != 0){
        NSWindowController *windowController = myWindowController;
        NSRect oldFrame = [[windowController window] frame];
        oldFrame.size.width = newSize.width;
        oldFrame.size.height = newSize.height;
        [[windowController window] setFrame:oldFrame display:YES animate:NO];
    }
    
    if(self.timeObserverToken != NULL){
        [[self player] removeTimeObserver:[self timeObserverToken]];
    }
	[self setTimeObserverToken:[[self player] addPeriodicTimeObserverForInterval:CMTimeMake(1, 10) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
		[[self timeSlider] setDoubleValue:CMTimeGetSeconds(time)];
        
        UInt64 currentTimeSec = time.value / time.timescale;
        UInt64 minutes = currentTimeSec / 60;
        UInt64 seconds = currentTimeSec % 60;
        NSString *playbackTimeLabel = [NSString stringWithFormat:
                                       @"%02lld:%02lld", minutes, seconds];
        [[self timeElapsed] setStringValue:playbackTimeLabel];
	}]];
    
    [[self player] play];
    // Enable export button 
    [toolbarItemState replaceObjectAtIndex:kExportTag withObject:[NSNumber numberWithInt:1]];
}

#pragma mark - Utilities

- (void)close
{
	[[self player] pause];
	[[self player] removeTimeObserver:[self timeObserverToken]];
	[self setTimeObserverToken:nil];
	[self removeObserver:self forKeyPath:@"player.rate"];
	[self removeObserver:self forKeyPath:@"player.currentItem.status"];
	if ([self playerLayer])
		[self removeObserver:self forKeyPath:@"playerLayer.readyForDisplay"];
    self.composition = NULL;
    self.videoComposition = NULL;
    self.audioMix = NULL;
	[super close];
}

- (CALayer*)copyWatermarkLayer:(CALayer*)inputLayer
{
    CALayer *_watermarkLayer = [CALayer layer];
    CATextLayer *titleLayer = [CATextLayer layer];
    CATextLayer *inputTextLayer = [[inputLayer sublayers] objectAtIndex:0];
    titleLayer.string = inputTextLayer.string;
    titleLayer.foregroundColor = inputTextLayer.foregroundColor;
	titleLayer.font = inputTextLayer.font;
	titleLayer.shadowOpacity = inputTextLayer.shadowOpacity;
	titleLayer.alignmentMode = inputTextLayer.alignmentMode;
	titleLayer.bounds = inputTextLayer.bounds;
    
    [_watermarkLayer addSublayer:titleLayer];
    return _watermarkLayer;
}

- (void)exportWillBegin
{
    // Hide play until the export is complete
    [[self playPauseButton] setEnabled:NO]; 
    [[self progressBar] setHidden:NO];
    [[self progressBar] startAnimation:self];
    
    // If Add watermark has been applied to the composition, create a video composition animation tool for export
    if(watermarkLayer){
        CALayer *_watermarkLayer = [self copyWatermarkLayer:watermarkLayer];
        CALayer *parentLayer = [CALayer layer];
        CALayer *videoLayer = [CALayer layer];
        parentLayer.frame = CGRectMake(0, 0, videoComposition.renderSize.width, videoComposition.renderSize.height);
        videoLayer.frame = CGRectMake(0, 0, videoComposition.renderSize.width, videoComposition.renderSize.height);
        [parentLayer addSublayer:videoLayer];
        _watermarkLayer.position = CGPointMake(videoComposition.renderSize.width/2, videoComposition.renderSize.height/4);
        [parentLayer addSublayer:_watermarkLayer];
         self.videoComposition.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    }
}

- (void)exportDidEnd
{
    // Update UI after export is completed
    [[self progressBar] stopAnimation:self];
    [[self progressBar] setHidden:YES];
    // Enable play button
    [[self playPauseButton] setEnabled:YES];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)toolbarItem
{
    // validateToolbarItem: method is implemented to allow a toolbar item to be disabled in certain situations
    // Return NO to disable button to indicate the operation has been applied
    BOOL enable = YES;
    
    if([[toolbarItemState objectAtIndex:[toolbarItem tag]] intValue] == 0)
        // Keep Export disabled when document is not edited
        enable = NO; 
    return enable;
}

- (void)resetToolBar
{
    // Initial state of toolbar items, except export all other tools are set
    // Export is set only when an edit tool has been applied 
    // toolbarItemState: maintains the state (enabled/disabled) of each tool
    [toolbarItemState insertObject:[NSNumber numberWithInt:1] atIndex:kTrimTag];
    [toolbarItemState insertObject:[NSNumber numberWithInt:1] atIndex:kRotateTag];
    [toolbarItemState insertObject:[NSNumber numberWithInt:1] atIndex:kCropTag];
    [toolbarItemState insertObject:[NSNumber numberWithInt:1] atIndex:kAddMusicTag];
    [toolbarItemState insertObject:[NSNumber numberWithInt:1] atIndex:kAddWatermarkTag];
    [toolbarItemState insertObject:[NSNumber numberWithInt:0] atIndex:kExportTag];
}

- (void)reloadNotificationReceiver:(NSNotification*) notification
{
    if ([[notification object] currentDocument] == self) {
        if ([[notification name] isEqualToString:AVSEReloadNotification]){
            // Update the document's composition, video composition etc 
            self.composition = [[notification object] mutableComposition];
            self.videoComposition = [[notification object] mutableVideoComposition]; 
            self.audioMix = [[notification object] mutableAudioMix];
            if([[notification object] watermarkLayer])
                self.watermarkLayer = [[notification object] watermarkLayer];
            newSize.width = [[notification object] newWindowWidth];
            newSize.height = [[notification object] newWindowHeight];
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self reloadPlayerView];
            });
        }
    }
}

- (void)exportNotificationReceiver:(NSNotification *)notification
{
    if ([[notification object] currentDocument] == self) {
        if ([[notification name] isEqualToString:AVSEExportNotification]){
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self exportDidEnd];
            });
        }
    }
}

#pragma mark - Editing Tools

- (IBAction)performCommand:(id)sender
{
    // Disable the tool clicked
    [toolbarItemState replaceObjectAtIndex:[sender tag] withObject:[NSNumber numberWithInt:0]];
    
    NSInteger inputTag = [sender tag];
    AVSECommand *obj;
    
    switch (inputTag) {
        case kTrimTag:{
            obj = [[AVSETrimCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix ofDocument:self];
            break;
        }
        case kRotateTag:{
            obj = [[AVSERotateCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix ofDocument:self];
            break;
        }
        case kCropTag:{
            obj = [[AVSECropCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix ofDocument:self];
            break;
        }
        case kAddMusicTag:{
            obj = [[AVSEAddMusicCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix ofDocument:self];
            break;
        }
        case kAddWatermarkTag:{
            obj = [[AVSEAddWatermarkCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix ofDocument:self];
            break;
        }
        default:
            break;
    }
    
    [obj performWithAsset:inputAsset];
}

- (IBAction)performExport:(id)sender
{
    [self exportWillBegin];
    AVSEExportCommand *obj = [[AVSEExportCommand alloc] initWithComposition:self.composition videoComposition:self.videoComposition audioMix:self.audioMix ofDocument:self];
    [obj performWithAsset:nil];
}

@end