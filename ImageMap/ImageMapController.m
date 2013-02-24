/*

File: ImageMapController.m

Abstract: controller object for image map example

Version: <1.0>

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

Copyright (C) 2005-2009 Apple Inc. All Rights Reserved.

*/ 

#import "ImageMapController.h"
#import "ImageMap.h"

static void SetSegmentDescriptions(NSSegmentedControl *control, NSString *firstDescription, ...) {
    // Use NSAccessibilityUnignoredDescendant to be sure we start with the correct object.
    id segmentElement = NSAccessibilityUnignoredDescendant(control);
    
    // Use the accessibility protocol to get the children.
    NSArray *segments = [segmentElement accessibilityAttributeValue:NSAccessibilityChildrenAttribute];
    
    va_list args;
    va_start(args, firstDescription);
    
    id segment;
    NSString *description = firstDescription;
    NSEnumerator *e = [segments objectEnumerator];
    while ((segment = [e nextObject])) {
        if (description != nil) {
            [segment accessibilitySetOverrideValue:description forAttribute:NSAccessibilityDescriptionAttribute];
        } else {
            // Exit loop if we run out of descriptions.
            break;
        }
        description = va_arg(args, id);
    }
    
    va_end(args);
}


@implementation ImageMapController

- (void)awakeFromNib {

    // configure image map
    [imageMap setImageAndHotSpotsFromImageAndImageMapNamed:@"FoodPyramid"];
    [imageMap setTarget:self];
    [imageMap setAction:@selector(imageMapAction:)];
    [imageMap setHotSpotCompositeOperation:NSCompositePlusLighter];
    
    
    // configure segmented control
    [segmentedControl setImage:[NSImage imageNamed:@"InvisibleHotSpots"] forSegment:0];
    [segmentedControl setImage:[NSImage imageNamed:@"VisibleHotSpots"] forSegment:1];
    [segmentedControl setImage:[NSImage imageNamed:@"RolloverHighlighting"] forSegment:2];
    [segmentedControl setSelectedSegment:0];

    // set up segmented control accessibility

    id segmentedControlElement = NSAccessibilityUnignoredDescendant(segmentedControl);
    id segmentedControlTitleElement = NSAccessibilityUnignoredDescendant(segmentedControlTitle);
    [segmentedControlElement accessibilitySetOverrideValue:segmentedControlTitleElement forAttribute:NSAccessibilityTitleUIElementAttribute];

    SetSegmentDescriptions(segmentedControl, @"invisible hot spots", @"visible hot spots", @"rollover highlighting", nil);
}

- (IBAction)segmentedControlAction:(id)sender {
    int segmentIndex = [segmentedControl selectedSegment];
    BOOL hotSpotsVisible;
    BOOL rolloverHighlighting;
    switch (segmentIndex) {
	case 0:
	    hotSpotsVisible = NO;
	    rolloverHighlighting = NO;
	    break;
	case 1:
	    hotSpotsVisible = YES;
	    rolloverHighlighting = NO;
	    break;
	case 2:
	    hotSpotsVisible = NO;
	    rolloverHighlighting = YES;
	    break;
    }
    [imageMap setHotSpotsVisible:hotSpotsVisible];
    [imageMap setRolloverHighlighting:rolloverHighlighting];
}

- (void)hotSpotAction_grains {
    [imageTextField setStringValue:@"Grains"];
}
- (void)hotSpotAction_vegetables {
    [imageTextField setStringValue: @"Vegetables"];
}
- (void)hotSpotAction_fruits {
    [imageTextField setStringValue:@"Fruits"];
}
- (void)hotSpotAction_dairy {
    [imageTextField setStringValue:@"Dairy"];
}
- (void)hotSpotAction_meat {
    [imageTextField setStringValue:@"Meat and Eggs"];
}
- (void)hotSpotAction_fats {
    [imageTextField setStringValue:@"Fats and Sweets"];
}

- (IBAction)imageMapAction:(id)sender {
    NSDictionary *info = [imageMap selectedHotSpotInfo];
    NSString *href = [info objectForKey:@"href"];
    if ([href length] > 0) {
        SEL action = NSSelectorFromString([NSString stringWithFormat:@"hotSpotAction_%@", href]);
        if ([self respondsToSelector:action]) {
            [self performSelector:action];
        } else {
            NSLog(@"unsupported hot spot: %@", info);
        }
    }
}


@end
