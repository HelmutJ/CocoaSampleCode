/*

File: PlaylistItem.m

Abstract: Implementation of the PlaylistItem object.

		  A PlaylistItem object represents a single movie in a list
          of movies that are to be played. A PlaylistItem object 
		  conforms to the NSCoding protocol to allow a playlist to be written
		  to a file on disk. It also conforms to the NSPasteboardWriting
		  and NSPasteboardReading protocols to enable copy and paste 
		  operations between different playlists.

Version: 1.0

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

Copyright (C) 2010 Apple Inc. All Rights Reserved.

*/

#import "PlaylistItem.h"

/* 

Using a private pasteboard type that conforms to UTI naming guidelines.  
Since this type is only used by this application, it is not formally declared as a UTI.

*/
NSString * const MyPasteboardTypePlaylistItem = @"com.example.pasteboard.playlistItem";


static NSString * const PlaylistItemURLCoderKey = @"URL";

@implementation PlaylistItem

+ (void)initialize
{
    if (self == [PlaylistItem class])
	{
        [self setVersion:1];
    }
}

+ (PlaylistItem *)playlistItemWithURL:(NSURL *)URL
{
	return [[[self alloc] initWithURL:URL] autorelease];
}

- (id)initWithURL:(NSURL *)URL
{
	self = [super init];
	
	if (self)
	{
		mURL = [URL copy];
	}
	
	return self;
}

- (id)init 
{    
    return [self initWithURL:nil];
}

@synthesize URL = mURL;

@dynamic localizedName;
- (NSString *)localizedName 
{
	NSString *displayName = nil;
	NSURL *URL = [self URL];
	[URL getResourceValue:&displayName forKey:NSURLLocalizedNameKey error:NULL];
	if (!displayName)
		displayName = [URL lastPathComponent];
	
	return displayName;
}

#pragma mark NSCoding
/*

The NSCoding protocol declares the -encodeWithCoder: and -initWithCoder: methods 
that a class must implement so that instances of that class can be encoded and decoded.

*/
- (void)encodeWithCoder:(NSCoder *)coder 
{
    [coder encodeObject:[self URL] forKey:PlaylistItemURLCoderKey];
}

- (id)initWithCoder:(NSCoder *)coder 
{
    return [self initWithURL:[coder decodeObjectForKey:PlaylistItemURLCoderKey]];
}

- (void)dealloc
{
	[mURL release];
	
	[super dealloc];
}

/* 

Implementing NSPasteboardWriting and NSPasteboardReading protocols to allow 
PlaylistItems to be written and read on the pasteboard 

*/

#pragma mark NSPasteboardWriting

/* NSPasteboardWriting */
- (NSArray *)writableTypesForPasteboard:(NSPasteboard *)pasteboard 
{
    return [NSArray arrayWithObjects:MyPasteboardTypePlaylistItem, NSPasteboardTypeString, nil];
}

- (id)pasteboardPropertyListForType:(NSString *)type 
{
    if ([type isEqualToString:MyPasteboardTypePlaylistItem]) 
	{
		return [NSKeyedArchiver archivedDataWithRootObject:self];
    } 
	else if ([type isEqualToString:NSPasteboardTypeString]) 
	{
		return [self localizedName];
    } 
	else 
	{
		return nil; // Return nil if we are asked for a type we don't support
    }
}

#pragma mark NSPasteboardReading
/* NSPasteboardReading */

+ (NSArray *)readableTypesForPasteboard:(NSPasteboard *)pasteboard 
{
    return [NSArray arrayWithObject:MyPasteboardTypePlaylistItem];
}

+ (NSPasteboardReadingOptions)readingOptionsForType:(NSString *)type pasteboard:(NSPasteboard *)pasteboard 
{
    if ([type isEqualToString:MyPasteboardTypePlaylistItem]) 
	{
		return NSPasteboardReadingAsKeyedArchive;
    } 
	else 
	{
		return 0;
    }
}

@end
