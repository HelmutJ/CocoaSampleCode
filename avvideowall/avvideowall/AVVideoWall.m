/*
     File: AVVideoWall.m
 Abstract: The AVVideoWall class, builds a video wall of live capture devices
  Version: 1.1
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import "AVVideoWall.h"

@interface AVCaptureInput (ConvenienceMethodsCategory)
- (AVCaptureInputPort *)portWithMediaType:(NSString *)mediaType;
@end

@implementation AVCaptureInput (ConvenienceMethodsCategory)

// Find the input port with the target media type
- (AVCaptureInputPort *)portWithMediaType:(NSString *)mediaType
{
	for (AVCaptureInputPort *p in [self ports]) {
		if ([[p mediaType] isEqualToString:mediaType])
			return p;
	}
	return nil;
}

@end

@implementation AVVideoWall

- (id)init
{
	self = [super init];
	if (self) {
		_videoPreviewLayers = [[NSMutableArray alloc] init];
		_homeLayerRects = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)dealloc
{
	for (AVCaptureVideoPreviewLayer *layer in _videoPreviewLayers)
		[layer setSession:nil];
    
    [_session release];
    [_window release];
    [_videoPreviewLayers release];
    [_homeLayerRects release];
    
    [super dealloc];
}

- (void)createWindowAndRootLayer
{
	// Create a screen-sized window
    CGRect mainDisplayBounds = NSRectToCGRect([[NSScreen mainScreen] frame]);
	NSRect bounds = NSMakeRect(0, 0, mainDisplayBounds.size.width, mainDisplayBounds.size.height);
	_window = [[NSWindow alloc] initWithContentRect:bounds styleMask:NSBorderlessWindowMask
											backing:NSBackingStoreBuffered defer:NO screen:[NSScreen mainScreen]];
	
	// Set the window level to floating
    int windowLevel = NSFloatingWindowLevel;
	[_window setLevel:windowLevel];
	
	// Make the content view layer-backed
	NSView *windowContentView = [_window contentView];
	[windowContentView setWantsLayer:YES];
	
	// Grab the Core Animation layer
	_rootLayer = [windowContentView layer];
	
	// Set its background color to opaque black
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGFloat black[] = {0.0f, 0.0f, 0.0f, 1.0f};
	CGColorRef blackColor = CGColorCreate(colorspace, black);
	_rootLayer.backgroundColor = blackColor;
	CGColorRelease(blackColor);
	CFRelease(colorspace);
	
	// Show the window
	[_window makeKeyAndOrderFront:nil];
}

// Find capture devices that support video and/or muxed media
- (NSMutableArray *)devicesThatCanProduceVideo
{
	NSMutableArray *devices = [NSMutableArray array];
	for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
		if ([device hasMediaType:AVMediaTypeVideo] || [device hasMediaType:AVMediaTypeMuxed])
			[devices addObject:device];
	}
	return devices;
}

// Compute frame for quadrant i of the input rectangle
- (CGRect)rectForQuadrant:(int)i withinRect:(CGRect)rect
{
    CGRect curLayerFrame = rect;
    curLayerFrame.size.width = curLayerFrame.size.width / 2;
    curLayerFrame.size.height = curLayerFrame.size.height / 2;
    
    switch (i) {
        case 0: // top left
            // currentLayerBounds.origin.x/y are unchanged.
            break;
        case 1: // top right
            curLayerFrame.origin.x += curLayerFrame.size.width;
            break;
        case 2: // bottom left
            curLayerFrame.origin.y += curLayerFrame.size.height;
            break;
        case 3: // bottom right
            curLayerFrame.origin.y += curLayerFrame.size.height;
            curLayerFrame.origin.x += curLayerFrame.size.width;
            break;
    }
    
    // Make a 2-pixel border
    curLayerFrame.origin.y += 2;
    curLayerFrame.origin.x += 2;
    curLayerFrame.size.width -= 4;
    curLayerFrame.size.height -= 4;
    
    return curLayerFrame;
}

// Create 4 video preview layers per video device in a mirrored square, and
// set up these squares left to right within the root layer
- (BOOL)setupVideoWall
{
	NSError *error = nil;
	
	// Find video devices
	NSMutableArray *devices = [self devicesThatCanProduceVideo];
	NSInteger devicesCount = [devices count], currentDevice = 0;
	CGRect rootBounds = [_rootLayer bounds];
	if (devicesCount == 0)
		return NO;
	
	// For each video device
	for (AVCaptureDevice *d in devices) {
		// Create a device input with the device and add it to the session
		AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:&error];
		if (error) {
			NSLog(@"deviceInputWithDevice: failed (%@)", error);
            return NO;
        }
		[_session addInputWithNoConnections:input];
		
		// Find the video input port
		AVCaptureInputPort *videoPort = [input portWithMediaType:AVMediaTypeVideo];
		
		// Set up its corresponding square within the root layer
		CGRect deviceSquareBounds = CGRectMake(0, 0, rootBounds.size.width / devicesCount, rootBounds.size.height);
		deviceSquareBounds.origin.x = deviceSquareBounds.size.width * currentDevice;
		
		// Create 4 video preview layers in the square
		for (int i = 0; i < 4; ++i) {
			// Create a video preview layer with the session
			AVCaptureVideoPreviewLayer *videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSessionWithNoConnection:_session];
			
			// Add it to the array
			[_videoPreviewLayers addObject:videoPreviewLayer];
			
			// Create a connection with the input port and the preview layer
			// and add it to the session
			AVCaptureConnection *connection = [AVCaptureConnection connectionWithInputPort:videoPort videoPreviewLayer:videoPreviewLayer];
			[_session addConnection:connection];
			
			// If the preview layer is at top-right (i=1) or bottom-left (i=2),
			// flip it left-right.
			BOOL doMirror = ((i == 1) || (i == 2));
			if ( doMirror ) {
				[connection setAutomaticallyAdjustsVideoMirroring:NO];
				[connection setVideoMirrored:YES];
			}
			
			// Compute the frame for the current layer
            // Each layer fills a quadrant of the square
            CGRect curLayerFrame = [self rectForQuadrant:i withinRect:deviceSquareBounds];
            
			[CATransaction begin];
			// Disable implicit animations for this transaction
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			
			// Set the layer frame
			[videoPreviewLayer setFrame:curLayerFrame];
			
			// Save the frame in an array for the "sendLayersHome" animation
			[_homeLayerRects addObject:[NSValue valueWithRect:NSRectFromCGRect(curLayerFrame)]];
			
			// We want the video content to always fill the entire layer regardless of the layer size,
            // so set video gravity to ResizeAspectFill
			[videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
			
			// If the layer is at top of the square (i=0, 1), make it upside down
			if ( i < 2 )
				[connection setVideoOrientation:AVCaptureVideoOrientationPortraitUpsideDown];
			
			// Add the preview layer to the root layer
			[_rootLayer addSublayer:videoPreviewLayer];
			
			[CATransaction commit];	
		}
		currentDevice++;
	}
	
	return YES;
}

// Spin the video preview layers
- (void)spinLayers
{
	if (_spinningLayers) {
		[CATransaction begin];
		for (AVCaptureVideoPreviewLayer *layer in _videoPreviewLayers) {
			[layer removeAllAnimations];
            // Set the animation duration
			[CATransaction setValue:[NSNumber numberWithFloat:5.0f] forKey:kCATransactionAnimationDuration];
            // Change the layer's position to some random value within the root layer
			layer.position = CGPointMake([_rootLayer bounds].size.width * rand()/(CGFloat)RAND_MAX, 
										 [_rootLayer bounds].size.height * rand()/(CGFloat)RAND_MAX);
            // Scale the layer 
			CGFloat factor = rand()/(CGFloat)RAND_MAX * 2.0f;
			CATransform3D transform = CATransform3DMakeScale(factor, factor, 1.0f);
            // Rotate the layer
			transform = CATransform3DRotate(transform, acos(-1.0f)*rand()/(CGFloat)RAND_MAX, 
											rand()/(CGFloat)RAND_MAX, rand()/(CGFloat)RAND_MAX, rand()/(CGFloat)RAND_MAX);
            // Apply the transform
			layer.transform = transform;
		}
		[CATransaction commit];
		
        // Schedule another animation in 2 seconds
		double delayInSeconds = 2.0;
		dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
		dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
			[self spinLayers];
		});
	}
}

// Reset the video preview layers
- (void)sendLayersHome
{
	NSUInteger curLayerIdx = 0;
	[CATransaction begin];
    for (AVCaptureVideoPreviewLayer *layer in _videoPreviewLayers) {
        // Set the animation duration
		[CATransaction setValue:[NSNumber numberWithFloat:1.0f] forKey:kCATransactionAnimationDuration];
        // Reset the layer's frame to initial values 
		CGRect homeRect = NSRectToCGRect([(NSValue *)[_homeLayerRects objectAtIndex:curLayerIdx] rectValue]);
		[layer setFrame:homeRect];
        // Reset the layer's transform to identity
		[layer setTransform:CATransform3DIdentity];
		curLayerIdx++;
	}
    [CATransaction commit];
}

- (BOOL)configure
{	
    // Create a screen-sized window and Core Animation layer
	[self createWindowAndRootLayer];
	
    // Create a capture session
	_session = [[AVCaptureSession alloc] init];
    // Set the session preset
	[_session setSessionPreset:AVCaptureSessionPreset640x480];
	
    // Create a wall of video out of the video capture devices on your Mac
	BOOL success = [self setupVideoWall];
    return success;
}

@end

