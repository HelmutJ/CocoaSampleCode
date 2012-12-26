
/*
     File: AppController.m
 Abstract: Application controller object that manages a collection of Position objects containing offset and angle values.
 
  Version: 2.0
 
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

#import "AppController.h"
#import "JoystickView.h"
#import "Position.h"

@interface AppController ()

@property (weak) IBOutlet JoystickView *joystick;
@property (strong) IBOutlet NSArrayController *arrayController;

@property (strong) NSMutableArray *anArray;

@end



@implementation AppController


- (void)awakeFromNib
{
	// Create a dictionary to set the binding option to allow editing of multiple selections.
	NSDictionary *options = @{ NSAllowsEditingMultipleValuesSelectionBindingOption:@YES };
	
    /*
     Bind the array controller's content to self's anArray.
	 */
    [self.arrayController bind:@"contentArray"
					 toObject:self
				     withKeyPath:@"anArray"
					 options:options];
	
	/*
	 Bind the joystick's angle to the value for the "angle" key of the current selection in the array controller.
	 */
	[self.joystick bind:@"angle"
			  toObject:self.arrayController
	          withKeyPath:@"selection.angle"
		      options:options];
	
	/*
	 Bind the joystick's offset to the value for the "offset" key of the current selection in the array controller.
	 */
	[self.joystick bind:@"offset"
		      toObject:self.arrayController
	          withKeyPath:@"selection.offset"
		      options:options];

	/*
	 Create an array to contain Position objects.
	 This will be managed by the array controller.
	 */
	NSMutableArray *anArray = [NSMutableArray new];
	[anArray addObject:[Position new]];
	
    self.anArray = anArray;
}



/*
 Indexed accessor methods for 'anArray'.
 These are not strictly necessary, but make accessing the array by the array controller more efficient.
 See "Key-Value Coding Programming Guide > Key-Value Coding Accessor Methods" for more details.
 */
- (NSUInteger)countOfAnArray 
{
    return [self.anArray count];
}

- (id)objectInAnArrayAtIndex:(unsigned int)index 
{
    return [self.anArray objectAtIndex:index];
}

- (void)insertObject:(id)anObject inAnArrayAtIndex:(unsigned int)index 
{
    [self.anArray insertObject:anObject atIndex:index];
}

- (void)removeObjectFromAnArrayAtIndex:(unsigned int)index 
{
    [self.anArray removeObjectAtIndex:index];
}

- (void)replaceObjectInAnArrayAtIndex:(unsigned int)index withObject:(id)anObject 
{
    [self.anArray replaceObjectAtIndex:index withObject:anObject];
}


@end

