/*
     File: AppController.m
 Abstract: Manages drag-n-drop, updates the layers when the sliders move
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

#import "AppController.h"

@implementation AppController

-(void)awakeFromNib {
	//Load the image and add it to the slice view
	dragImage = YES;
	img = [NSImage imageNamed:@"drag.png"];
	[sliceView setImg:img];
	
	//Set the initial values for the center slice
	[sliceView sliceWithRect:CGRectMake(0.25, 0.25, 0.5, 0.5)];
	
	//Create the root layer
	rootLayer = [CALayer layer];
	
	//Set the root layer's background color to black
	rootLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
	
	
	//Build the 9-slice layer with an initial scale of 1
	imgLayer = [CALayer layer];
	imgLayer.contents = img;
	
	imgLayer.frame = CGRectMake(0, 0, [img size].width, [img size].height);
	imgLayer.contentsCenter = CGRectMake(0.5, 0.5, 1, 1);

	//Build the layer hierarchy and turn on CoreAnimation for the view
	[rootLayer addSublayer:imgLayer];
	[view setLayer:rootLayer];
	[view setWantsLayer:YES];
	
	//Register to receive notifications when a file is dragged into the window
	[[view window] registerForDraggedTypes:[NSArray arrayWithObject:NSURLPboardType]];
}

//Update the layer with the new slider values
-(IBAction)slidersMoved:(id)sender {
	if (dragImage) {
		return;
	}
	//Update the size
	imgLayer.frame = CGRectMake(0, 0, [img size].width + ([imgWidthSlider floatValue] 
									/ 100.0) * (rootLayer.bounds.size.width - [img size].width),
									[img size].height + ([imgHeightSlider floatValue] 
									/ 100.0) * (rootLayer.bounds.size.height - [img size].height));
	
	//Update the dimensions of the center slice
	float cX = [centerXSlider floatValue] / 100.0;
	float cY = [centerYSlider floatValue] / 100.0;
	
	//Construct the center rect making sure that it stays within the unit rect [0 0 1 1]
	CGRect centerSlice = CGRectMake(cX, 
									cY, 
									MIN([centerWidthSlider floatValue] / 100.0, 1-cX), 
									MIN([centerHeightSlider floatValue] / 100.0, 1-cY));	
	imgLayer.contentsCenter = centerSlice;

	//Update the mini 'sliceView' with the new rect
	[sliceView sliceWithRect:centerSlice];
}


//Reset the slider values
-(IBAction)resetSliders:(id)sender {
	[imgWidthSlider setFloatValue:0];
	[imgHeightSlider setFloatValue:0];
	[centerXSlider setFloatValue:25];
	[centerYSlider setFloatValue:25];
	[centerWidthSlider setFloatValue:50];
	[centerHeightSlider setFloatValue:50];
	[sliceView sliceWithRect:CGRectMake(0.25, 0.25, 0.5, 0.5)];
	[self slidersMoved:self];
}

//Inform the pasteboard that we intend to link to the dragged file
//Used to implement the 'drag-n-drop' feature
- (NSDragOperation)draggingEntered:(id < NSDraggingInfo >)sender {
	return NSDragOperationLink;
}

//If the dragged file is a valid image, update the views. Otherwise reject.
//Used to implement the 'drag-n-drop' feature
- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
	NSImage *newImg =  [[NSImage alloc] initWithContentsOfURL:[NSURL URLFromPasteboard:[sender draggingPasteboard]]];
	float h = [newImg size].height;
	float w = [newImg size].width;
	if(h > 0 && w > 0) {
		
		//Resize the window to fit the new image
		CGRect rect = [[view window] frame];
		if (w > imgLayer.frame.size.width) {
			rect.size.width = MAX(w + 209, 721);
		}
		if (h > imgLayer.frame.size.height) {
			rect.size.height = MAX(h + 62, 574);
		}
		[[view window] setFrame:rect display:YES animate:YES];
		
		img = newImg;
		sliceView.img = img;
		[self resetSliders:self];
		[imgLayer setContents:img];
		[imgLayer setFrame:CGRectMake(0, 0, w, h)];
		dragImage = NO;
		return YES;
	} else {
		return NO;
	}
}

//Dont let the window become smaller than the image
-(NSSize)windowWillResize:(NSWindow *)window toSize:(NSSize)proposedFrameSize {
	if (rootLayer.bounds.size.width - imgLayer.frame.size.width <= 0 && proposedFrameSize.width < [window frame].size.width) {
		proposedFrameSize.width = MAX([window frame].size.width, 721);
	} 
	
	if (rootLayer.bounds.size.height - imgLayer.frame.size.height <= 0 && proposedFrameSize.height < [window frame].size.height) {
		proposedFrameSize.height = MAX([window frame].size.height, 574);
	}
	
	return proposedFrameSize;
}

//Adjust the image size sliders to match the new window area
-(void)windowDidResize:(NSNotification*)aNotification {
	[CATransaction setDisableActions:YES];
	if (dragImage) {
		//If the 'drag' placeholder image is being displayed, center it
		imgLayer.position = CGPointMake(rootLayer.bounds.size.width / 2, rootLayer.bounds.size.height / 2); 
	} else {
		[imgWidthSlider setFloatValue:  100 * (1 - (rootLayer.bounds.size.width - imgLayer.frame.size.width)
											   / (rootLayer.bounds.size.width - [img size].width))];
		[imgHeightSlider setFloatValue: 100 * (1 - (rootLayer.bounds.size.height - imgLayer.frame.size.height) 
											   / (rootLayer.bounds.size.height - [img size].height))];
		[self slidersMoved:self];
	}
	[CATransaction setDisableActions:NO];
}

@end
