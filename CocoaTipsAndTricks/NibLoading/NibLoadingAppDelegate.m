/*
     File: NibLoadingAppDelegate.m 
 Abstract: The sample's application delegate used to manage its primary window. 
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
  
 Copyright (C) 2010 Apple Inc. All Rights Reserved. 
  
 */

#import "NibLoadingAppDelegate.h"
#import "MyWindowController.h"

@implementation NibLoadingAppDelegate

- (void)dealloc
{
    [_myWindowController release];
    [super dealloc];
}

@synthesize window;

- (void)awakeFromNib {
    // Note that as the owner you will get an awake from nib every time a new nib is instatiated.
    // It is important to be aware of this and to make sure you accidentally don't repeat your setup twice.
    static NSInteger awakeFromNibCount = 0;
    NSLog(@"awakeFromNib called %ld", (long)++awakeFromNibCount);
}

- (IBAction)btnManualSecondWindowLoadClick:(id)sender {
    NSNib *nib = [[NSNib alloc] initWithNibNamed:@"SecondWindow" bundle:nil];

    // At this pint, our outlets to inside this nib will be properly setup. It is important to note
    // that they will get overwritten when this is called again!
    // In general, it is good practice to use a unique controller object for each nib you load.
    // You will normally pass that controller as the 'owner'. For simplicity purposes we are passing
    // in this object as the owner.
    //
    [nib instantiateNibWithOwner:self topLevelObjects:nil];
    [_secondWindow makeKeyAndOrderFront:nil];
   
    // Tip: We can reuse the same nib and load it again! This will overwrite the IBOutlet with the new value.
    [nib instantiateNibWithOwner:self topLevelObjects:nil];
    [_secondWindow makeKeyAndOrderFront:nil];
    
    [nib release];
}

- (IBAction)btnLoadThirdWindowWithController:(id)sender {
    // Using a window controller is even easier, and generally better for management for code.
    if (_myWindowController == nil) {
        _myWindowController = [[MyWindowController alloc] initWithWindowNibName:@"ThirdWindow"];
    }
    [_myWindowController.window makeKeyAndOrderFront:nil];
}



@end
