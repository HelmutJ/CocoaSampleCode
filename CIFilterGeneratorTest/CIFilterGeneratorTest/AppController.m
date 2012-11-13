
/*
     File: AppController.m
 Abstract: Code for creating, saving and loading a CIFilterGenerator.
 Here we export the three action to be hooked up in the nib.
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import <Quartz/Quartz.h>
#import "AppController.h"


@interface AppController ()
{
	CIFilterGenerator	*generator;
	CIFilter			*generatedFilter;
	CIImage				*image;
}

@property (nonatomic, weak) IBOutlet SampleCIView *testView;
@property (nonatomic, strong) IBOutlet NSPanel *filterPanel;

@end


NSString *ImageFileName = @"WWDC06Logo";
NSString *ImageFileExtension = @"tiff";



@implementation AppController

//--------------------------------------------------------------------------------------------------

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	// draw the result of the filter into the view
	[self.testView setImage:[generatedFilter valueForKey:kCIOutputImageKey]];
}

//--------------------------------------------------------------------------------------------------

- (void)awakeFromNib
{
	// Make sure we have all Image Units available.
	[CIPlugIn loadAllPlugIns];	
	
	// Read the default image.
    NSURL *imageURL = [[NSBundle mainBundle] URLForResource:ImageFileName withExtension:ImageFileExtension];
    
	image = [CIImage imageWithContentsOfURL:imageURL];
	[self createFilterGenerator:nil];
}

//--------------------------------------------------------------------------------------------------

- (IBAction)createFilterGenerator:(id)sender
{
	// remove old view from the filter UI and remove observer from the old filter
	[self.filterPanel setContentView:nil];
	[generatedFilter removeObserver:self forKeyPath:@"outputImage"];
	generatedFilter = nil;
		
	generator = [CIFilterGenerator filterGenerator];
	CIFilter	*filter = [CIFilter filterWithName:@"CIComicEffect"];
	[filter setDefaults];
	CIFilter	*compositeFilter = [CIFilter filterWithName:@"CICopyMachineTransition"];
	[compositeFilter setDefaults];
	[compositeFilter setValue:@0.5 forKey:kCIInputTimeKey];
    
	// Connect the filters into the filter generator.
	[generator connectObject:filter withKey:kCIOutputImageKey toObject:compositeFilter withKey:kCIInputImageKey];
	[generator connectObject:nil withKey:kCIOutputImageKey toObject:[compositeFilter copy] withKey:kCIInputImageKey];

	// Export the time key of the transition, so the user can set it.
	[generator exportKey:kCIInputTimeKey fromObject:compositeFilter withName:kCIInputTimeKey];
	// Export both images of the transition to the same exported key.
	[generator exportKey:kCIInputImageKey fromObject:filter withName:kCIInputImageKey];
	[generator exportKey:kCIInputTargetImageKey fromObject:compositeFilter withName:kCIInputImageKey];
	// Export the output image.
	[generator exportKey:kCIOutputImageKey fromObject:compositeFilter withName:nil];
	
	// Set the class attributes for the filter.
	NSMutableDictionary	*theClassAttributes = [[NSMutableDictionary alloc] init];	
	[theClassAttributes setObject:@"Sample CIFilterGenerator" forKey:kCIAttributeFilterDisplayName];
    [theClassAttributes setObject:@"A sample filter generator that wraps around a transition from a source image to a stylized version of the image" forKey:kCIAttributeDescription];
    [theClassAttributes setObject:[NSArray arrayWithObjects:kCICategoryStylize, kCICategoryStillImage, kCICategoryVideo, nil] forKey:kCIAttributeFilterCategories];
    [generator setClassAttributes:theClassAttributes];
		
	generatedFilter = [generator filter];
	[generatedFilter setValue:image forKey:kCIInputImageKey];
	[generatedFilter addObserver:self forKeyPath:@"outputImage" options:NSKeyValueObservingOptionNew context:nil];	
	[self.testView setImage:[generatedFilter valueForKey:kCIOutputImageKey]];
	
    // Create some UI for the filter.
	IKFilterUIView	*filterContentView = [generatedFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey]];
    [self.filterPanel setContentSize:filterContentView.bounds.size];
	[self.filterPanel setContentView:filterContentView];
}

//--------------------------------------------------------------------------------------------------

- (IBAction)saveGenerator:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setNameFieldStringValue:@"MyGenerator"];

    NSInteger rv = [savePanel runModal];
    if (rv == NSFileHandlingPanelOKButton)
	{
		// Just write out the generator
		if(![generator writeToURL:[savePanel URL] atomically:YES]) {
			NSLog(@"failed to write out generator");
        }
	}
}

//--------------------------------------------------------------------------------------------------

- (IBAction)loadGenerator:(id)sender
{
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setResolvesAliases:YES];
    [openPanel setCanChooseFiles:YES];
    
    NSInteger rv = [openPanel runModal];
    if (rv == NSFileHandlingPanelOKButton) {
        
		// Remove old view from the filter UI and remove observer from the old filter.
		[self.filterPanel setContentView:nil];
		[generatedFilter removeObserver:self forKeyPath:@"outputImage"];
        generatedFilter = nil;
        generator = nil;

		// Load the generator.
		generator = [CIFilterGenerator filterGeneratorWithContentsOfURL:[openPanel URL]];
		// Create a filter from the generator.
		generatedFilter = [generator filter];
                                                
		// Set the default input image.
		[generatedFilter setValue:image forKey:kCIInputImageKey];
		
		// Register for KVO on the output image so that when the parameters of the filter change we draw again.
		[generatedFilter addObserver:self forKeyPath:@"outputImage" options:NSKeyValueObservingOptionNew context:nil];	
		// For the first time, draw the result of the filter into the view.
		[self.testView setImage:[generatedFilter valueForKey:kCIOutputImageKey]];
		// Create some UI for the filter.
		IKFilterUIView	*filterContentView = [generatedFilter viewForUIConfiguration:@{IKUISizeFlavor:IKUISizeMini} excludedKeys:@[kCIInputImageKey]];
		// ... and install the filter UI into the panel
        [self.filterPanel setContentSize:filterContentView.bounds.size];
		[self.filterPanel setContentView:filterContentView];
	}
}

//--------------------------------------------------------------------------------------------------

@end
