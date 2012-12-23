/*
     File: MyCollectionViewItem.m 
 Abstract: Subclass of NSCollectionViewItem for 10.5.x compatibility.
  
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

#import "MyCollectionViewItem.h"

static NSNib *viewNib = nil;

@implementation MyCollectionViewItem

// Since NSCollectionView implementation has changed in 10.6.x, NSCollectionViewItem is now a
// subclass of NSViewController, we need to override here for 10.5.x to load its view.
//
- (id)copyWithZone:(NSZone *)zone
{
	id result;
	
	if (![self isKindOfClass:[NSViewController class]])
	{
		// 10.5.x - load the view
		//
		
		// don't call super in this case and load our view manually
		result = [[[self class] alloc] init];
	
		if (viewNib == nil)
		{
			NSBundle *myBundle = [NSBundle bundleForClass:[result class]];
			viewNib = [[NSNib alloc] initWithNibNamed:@"CollectionItemView" bundle:myBundle];
		}
		
		// set the view to this controller
		NSArray *topObjects = nil;
		[viewNib instantiateNibWithOwner:result topLevelObjects:&topObjects];
		for (id obj in topObjects)
		{
			if ([obj isKindOfClass:[NSView class]])
			{
				[self setView:obj];
				break;
			}
		}
		
		[topObjects release];
	}	
	else
	{
		// 10.6.x - create our object the default way
		//
		result = [super copyWithZone:zone];
	}
	
	return result;
}

// For 10.6.x as an NSViewController -
// If your app loads your collection item's view from a separate nib (set in Interface Builder),
// you do not need to override this method. So in our case this method is not needed.
/*
- (void)loadView
{
	
}
*/

@end
