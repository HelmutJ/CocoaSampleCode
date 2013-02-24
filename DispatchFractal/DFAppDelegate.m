//
// File:       DFAppDelegate.m
//
// Abstract:   This example shows how to combine parallel computation on the CPU
//             via GCD with results processing and display on the GPU via OpenCL
//             and OpenGL. It computes escape-time fractals in parallel on the
//             global concurrent GCD queue and uses another GCD queue to upload
//             results to the GPU for processing via two OpenCL kernels. Calls to
//             OpenCL and OpenGL for display are serialized with a third GCD queue.
//
// Version:    <1.0>
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//  Copyright 2009 Apple Inc. All rights reserved.
//

#import "DFAppDelegate.h"
#import <Quartz/Quartz.h>

extern fractal_compute_t mandelbrot;

#pragma mark DFAppDelegate

@implementation DFAppDelegate

@synthesize window, view, dataController, observedKeys;

enum {IDX_subdivisions = 0, IDX_fractal};

- (void)applicationWillFinishLaunching:(NSNotification *)aNotification {
    self.observedKeys = [NSArray arrayWithObjects:@"subdivisions", @"fractal",
	    nil];
    for (NSString *k in self.observedKeys) {
	[self.dataController addObserver:self forKeyPath:[@"selection."
		stringByAppendingString:k] options:NSKeyValueObservingOptionNew
		context:NULL];
    }
    for (NSString *k in self.view.observedKeys) {
	[self.dataController addObserver:self.view forKeyPath:[@"selection."
		stringByAppendingString:k] options:NSKeyValueObservingOptionNew
		context:NULL];
    }
    [[self.dataController selection] setValuesForKeysWithDictionary:
	    [NSDictionary dictionaryWithObjectsAndKeys:
	    [NSNumber numberWithDouble:0	    ], @"gflops",
	    [NSNumber numberWithDouble:0	    ], @"fps",
	    [NSNumber numberWithDouble:0	    ], @"elapsed",
	    [NSNumber numberWithUnsignedLong:0	    ], @"computedone",
	    [NSNumber numberWithUnsignedLong:0	    ], @"computequeued",
	    [NSNumber numberWithUnsignedInt:0	    ], @"fractal",
	    [NSNumber numberWithBool:YES	    ], @"computeqconcurrent",
	    [NSNumber numberWithUnsignedLong:10	    ], @"subdivisions",
	    [NSNumber numberWithUnsignedLong:4	    ], @"stride",
	    [NSNumber numberWithBool:YES	    ], @"enabledisplay",
	    [NSNumber numberWithBool:YES	    ], @"cyclecolors",
	    [NSNumber numberWithDouble: 0.1	    ], @"cyclespeed",
	    @""					     , @"opencldevice",
	    [NSNumber numberWithBool:NO		    ], @"vsync",
	    [NSNumber numberWithBool:YES	    ], @"displaylink",
	    [NSNumber numberWithBool:NO		    ], @"openglmp",
	    [NSColor yellowColor		    ], @"col0",
	    [NSColor blueColor			    ], @"col1",
	    [NSColor orangeColor		    ], @"col2",
	    [NSColor colorWithCalibratedRed:0 green:.7 blue:1 alpha:1], @"col3",
	    [NSColor blackColor			    ], @"col4",
	    [NSNumber numberWithBool:NO		    ], @"running",
	    [NSNumber numberWithBool:NO		    ], @"stopping",
	    [NSNumber numberWithBool:NO		    ], @"displayoff",
	    nil]];
    fractal = fractalNew();
}

- (void)dealloc {
    [dataController removeObserver:self forKeyPath:@"selection.subdivisions"];
    for (NSString *k in view.observedKeys) {
	[dataController removeObserver:view forKeyPath:[@"selection."
		stringByAppendingString:k]];
    }
    [view release];
    [window release];
    [dataController release];
    fractalFree(fractal);
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self start:self];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication*)sender {
    return YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
	change:(NSDictionary *)change context:(void *)context {
    if ([object isEqual:self.dataController] &&
	    [keyPath hasPrefix:@"selection."]) {
	id d = [object selection];
	NSString *k = [keyPath substringFromIndex:10];
	switch ([self.observedKeys indexOfObject:k]) {
	case IDX_subdivisions: {
	    const unsigned long s = [[d valueForKey:k] unsignedLongValue];
	    const unsigned long stride = [[d valueForKey:@"stride"]
		    unsignedLongValue];
	    if (stride > s + 1) {
		[d setValue:[NSNumber numberWithUnsignedLong:s + 1]
			forKey:@"stride"];
	    }
	    break;
	}
	case IDX_fractal: {
	    const unsigned int f = [[d valueForKey:k] unsignedIntValue];
	    [d setValuesForKeysWithDictionary:
		    [NSDictionary dictionaryWithObjectsAndKeys:
		    [NSNumber numberWithDouble:
			    fractalInitialParams[f].centerX], @"x",
		    [NSNumber numberWithDouble:
			    fractalInitialParams[f].centerY], @"y",
		    [NSNumber numberWithDouble:
			    fractalInitialParams[f].width], @"w",
		    [NSNumber numberWithUnsignedLong:
			    fractalInitialParams[f].maxiterations],
			    @"maxiterations",
		    [NSNumber numberWithUnsignedInt:
			    fractalInitialParams[f].colorroot], @"colorroot",
		    nil]];
	    if (fractal) [self start:self];
	    break;
	}
	case NSNotFound:
	default:
	    break;
	}
    }
}

- (IBAction)start:(id)sender {
    id d = [self.dataController selection];
    if (![[d valueForKey:@"stopping"] boolValue]) {
	NSWindow *win = self.window;
	if(![win makeFirstResponder:win]) {
	    [win endEditingFor:nil];
	}
	const real x = [[d valueForKey:@"x"] doubleValue];
	const real y = [[d valueForKey:@"y"] doubleValue];
	const real w = [[d valueForKey:@"w"] doubleValue];
	const unsigned long m = [[d valueForKey:@"maxiterations"]
		unsignedLongValue];
	const unsigned int f = [[d valueForKey:@"fractal"] unsignedIntValue];
	const BOOL enabledisplay = [[d valueForKey:@"enabledisplay"]
		boolValue];
	const BOOL concurrent = [[d valueForKey:@"computeqconcurrent"]
		boolValue];
	const unsigned long subdivisions = [[d valueForKey:@"subdivisions"]
		unsignedLongValue];
	const unsigned long stride = [[d valueForKey:@"stride"]
		unsignedLongValue];
	[d setValue:[NSNumber numberWithBool:YES] forKey:@"running"];
	if (!enabledisplay) {
	    [d setValue:[NSNumber numberWithBool:YES] forKey:@"displayoff"];
	}
	fractalStart(fractal, ^{
	    const fractal_params_t params = {
		.centerX		= x,
		.centerY		= y,
		.width			= w,
		.maxiterations		= m,
		.subdivisions		= subdivisions,
		.stride			= stride,
		.computeqconcurrent	= concurrent,
		.enabledisplay		= enabledisplay,
		.collectstats		= YES,
		.displaystats		= YES,
	    };
	    return params;
	}, fractalCompute[f], ^(fractal_out_t * const quadtree,
		const natural size) {
	    if (enabledisplay) {
		[self.view startQuadtreeProcessing:quadtree size:size];
	    }
	}, ^(const nanoseconds elapsed) {
	    if (enabledisplay) {
		[self.view stopQuadtreeProcessing];
	    }
	    [d setValue:[NSNumber numberWithDouble:(double)elapsed/NSEC_PER_SEC]
		    forKey:@"elapsed"];
	    [d setValue:[NSNumber numberWithBool:NO] forKey:@"running"];
	    [d setValue:[NSNumber numberWithBool:NO] forKey:@"stopping"];
	    [d setValue:[NSNumber numberWithBool:NO] forKey:@"displayoff"];
	}, ^(const counter computedone, const counter computequeued,
		const counter computemax, const counter flops,
		const nanoseconds elapsed) {
	    [d setValue:[NSNumber numberWithUnsignedLong:computemax]
		    forKey:@"computemax"];
	    [d setValue:[NSNumber numberWithUnsignedLong:computedone]
		    forKey:@"computedone"];
	    [d setValue:[NSNumber numberWithUnsignedLong:computequeued]
		    forKey:@"computequeued"];
	    [d setValue:[NSNumber numberWithDouble:(double)flops/elapsed]
		    forKey:@"gflops"];
	    [d setValue:[NSNumber numberWithDouble:(double)elapsed/NSEC_PER_SEC]
		    forKey:@"elapsed"];
	});
    }
}

- (IBAction)stop:(id)sender {
    id d = [self.dataController selection];
    if ([[d valueForKey:@"running"] boolValue]) {
	fractalStop(fractal);
	[d setValue:[NSNumber numberWithBool:YES] forKey:@"stopping"];
    }
}

- (IBAction)zoomIn:(id)sender {
    NSRect bounds = [self.view bounds];
    [self zoomInAtPoint:NSMakePoint(NSMidX(bounds), NSMidY(bounds))];
}

- (IBAction)zoomOut:(id)sender {
    NSRect bounds = [self.view bounds];
    [self zoomOutAtPoint:NSMakePoint(NSMidX(bounds), NSMidY(bounds))];
}

- (void)zoomToPoint:(NSPoint)center factor:(CGFloat)factor {
    id d = [self.dataController selection];
    CGFloat x = [[d valueForKey:@"x"] doubleValue];
    CGFloat y = [[d valueForKey:@"y"] doubleValue];
    CGFloat w = [[d valueForKey:@"w"] doubleValue], wo = w;
    unsigned long m = [[d valueForKey:@"maxiterations"] unsignedLongValue];
    const NSSize size = [self.view bounds].size;
    x += w * (center.x - size.width  / 2) / size.width;
    y += w * (center.y - size.height / 2) / size.height;
    w *= factor; if (w > 100) { w = 100; } else if (w < 5e-17) { w = 5e-17; }
    m *= pow(w/wo, -.2); if (m < 200) { m = 200; }
    [d setValue:[NSNumber numberWithDouble:x] forKey:@"x"];
    [d setValue:[NSNumber numberWithDouble:y] forKey:@"y"];
    [d setValue:[NSNumber numberWithDouble:w] forKey:@"w"];
    [d setValue:[NSNumber numberWithUnsignedLong:m] forKey:@"maxiterations"];
}

- (void)zoomToRect:(NSRect)frame {
    NSSize size = [self.view bounds].size;
    [self zoomToPoint:NSMakePoint(NSMidX(frame), NSMidY(frame)) factor:
	    fmax(frame.size.width / size.width,
	    frame.size.height / size.height)];
    [self start:self];
}

- (void)zoomInAtPoint:(NSPoint)center {
    [self zoomToPoint:center factor:.5];
    [self start:self];
}

- (void)zoomOutAtPoint:(NSPoint)center {
    [self zoomToPoint:center factor:2];
    [self start:self];
}

- (void)centerAtPoint:(NSPoint)center {
    [self zoomToPoint:center factor:1];
    [self start:self];
}

- (void)saveDocumentAs:(id)sender {
    CGImageRef image = [view createImage];
    if (image) {
	NSSavePanel *savePanel = [NSSavePanel savePanel];
	IKSaveOptions *saveOptions = [[IKSaveOptions alloc]
		initWithImageProperties:nil imageUTType:(NSString *)kUTTypePNG];
	[saveOptions addSaveOptionsAccessoryViewToSavePanel:savePanel];
	[savePanel beginSheetModalForWindow:self.window
		completionHandler:^(NSInteger result) {
	    if (result == NSOKButton) {
		CGImageDestinationRef dest = CGImageDestinationCreateWithURL(
			(CFURLRef)[savePanel URL],
			(CFStringRef)[saveOptions imageUTType], 1, NULL);
		if (dest) {
		    NSDictionary *properties  = [[saveOptions imageProperties]
			    retain];
		    CFRetain(image);
		    dispatch_async(dispatch_get_global_queue(
			    DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			CGImageDestinationAddImage(dest, image,
				(CFDictionaryRef)properties);
			CGImageDestinationFinalize(dest);
			CFRelease(dest);
			CFRelease(image);
			[properties release];
		    });
		}
	    }
	    CFRelease(image);
	}];
	[saveOptions release];
    }
}

@end

#pragma mark DFWindowDelegate

@implementation DFWindowDelegate

- (void)showHelp:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle]
	    pathForResource:@"ReadMe" ofType:@"txt"]
	    withApplication:@"TextEdit" andDeactivate:YES];
}

@end

#pragma mark DFData

@implementation DFData

+ (BOOL)accessInstanceVariablesDirectly { return NO; }

- (id)init {
    self = [super init];
    if (self) {
	_data = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)dealloc {
    [_data release];
    [super dealloc];
}

- (id)valueForKey:(NSString *)key { return [_data valueForKey:key]; }

- (void)setValue:(id)value forKey:(NSString *)key {
    [_data setValue:value forKey:key];
}

- (BOOL)validateStride:(id *)ioValue error:(NSError **)outError {
    if (*ioValue) {
	const unsigned long stride = [*ioValue unsignedLongValue];
	const unsigned long s = [[_data valueForKey:@"subdivisions"]
		unsignedLongValue];
	if (stride > s + 1) {
	    *ioValue = [NSNumber numberWithUnsignedLong:s + 1];
	}
    }
    return YES;
}

@end

#pragma mark DFStartActionValueTransformer

@implementation DFStartActionValueTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    return [value boolValue] ?
	NSLocalizedString(@"Restart", @"Button title to restart processing") : 
	NSLocalizedString(@"Start",   @"Button title to start processing");
}

@end

#pragma mark DFValueStringValueTransformer

@implementation DFValueStringValueTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value { return [value stringValue]; }

@end

#pragma mark DFBlocksValueTransformer

@implementation DFBlocksValueTransformer

+ (Class)transformedValueClass { return [NSString class]; }

+ (BOOL)allowsReverseTransformation { return NO; }

- (id)transformedValue:(id)value {
    return [[value stringValue] stringByAppendingString:@" Blocks"];
}

@end
