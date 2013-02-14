/*
     File: UsingBlocksAsContextInfoAppDelegate.m 
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

#import "UsingBlocksAsContextInfoAppDelegate.h"

@implementation UsingBlocksAsContextInfoAppDelegate

@synthesize window, button;

// This is a quick tip on how to use the context info as a block parameter.
// You can use this type of pattern for any methods that have a delegate/selector/contextInfo pattern.
- (void)btnShowAlertClicked:(id)sender  {
    NSAlert *alert = [NSAlert alertWithMessageText:@"Alert Message"
                                     defaultButton:@"Default Button"
                                   alternateButton:@"Alternate Button"
                                       otherButton:@"Other Button"
                         informativeTextWithFormat:@"Informative Text"];
    
    BOOL someLocalVariable = YES;
    
    // We create a block that can easily access local variables to this method.
    // This is much easier than trying to package them all up into a contextInfo object
    void (^blockCallback)(NSInteger) = ^(NSInteger returnCode) {
        // Inside the block callback we can easily access locals
        if (someLocalVariable) {
            if (returnCode == NSAlertDefaultReturn) {
                [button setTitle:@"Default Return Button Clicked!"];
            } else {
                [button setTitle:@"Something else clicked...try again."];
            }
        }
    };
    
    // We copy the block, since it needs to stay alive for longer than the current scope
    [alert beginSheetModalForWindow:self.window
                      modalDelegate:[self class]
                     didEndSelector:@selector(alertDidEnd:returnCode:contextInfo:)
                        contextInfo:Block_copy(blockCallback)];
}

+ (void)alertDidEnd:(NSAlert *)alert returnCode:(NSInteger)returnCode contextInfo:(void (^)(NSInteger returnCode))continuationHandler {
    continuationHandler(returnCode);
    // The block must always be retained before the first call. This is the matching release
    Block_release(continuationHandler);
}

@end
