/*
     File: TransitionSetup.m
 Abstract: Category for the TransitionSelectorView that 
 gathers all transitions and sets them up for
 rendering.
  Version: 1.2
 
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

#import "TransitionSelectorView.h"


@implementation TransitionSelectorView (TransitionSetup)

- (void)setupTransitions
{
    CIVector  *extent;
    int        i;


    if(!transitions)
    {
		// get all the transition filters
		NSArray	*foundTransitions = [CIFilter filterNamesInCategories:[NSArray arrayWithObject:kCICategoryTransition]];
		
		if(!foundTransitions)
			return;
		i = [foundTransitions count];

		extent = [CIVector vectorWithX: 0  Y: 0  Z: thumbnailWidth  W: thumbnailHeight];
		transitions = [[NSMutableArray alloc] initWithCapacity:i];
		while(--i >= 0)
		{
			CIFilter	*theTransition = [CIFilter filterWithName:[foundTransitions objectAtIndex:i]];	    // create the filter
			
			[theTransition setDefaults];    // initialize the filter with its defaults, as we might not set every value ourself

			// setup environment maps and other static parameters of the filters
			NSArray		*filterKeys = [theTransition inputKeys];
			NSDictionary	*filterAttributes = [theTransition attributes];
			if(filterKeys)
			{
				NSEnumerator	*enumerator = [filterKeys objectEnumerator];
				NSString		*currentKey;
				NSDictionary	*currentInputAttributes;
				
				while(currentKey = [enumerator nextObject]) 
				{
					if([currentKey compare:@"inputExtent"] == NSOrderedSame)		    // set the rendering extent to the size of the thumbnail
						[theTransition setValue:extent forKey:currentKey];
					else {
						currentInputAttributes = [filterAttributes objectForKey:currentKey];
						
						NSString		    *classType = [currentInputAttributes objectForKey:kCIAttributeClass];
						
						if([classType compare:@"CIImage"] == NSOrderedSame)
						{
							if([currentKey compare:@"inputShadingImage"] == NSOrderedSame)	// if there is a shading image, use our shading image
								[theTransition setValue:[self shadingImage] forKey:currentKey];
							else if ([currentKey compare:@"inputBacksideImage"] == NSOrderedSame)	// this is for the page curl transition
								[theTransition setValue:[self sourceImage] forKey:currentKey];
							else 
								[theTransition setValue:[self maskImage] forKey:currentKey];
						}
					}
				}
			}
			[transitions addObject:theTransition];
		}
    }
}

@end
