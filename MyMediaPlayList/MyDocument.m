/*

File: MyDocument.m

Abstract: MyDocument is a NSDocument subclass. Each document contains
		a movie playlist, which is simply a list of movies to be 
		played in sequence. A PlaylistItem object is created for each 
		movie in the play list. Each PlaylistItem contains a QTMovie
		object for the movie to be played.
		

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

#import "MyDocument.h"
#import "PlaylistItem.h"

#import <QTKit/QTKit.h>


// private methods
@interface MyDocument ()

- (void)setPlaylist:(NSMutableArray *)newPlaylist;
- (void)handleLoadStateChanged;
- (void)updateSelectedMovieIsPlaying;
- (void)updateSelectedMovieCurrentTime;
- (void)documentChanged;

@end

@implementation MyDocument

- (void)dealloc
{
	[mSelectedPlaylistIndexes release];
	[mPlaylist release];
	
	[super dealloc];
}

- (NSString *)windowNibName
{
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
   
    if (nil == [self playlist])
        [self setPlaylist:[NSMutableArray array]];
	
	// set the play button to not change its title when it's highlighted
	NSButtonCell *playButtonCell = (NSButtonCell *)[playButton cell];
	if ([playButtonCell isKindOfClass:[NSButtonCell class]])
		[playButtonCell setHighlightsBy:([playButtonCell highlightsBy] & ~NSContentsCellMask)];
}


- (void)close
{
	// unselect everything in the playlist to release any open movies.
	[self setSelectedPlaylistIndexes:[NSIndexSet indexSet]];
	
	[super close];
}

// Creates and returns a data object that contains the contents of the document playlist
- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
	return [NSKeyedArchiver archivedDataWithRootObject:[self playlist]];
	
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

// Sets the contents of this document by reading from media data in the playlist
- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
	[self setPlaylist:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
	
    return YES;
	
	if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return YES;
	
}

// Split View delegate method
// This keeps the source list on the left from resizing when the window is resized

- (BOOL)splitView:(NSSplitView *)splitView shouldAdjustSizeOfSubview:(NSView *)subview {
    if ([subview isKindOfClass:[NSScrollView class]]) return NO;
    else return YES;
}


#pragma mark PlayList

@synthesize playlist = mPlaylist;

- (void)setPlaylist:(NSMutableArray *)newPlaylist
{
    newPlaylist = [newPlaylist mutableCopy];
    [mPlaylist release];
	mPlaylist = newPlaylist;
}

- (void)documentChanged
{
    [self updateChangeCount:NSChangeDone];
}

- (void)insertObject:(id)object inPlaylistAtIndex:(NSUInteger)index
{
	[mPlaylist insertObject:object atIndex:index];
	[self documentChanged];
}

- (void)removeObjectFromPlaylistAtIndex:(NSUInteger)index
{
	[mPlaylist removeObjectAtIndex:index];
	[self documentChanged];
}


@dynamic selectedPlaylistIndexes;
- (NSIndexSet *)selectedPlaylistIndexes
{
	return [[mSelectedPlaylistIndexes copy] autorelease];
}

- (void)setSelectedPlaylistIndexes:(NSIndexSet *)selectedPlaylistIndexes
{
	if (((selectedPlaylistIndexes == nil) != (mSelectedPlaylistIndexes == nil))
		|| (mSelectedPlaylistIndexes && ![mSelectedPlaylistIndexes isEqualToIndexSet:selectedPlaylistIndexes]))
	{
		selectedPlaylistIndexes = [selectedPlaylistIndexes copy];
		[mSelectedPlaylistIndexes release];
		mSelectedPlaylistIndexes = selectedPlaylistIndexes;
		
		// open a new movie corresponding to the changed selection
		NSUInteger selectedIndex = [mSelectedPlaylistIndexes firstIndex];
		NSURL *selectedMovieURL = nil;
		
		if (selectedIndex != NSNotFound)
		{
			selectedMovieURL = [[[self playlist] objectAtIndex:selectedIndex] URL];
		}
		
		QTMovie *newSelectedMovie = nil;
		
		if (selectedMovieURL)
		{
			if ([selectedMovieURL isEqual:[mSelectedMovie attributeForKey:QTMovieURLAttribute]])
			{
				newSelectedMovie = mSelectedMovie;
			}
			else	
			{
				NSError *error = nil;
				/*
					Opting into QuickTime X
					
					Specify the QTMovieOpenForPlaybackAttribute movie attribute to opt into the more efficient media 
					capabilities provided in QuickTime X. This indicates whether a QTMovie object will be used only 
					for playback and not for editing or exporting.
				*/
				newSelectedMovie = [QTMovie movieWithAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
																 selectedMovieURL, QTMovieURLAttribute,
																 [NSNumber numberWithBool:YES], QTMovieOpenForPlaybackAttribute,
																 nil] error:&error];
				if (!newSelectedMovie)
					[self presentError:error];
			}
		}
		
		if (newSelectedMovie != mSelectedMovie)
		{
			NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
			
			if (mSelectedMovie)
			{
				/* register for movie notfications:
				
					QTMovieLoadStateDidChangeNotification
						-Sent when the load state of a movie has changed.
					QTMovieDidEndNotification
						-Sent when the movie is “done” or at its end.
					QTMovieRateDidChangeNotification
						-Sent when the rate of a movie has changed.
				*/
				[notificationCenter removeObserver:self name:QTMovieLoadStateDidChangeNotification object:mSelectedMovie];
				[notificationCenter removeObserver:self name:QTMovieDidEndNotification object:mSelectedMovie];
				[notificationCenter removeObserver:self name:QTMovieRateDidChangeNotification object:mSelectedMovie];
			}
			
			[self setSelectedMovie:newSelectedMovie];

			if (mSelectedMovie)
			{
				[notificationCenter addObserver:self selector:@selector(movieLoadStateChanged:) name:QTMovieLoadStateDidChangeNotification object:mSelectedMovie];
				[notificationCenter addObserver:self selector:@selector(movieDidEnd:) name:QTMovieDidEndNotification object:mSelectedMovie];
				[notificationCenter addObserver:self selector:@selector(movieRateChanged:) name:QTMovieRateDidChangeNotification object:mSelectedMovie];
				
				if (!mCheckMovieTimeTimer)
					mCheckMovieTimeTimer = [[NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(checkMovieTime:) userInfo:nil repeats:YES] retain];
			}
			else
			{
				[mCheckMovieTimeTimer invalidate];
				[mCheckMovieTimeTimer release];
				mCheckMovieTimeTimer = nil;
			}
			
			// reset selectedMovieDuration
			// this will be updated to the new movie's duration in handleLoadStateChanged once the
			// movie's load state is QTMovieLoadStateLoaded
			[self setSelectedMovieDuration:0.0];

			
			[self handleLoadStateChanged];
			[self updateSelectedMovieCurrentTime];
			[self updateSelectedMovieIsPlaying];
			
			[mSelectedMovie autoplay];
		}
	}
}

// display the open panel and allow the user to choose movies to add to the playlist
- (IBAction)addPlaylistItem:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	
    [openPanel setAllowsMultipleSelection:YES];
    [openPanel setAllowedFileTypes:[QTMovie movieFileTypes:QTIncludeCommonTypes]]; 
	
	[openPanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) {
		if (NSFileHandlingPanelOKButton == result)
		{
			for (NSURL *URL in [openPanel URLs])
			{
				[self insertObject:[PlaylistItem playlistItemWithURL:URL] inPlaylistAtIndex:[[self playlist] count]];
			}
		}
	}];
}

#pragma mark Movie

/*

Because opening a movie file or URL may involve reading and processing large amounts of movie 
data, QTKit may take a non-negligible amount of time to make a QTMovie object ready for 
inspection and playback. Accordingly, you need to pay attention to the movie’s load states when 
opening a movie file or URL. These are the defined movie load states:

   QTMovieLoadStateError   = -1L, // an error occurred while loading the movie
   QTMovieLoadStateLoading = 1000, // the movie is loading
   QTMovieLoadStateLoaded = 2000, // the movie atom has loaded; it's safe to query movie properties
   QTMovieLoadStatePlayable = 10000, // the movie has loaded enough media data to begin playing
   QTMovieLoadStatePlaythroughOK = 20000, //the movie has loaded enough media data to play through to end
   QTMovieLoadStateComplete = 100000L // the movie has loaded completely

*/
- (void)handleLoadStateChanged 
{
	QTMovie *movie = [self selectedMovie];
	if (movie)
	{
		NSInteger loadState = [[movie attributeForKey:QTMovieLoadStateAttribute] longValue];
		
		if (loadState == QTMovieLoadStateError)
		{
			// an error occurred while loading the movie
			[self presentError:[movie attributeForKey:QTMovieLoadStateErrorAttribute]];
		}
		
		if (loadState >= QTMovieLoadStateLoaded)
		{
			// now that the movie is loaded, it can return information about its structure
			// at this point, it is safe to get the movie's duration
			QTTime duration = [movie duration];
			
			NSTimeInterval timeInterval;
			QTGetTimeInterval(duration, &timeInterval);
			[self setSelectedMovieDuration:timeInterval];
		}
	}
}

// This method called when the load state of a movie has changed
- (void)movieLoadStateChanged:(NSNotification *)notification 
{
	[self handleLoadStateChanged];
}

@synthesize selectedMovie = mSelectedMovie;

@dynamic selectedMovieIsPlaying;
- (BOOL)selectedMovieIsPlaying
{
	return mSelectedMovieIsPlaying;
}

- (void)setSelectedMovieIsPlaying:(BOOL)selectedMovieIsPlaying
{
	// mSelectedMovieIsPlaying will be automatically updated by the QTMovieRateDidChangeNotification
	mSelectedMovieIsPlaying = selectedMovieIsPlaying;
	[[self selectedMovie] setRate:(selectedMovieIsPlaying ? 1.0f : 0.0f)];
}

- (void)updateSelectedMovieIsPlaying
{
	QTMovie *movie = [self selectedMovie];
	[self setSelectedMovieIsPlaying:(movie && [movie rate] != 0.0f)];
}

@synthesize selectedMovieDuration = mSelectedMovieDuration;

@dynamic selectedMovieCurrentTime;
- (NSTimeInterval)selectedMovieCurrentTime
{
	return mSelectedMovieCurrentTime;
}

- (void)setSelectedMovieCurrentTime:(NSTimeInterval)selectedMovieCurrentTime
{
	if (mSelectedMovieCurrentTime != selectedMovieCurrentTime)
	{
		// Sets the movie’s current time setting to time.
		mSelectedMovieCurrentTime = selectedMovieCurrentTime;
		[[self selectedMovie] setCurrentTime:QTMakeTimeWithTimeInterval(mSelectedMovieCurrentTime)];
	}
}

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey 
{
	BOOL automatic = NO;

	// specify that we support manual key-value observer notification
	// for the selectedMovieCurrentTime property (via the
	// updateSelectedMovieCurrentTime: method)
	if ([theKey isEqualToString:@"selectedMovieCurrentTime"]) 
	{ 
		automatic = NO;
	} 
	else 
	{ 
		automatic = [super automaticallyNotifiesObserversForKey:theKey];
	} 
	return automatic;
}

- (void)updateSelectedMovieCurrentTime
{
	NSTimeInterval selectedMovieCurrentTime = 0.0;
	
	QTMovie *movie = [self selectedMovie];
	if (movie)
	{
		QTGetTimeInterval([movie currentTime], &selectedMovieCurrentTime);
	}
	
	// set mSelectedMovieCurrentTime directly rather than calling setSelectedMovieCurrentTime:
	// since that will also call -[QTMovie setCurrentTime:], which will affect movie playback if
	// called while the movie is playing
	[self willChangeValueForKey:@"selectedMovieCurrentTime"];
	mSelectedMovieCurrentTime = selectedMovieCurrentTime;
	[self didChangeValueForKey:@"selectedMovieCurrentTime"];
}

// Sent when the rate of a movie has changed (QTMovieRateDidChangeNotification)
- (void)movieRateChanged:(NSNotification *)notification 
{
	[self updateSelectedMovieIsPlaying];
}

// timer routine called periodically to update the selected movie current time
- (void)checkMovieTime:(NSTimer *)timer
{
	[self updateSelectedMovieCurrentTime];
}

// called for QTMovieDidEndNotification when the movie is “done” or at its end.
- (void)movieDidEnd:(NSNotification *)note
{
    NSUInteger selectedIndex = [[self selectedPlaylistIndexes] firstIndex];
	NSUInteger playlistCount = [[self playlist] count];
	
    if ((selectedIndex != NSNotFound) && (++selectedIndex < playlistCount))
		[self setSelectedPlaylistIndexes:[[[NSIndexSet alloc] initWithIndex:selectedIndex] autorelease]];
}

#pragma mark Editing

// removes an item from the playlist
- (IBAction)cut:(id)sender
{
    [self copy:self];
	
	NSUInteger selectedIndex = [[self selectedPlaylistIndexes] firstIndex];
	if (selectedIndex != NSNotFound)
		[self removeObjectFromPlaylistAtIndex:selectedIndex];
}

// copy a movie item from the playlist
- (IBAction)copy:(id)sender
{
	NSIndexSet *selectedPlaylistIndexes = [self selectedPlaylistIndexes];
	
	if (selectedPlaylistIndexes && ([selectedPlaylistIndexes count] > 0))
	{
	    NSArray *selectedPlaylistItems = [[self playlist] objectsAtIndexes:selectedPlaylistIndexes];
	    
	    // get the general pasteboard
	    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	    
	    // clear the contents
	    [pboard clearContents];
	    
	    // write the objects
	    [pboard writeObjects:selectedPlaylistItems];
	}
	
}

// paste an item into the playlist
- (IBAction)paste:(id)sender
{
    NSPasteboard *pboard = [NSPasteboard generalPasteboard];
    
    NSArray *desiredClasses = [NSArray arrayWithObject:[PlaylistItem class]];
    NSArray *readPlaylistItems = [pboard readObjectsForClasses:desiredClasses options:nil];
    
    for (PlaylistItem *playlistItem in readPlaylistItems) {
	[self insertObject:playlistItem inPlaylistAtIndex:[[self playlist] count]];
    }
}

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    BOOL isValid = NO;
    SEL itemAction = [item action];
    
    if (itemAction == @selector(paste:))
	{
        NSPasteboard *pboard = [NSPasteboard generalPasteboard];
	NSArray *desiredClasses = [NSArray arrayWithObject:[PlaylistItem class]];
	isValid = [pboard canReadObjectForClasses:desiredClasses options:nil];
    }
    else if ((itemAction == @selector(cut:)) || (itemAction == @selector(copy:)))
	{
		NSIndexSet *selectedPlaylistIndexes = [self selectedPlaylistIndexes];
        isValid = ((nil != selectedPlaylistIndexes) && ([selectedPlaylistIndexes count] > 0));
    }
    else
	{
        isValid = [super validateMenuItem:item];
    }
	
    return isValid;
}

@end
