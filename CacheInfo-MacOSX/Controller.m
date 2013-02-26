/*
 
 File:<Controller.m>
 
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
 
 Copyright (C) 2008 Apple Inc. All Rights Reserved.
 
 */

#import "Controller.h"

/* maximum cache sizes in megabytes */

const double kMemoryCacheSize = 50.0;
const double kDiskCacheSize = 100.0;

/* Private methods. Instead of declaring them in the header, 
 we declare them here in a category that extends the class. */

@interface Controller (InternalMethods)

- (void) createConnectionWithPath:(NSString *)thePath;
- (void) controlsEnabled:(BOOL)flag;
- (void) reset;
- (void) terminate;

@end

@implementation Controller

@synthesize diskPath;
@synthesize connectionTime;
@synthesize receivedData;
@synthesize connection;

@synthesize loadButton;
@synthesize clearButton;
@synthesize comboBox;
@synthesize sizeField;
@synthesize timeField;
@synthesize memoryField;
@synthesize diskField;
@synthesize memoryUsage;
@synthesize diskUsage;
@synthesize imageView;
@synthesize progressIndicator;
@synthesize memoryCacheSlider;
@synthesize diskCacheSlider;


/*
------------------------------------------------------------------------
	Initialization
------------------------------------------------------------------------
*/

- (id)init
{
    self = [super init];
    
    /* Defines a temporary directory for the on-disk URL cache. */
	
    self.diskPath = [[NSMutableString alloc] initWithString:NSTemporaryDirectory()];
    NSString *appName = [[NSProcessInfo processInfo] processName];
    [self.diskPath appendString:appName];
    
	/* Creates a custom URL cache that uses both memory and disk. */
	
	NSURLCache *sharedCache = 
	[[NSURLCache alloc] initWithMemoryCapacity:kMemoryCacheSize * 1000000 
								  diskCapacity:kDiskCacheSize * 1000000 
									  diskPath:diskPath];
	[NSURLCache setSharedURLCache:sharedCache];
	[sharedCache release];
	
	return self;
}


/* Do some UI initialization after loading the nib file. */

- (void)awakeFromNib {
    
    /* Initializes the memory and disk cache sliders. */
	
	[self.memoryCacheSlider setMaxValue:kMemoryCacheSize];
	[self.memoryCacheSlider setDoubleValue:kMemoryCacheSize];
	[self.diskCacheSlider setMaxValue:kDiskCacheSize];
	[self.diskCacheSlider setDoubleValue:kDiskCacheSize];
    [self onMemorySlider:self];
    [self onDiskSlider:self];
	
	/* Initializes the cache usage fields. */

 	[self onClearCache:self];

	/* Adds list of URLs to the NSComboBox control. */

    NSString *path = [[NSBundle mainBundle] pathForResource:@"URL" ofType:@"plist"];
    if (path) {
		NSArray *urlArray = [NSArray arrayWithContentsOfFile:path];
		[comboBox addItemsWithObjectValues:urlArray];

		/* Displays the first URL in the list. Also triggers the 
		 comboBoxSelectionDidChange: notification. */

		[comboBox selectItemAtIndex:0];
    }
}


- (void)dealloc
{
	[diskPath release];	
	[super dealloc];
}


/*
------------------------------------------------------------------------
	Action methods that respond to UI events or change the UI
------------------------------------------------------------------------
*/

#pragma mark IBAction methods

- (IBAction)onLoadResource:(id)sender
{
    /* starts loading the resource (possibly cached) */
    [self createConnectionWithPath:[comboBox stringValue]];
}


- (IBAction)onMemorySlider:(id)sender 
{
	/* displays the memory cache size in megabytes */

    double value = [self.memoryCacheSlider doubleValue];
    [self.memoryField setDoubleValue:value];

	/* set size of memory cache in bytes */

	NSUInteger memoryCacheSize = value * 1000000;
	[[NSURLCache sharedURLCache] setMemoryCapacity:memoryCacheSize];
}


- (IBAction)onDiskSlider:(id)sender 
{
	/* displays the disk cache size in megabytes */

    double value = [self.diskCacheSlider doubleValue];
    [self.diskField setDoubleValue:value];
	
	/* sets size of the disk cache in bytes */

	NSUInteger diskCacheSize = value * 1000000;
	[[NSURLCache sharedURLCache] setDiskCapacity:diskCacheSize];
}


- (IBAction)onClearCache:(id)sender
{
    /* clears the shared cache */

    NSURLCache *sharedCache = [NSURLCache sharedURLCache];
    [sharedCache removeAllCachedResponses];

    /* resets the cache usage fields */

    [self.memoryUsage setDoubleValue:[sharedCache currentMemoryUsage] / 1000000.0];
    [self.diskUsage setDoubleValue:[sharedCache currentDiskUsage] / 1000000.0];
}


/* NSResponder sends this message when the user presses Escape or
 Command-Period. To receive this message, we need to be the window
 delegate. */

- (IBAction)cancel:(id)sender
{
	/* User cancelled operation. If a load operation is in progress, 
	 we cancel it. */

	if (self.connection) {
		[self.connection cancel];
		[self terminate];	
    }
}


/*
------------------------------------------------------------------------
	Private methods
------------------------------------------------------------------------
*/

#pragma mark Internal methods

/* Used to disable the controls during an uncached load. */

- (void)controlsEnabled:(BOOL)flag
{
    [comboBox setEnabled:flag];
    [loadButton setEnabled:flag];
    [clearButton setEnabled:flag];
}


/* Resets the resource fields. */

- (void) reset
{
    [self.imageView setImage:nil];
    [self.sizeField setStringValue:@""];
    [self.timeField setStringValue:@""];
	[self.timeField setTextColor:[NSColor blackColor]];
}

 
/* Called when connection is no longer active. */

- (void) terminate
{
	/* releases the connection */
	if (self.connection) {
		[self.connection release];
		self.connection = nil;
	}

	/* shows the user that loading activity has stopped */
	[self.progressIndicator stopAnimation:self];
	[self controlsEnabled:YES];	
}	


/* Initiates a load request when the user clicks the Load Resource button. 
 The URL connection is asynchronous, and we implement a set of delegate 
 methods that act as callbacks during the load. */

- (void) createConnectionWithPath:(NSString *)thePath
{
    /* Creates the URL request. The cache policy specifies that the
     existing cached data should be used to satisfy the request,
     regardless of its age or expiration date. */

    NSURLRequest *theRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:thePath]
						cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:60];

	/* Finds out if the request response is found in the shared cache. 
	 If so, displays the elapsed time in gray to indicate a cache hit. */

    NSURLCache *sharedCache = [NSURLCache sharedURLCache];
	NSCachedURLResponse *response = [sharedCache cachedResponseForRequest:theRequest];
	if (response) {
		[timeField setTextColor:[NSColor grayColor]];
	} 
	else {
		[self reset];
		[self controlsEnabled:NO];
		[timeField setTextColor:[NSColor blackColor]];
	}
    
	/* Creates the URL connection with the request and starts loading the
	 data. */

    self.connection = [[NSURLConnection alloc] initWithRequest:theRequest 
    					delegate:self startImmediately:YES];
    
    if (self.connection) {
		/* record the start time of the connection */
		self.connectionTime = [NSDate date];
		
		/* create an object to hold the received data */
		self.receivedData = [NSMutableData data];

		/* show the user that loading activity has begun */
		[self.progressIndicator startAnimation:self];

    } 
}

/*
------------------------------------------------------------------------
	NSURLConnection delegate methods for asynchronous requests
------------------------------------------------------------------------
*/

#pragma mark NSURLConnection delegate methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    /* Called when the server has determined that it has enough  
	 information to create the NSURLResponse. It can be called 
	 multiple times (for example in the case of a redirect), so 
	 each time we reset the data. */
	
    [self.receivedData setLength:0];
    
}

- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    /* appends the new data to the received data */

    [self.receivedData appendData:data];
}

- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    /* inform the user here */
    
	/* logs the error */
    
	NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
    
    /* prepares for a new connection */
    
	[self terminate];
}


/* This method demonstrates how to control response caching. Our policy
 is to only cache HTTP requests. If the resource is loaded from the
 shared cache, this method is not called. */

- (NSCachedURLResponse *) connection:(NSURLConnection *)connection 
		   willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    
    NSCachedURLResponse *newCachedResponse = nil;
    
    if ([[[[cachedResponse response] URL] scheme] isEqual:@"http"]) {
		newCachedResponse = [[[NSCachedURLResponse alloc]
			      initWithResponse:[cachedResponse response]
			      data:[cachedResponse data]
			      userInfo:nil
			      storagePolicy:[cachedResponse storagePolicy]]
			      autorelease];
    }
    
    return newCachedResponse;
}


/*
------------------------------------------------------------------------
	connectionDidFinishLoading:
------------------------------------------------------------------------
*/

- (void) connectionDidFinishLoading:(NSURLConnection *)connection
{
	/* displays the elapsed time in milliseconds */

    NSTimeInterval elapsedTime = [[NSDate date] timeIntervalSinceDate:self.connectionTime];
    [self.timeField setDoubleValue:elapsedTime * 1000.0];
	
	/* displays length of the received data in bytes */

	NSUInteger length = [self.receivedData length];
    [self.sizeField setIntegerValue:length];
	
	/* displays memory and disk cache usage in megabytes */

	NSUInteger currentMemoryUsage = [[NSURLCache sharedURLCache] currentMemoryUsage];
    [self.memoryUsage setDoubleValue:currentMemoryUsage / 1000000.0];
    NSUInteger currentDiskUsage = [[NSURLCache sharedURLCache] currentDiskUsage];
    [self.diskUsage setDoubleValue: currentDiskUsage / 1000000.0];
    
	/* assumes the received data is an image and tries to display it */

    NSImage *theImage = [[NSImage alloc] initWithData:receivedData];
    if (theImage) {
		[imageView setImage:theImage];
		[theImage release];
    }
	
	[self terminate];
}


/*
------------------------------------------------------------------------
	Other delegate methods
------------------------------------------------------------------------
*/

#pragma mark Other delegate methods

/* This NSComboBox delegate method is called when the user selects a
 different URL. We clear the fields that contain the previous connection
 data. */

- (void) comboBoxSelectionDidChange:(NSNotification *)notification 
{
	[self reset];
}


/* This NSApplication delegate method is called when the user closes the
 application window. */

- (BOOL) applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    return YES;
}


/* This NSApplication delegate method is called when the application is
 about to terminate. */

- (void) applicationWillTerminate:(NSNotification *)aNotification
{
	/* deletes the disk cache */
    [[NSFileManager defaultManager] removeItemAtPath:self.diskPath error:NULL];
}

@end
