/*
     File: SpecialProtocol.h
 Abstract: Our custom NSURLProtocol.
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

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>


	/* our custom NSURLProtocol is implemented as a subclass. */
@interface SpecialProtocol : NSURLProtocol {
}
+ (NSString*) specialProtocolScheme;
+ (NSString*) specialProtocolVarsKey;
+ (void) registerSpecialProtocol;
@end

	/* utility category on NSImage used for converting
	NSImage to jfif data.  */
@interface NSImage (JFIFConversionUtils)

	/* returns jpeg file interchange format encoded data for an NSImage regardless of the
	original NSImage encoding format.  compressionValue is between 0 and 1.  
	values 0.6 thru 0.7 are fine for most purposes.  */
- (NSData *)JFIFData:(float) compressionValue;

@end


/* the following categories are added to NSURLRequest and NSMutableURLRequest
for the purposes of sharing information between the various webView delegate
routines and the custom protocol implementation defined in this file.  Our
WebResourceLoadDelegate (WRLD) will intercept resource load requests before they are
handled and if a NSURLRequest is destined for our special protocol, then the
WRLD will copy the NSURLRequest to a NSMutableURLRequest and call setSpecialVars
to attach some data we want to share between the WRLD and our NSURLProtocol
object. Inside of our NSURLProtocol we can access this data.

In this example, we store a reference to our WRLD object in the dictionary inside
of our WRLD method and then we call a method on our WRLD object from inside of our
startLoading method on our NSURLProtocol object.
*/

@interface NSURLRequest (SpecialProtocol)
- (NSDictionary *)specialVars;
@end

@interface NSMutableURLRequest (SpecialProtocol)
- (void)setSpecialVars:(NSDictionary *)caller;
@end

