/*
     File: MyController.m 
 Abstract: webView delegate / window controller object for this sample. 
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


#import "MyController.h"
#import "SpecialProtocol.h"

@implementation MyController

@synthesize theWebView;

	/* our awakeFromNib routine is called after the nib file
	has been successfully loaded.  We set up our webPage and install
	our protocol handler then. */
- (void) awakeFromNib {

	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));

		/* register our special protocol with webkit */
	[SpecialProtocol registerSpecialProtocol];
	
		/* load our main webpage. */
	[self reset:nil];

}


- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


	/* called when the reset button is clicked.  Here, we simply reload the page. */
- (IBAction)reset:(id)sender
{
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
	
		/* load our main webpage.  You'll notice that in that file we
		load all of our images using the 'special':// scheme (which
		generates the image files on the fly in memory).  */
	NSURL *mainWebPageURL = [[NSBundle mainBundle] URLForResource:@"test" withExtension:@"html"];
    
	[[theWebView mainFrame] loadRequest:[NSURLRequest requestWithURL:mainWebPageURL]];
}



	/* returns a string that we will use as a key for pairing with
	our MyController object in the dictionary shared between our protocol
	and this controller object.  This will allow the protocol to get
	a reference back to the calling controller object should it need to.  */
+ (NSString*) callerKey {
	return @"caller";
}



	/* Called just before a webView attempts to load a resource.  Here, we look at the
	request and if it's destined for our special protocol handler we modify the request
	so that it contains an NSDictionary containing some information we want to share
	between the code in this file and the custom NSURLProtocol.  */
-(NSURLRequest *)webView:(WebView *)sender resource:(id)identifier 
	willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse
		fromDataSource:(WebDataSource *)dataSource {

		/* if this request will be handled by our special protocol... */
	if ( [SpecialProtocol canInitWithRequest:request] ) {
	    
			/* create a NSDictionary containing any values we want to share between
			our webView/delegate object we are running in now and the protocol handler.
			Here, we'll put a referernce to ourself in there so we can access this
			object from the special protocol handler. */
		NSDictionary *specialVars = [NSDictionary dictionaryWithObject:self
				forKey:[MyController callerKey]];

			/* make a new mutable copy of the request so we can add a reference to our
			dictionary record. */
		NSMutableURLRequest *specialURLRequest = [[request mutableCopy] autorelease];

			/* call our category method to store away a reference to our dictionary. */
		[specialURLRequest setSpecialVars:specialVars];
		
			/* return the new modified request */
		return specialURLRequest;

	} else {
		return request;
	}
}



	/* this is an extra routine we added to show how the protocol could
	call back to the webView's delegate object while processing a request. */
- (void)callbackFromSpecialRequest:(NSURLRequest *)request
{
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
}



@end
