/*
     File: MyController.m 
 Abstract: Main controller's header file for the AttachAScript sample. 
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


#import <Carbon/Carbon.h>

#import "MyController.h"
#import "AEDescUtils.h"




@implementation MyController


	/* awakeFromNib is called after our window has been completely
	loaded from disk and it is ready to use.  We do all of our initialization
	steps in this method. */
- (void)awakeFromNib {
	NSDictionary* errorInfo;
	NSBundle* bundle = [NSBundle mainBundle];
	NSURL* scriptURL;
	NSAppleEventDescriptor *playLists;
	NSString* playerState;
	
		/* get the images we're using in our buttons, store them in a table */
	self.imagesTable = [NSArray arrayWithObjects:
		[NSImage imageNamed:@"shuffleoff.png"],
		[NSImage imageNamed:@"shuffleon.png"],
		[NSImage imageNamed:@"playp.png"],
		[NSImage imageNamed:@"pausep.png"],
		[NSImage imageNamed:@"repeatoff.png"],
		[NSImage imageNamed:@"repeaton.png"],
		[NSImage imageNamed:@"repeatone.png"],
                        nil];

		/* load the gong sound */
	self.gongSound = [[[NSSound alloc] initWithContentsOfFile:[bundle pathForResource:@"gong" ofType:@"aif"]
			byReference:NO] autorelease];

		/* load the compiled version of our AppleScript from the file AttachedScripts.scpt
		in the resources folder.  This script contains all of the handlers we will
		be using in this application.  */
	self.myScript = [[[TAttachedScripts alloc] init] autorelease];
	
		/* call the HookUpToRemoteMachine handler in our compiled AppleScript to
		allow the user to select a remote machine running the iTunes program we
		would like to control.  Remote Apple Events must be enabled on the remote
		machine. */
	if ( nil == self.myScript ) {
	
            /* no connection to remot machine.  If there was an error in the AppleScript
            then callScript will have already reported it so here we just quit. */
		[NSApp terminate:self];
		
	} else {
	
			/* update our user interface to reflect the state of the remote player */
		[self updatePlayerStatus];
		
			/* get the list of playlists on the remote machine */
		self.playlistItems = [[[self myScript] callHandler:@"GetPlaylistListing" withParameters:nil]
			listOfStringsToSortedArray];
		
			/* set up the play list object */
		[playlists setDataSource:self];
		[playlists setTarget:self];
		[playlists setDelegate:self];
		[playlists setAction:@selector(clickNewPlaylist)]; /* single clicks select a playlist to view */
		
			/* set up the track list object */
		self.tracklistItems = nil;
		[tracklist setDataSource:self];
		[tracklist setTarget:self];
		[tracklist setDelegate:self];
		[tracklist setDoubleAction:@selector(clickTrackToPlay)]; /* double clicks select a track to play */
	}
}





	/* windowShouldClose is called because we have set our controller object
	to be the main window's delegate object in the nib file.  Here, we terminate
	the application when the main window is closed. */
- (BOOL)windowShouldClose:(id)sender {
	[NSApp terminate:self];
	return YES;
}





	/* theScript and setTheScript are accessor methods for the theScript slot
	on our object.  Note that the 'copy' method has been commented out here
	because it does not work with Apple event descriptor records.  we store
	a reference to our compiled AppleScript that we loaded from the file
	AttachedScripts.scpt in theScript slot. */
@synthesize myScript;


	/* updatePlayerStatus communicates with the remote iTunes application and
	updates the user interface according to the results received.  This routine
	calls the ReportRemotePlayerState handler in the compiled AppleScript to
	obtain the necessary information from the remote host.  updatePlayerStatus also
	registers a timed callback to itself so that the interface will be updated
	periodically as music is playing.  */
- (void)updatePlayerStatus {
	RemotePlayerState *playerInfo;
	int updateTime;
	
		/*  call AppleScript to retrieve status information about the remote host.   */
	playerInfo = [[self myScript] getRemotePlayerState];

		/* display the status string */
	[statusline setStringValue:[playerInfo playerStatusString]];
	
		/* display the volume setting */
	[volumesetting setIntValue:[playerInfo playerVolume]];
	
		/* adjust play/pause button, calculate the update timer */
	if ( [playerInfo isPlaying] ) {
	
			/* swap in the image displayed while playing */
		[playpausebutton setImage:[[self imagesTable] objectAtIndex:kPauseImage]];

			/* calculate a reasonable interval before the next update.  Most likely,
			a good time to update is just after the current track stops playing. */
		updateTime = [playerInfo trackDuration] - [playerInfo positionInTrack] + 1;
		
			/* but, someone could be tinkering with the settings at the other end
			and our status may need to be updated before then.  So, we cap the update
			interval. */
		if (updateTime > kMaximumUpdateInterval) updateTime = kMaximumUpdateInterval;
		
			/* enable the gong button */
		[gongbutton setEnabled:YES];
		
	} else {
	
			/* swap in the image displayed while playing */
		[playpausebutton setImage:[[self imagesTable] objectAtIndex:kPlayImage]];
		
			/* call for the next update at our baseline interval */
		updateTime = kNotPlayingUpdateInterval;
		
			/* disable the gong button */
		[gongbutton setEnabled:NO];
	}
	
		/* remove any prior timed update requests in case there are any pending */
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePlayerStatus)
			object:nil];
	
		/* set a timed callback for the next update */
	[self performSelector:@selector(updatePlayerStatus) withObject:nil afterDelay:updateTime];
}


	/* tableView:shouldEditTableColumn:row: is called because we have set our object
	to be the delegate for both of the NSTable views we have in our window.  This
	method always returns NO and so turns off editing for all of our cells. */
- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex {
	return NO;
}


	/* numberOfRowsInTableView: is called because we have set our object as the
	target for both of the NSTable views installed in our window.  In this routine
	we check which table we are being asked about and then we return the number
	of rows in that table.  */
- (int)numberOfRowsInTableView:(NSTableView *)tableView {
    if (tableView == playlists) {
		return [self.playlistItems count];
	} else if (tableView == tracklist && self.tracklistItems != nil) {
		return [self.tracklistItems count];
	}
	return 0;
}


	/* tableView:objectValueForTableColumn:row: is called because we have set
	our object as the target for both of the NSTable views installed in our
	window.  In this routine we check which table we are being asked about
	and then we return the contents of the cell being asked for.  */
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn
		row:(int)row {
    if (tableView == playlists) {
	
			/* playlistItems is an Apple event descriptor containing a list
			of Apple event descriptors containing strings.  The list is
			indexed starting at 1... */
		return [self.playlistItems objectAtIndex:row];
		
	} else if (tableView == tracklist && tracklistItems != nil) {
	
			/* tracklistItems is an Apple event descriptor containing a list
			of Apple event descriptors containing strings.  The list is
			indexed starting at 1... */
		return [self.tracklistItems objectAtIndex:row];
	}
	return @""; /* default string */
}


	/* clickNewPlaylist is called whenever a single click is made on the list
	of playlists displayed in our window.  Here, we call the remote iTunes
	app to obtain a list of all of the tracks in the selected playlist and then
	we display those track names in the track listing in the window.  */
- (void) clickNewPlaylist {

		/* get the name of the playlist that the user clicked on */
	NSString* playlistName;
	int shuffleSetting, repeatSetting;

		/* if we are currently viewing a list of tracks, delete that list */
	
		/* call the remote host to obtain a list of tracks in the named playlist. */
	playlistName = [self.playlistItems objectAtIndex:[playlists clickedRow]];
	self.tracklistItems = [self.myScript getTracksForPlaylist:playlistName];
		
		/* display the shuffle setting for the selected playlist */
	shuffleSetting = [self.myScript getShuffleForPlaylist:playlistName];
	if (shuffleSetting == 1) {
		[shufflebutton setImage:[self.imagesTable objectAtIndex:kShuffleOnImage]];
	} else {
		[shufflebutton setImage:[self.imagesTable objectAtIndex:kShuffleOffImage]];
	}
	repeatSetting = [self.myScript getRepeatForPlaylist:playlistName];
	[repeatbutton setImage:[self.imagesTable objectAtIndex:(kRepeatOffImage + repeatSetting)]];
				
		/* enable our repeat and shuffle buttons */
	[repeatbutton setEnabled:YES];
	[shufflebutton setEnabled:YES];
}


	/* clickTrackToPlay is called whenever a double click is received by the list
	of tracks displayed in our window.  Here, we call the remote iTunes
	app and ask it to play the selected track.  */
- (void) clickTrackToPlay {
	int playlistRow = [playlists selectedRow];
	int tracklistRow = [tracklist clickedRow];
	
		/* if there is a selection in both the playlist and tracks lists... */
	if ( playlistRow != -1 && tracklistRow != -1 ) {
			
			/* get the name of the selected playlist */
		NSString* playlistName = [self.playlistItems objectAtIndex:playlistRow];
		
			/* get the name of the selected track */
		NSString* trackName = [self.tracklistItems objectAtIndex:tracklistRow];
		
			/* ask the remote iTunes app to play the selected track. */
		[self.myScript playTrack:trackName fromPlaylist: playlistName];
		
			/* update our user interface to display the new status of the player */
		[self updatePlayerStatus];
	}
}


	/* playlistItems and setPlaylistItems are accessor methods for the playlistItems slot
	on our object. */
@synthesize playlistItems;


    /* tracklistItems and setTracklistItems are accessor methods for the tracklistItems slot
	on our object. */
@synthesize tracklistItems;

- (void)setTracklistItems:(NSArray *)newTracklistItems {
    if (tracklistItems != newTracklistItems) {
        [tracklistItems release];
        tracklistItems = [newTracklistItems copy];
			/* redraw the table to reflect the new items*/
		[tracklist reloadData];
    }
}


	/* gongSound and setGongSound are accessor methods for the gongSound slot
	on our object. */
@synthesize gongSound;


	/* imagesTable and setImagesTable are accessor methods for the imagesTable slot
	on our object. */
@synthesize imagesTable;


	/* The gong method is called when the user clicks on the gong button
	in the ui.  This method plays the gong sound and then it calls through
	to the AppleScript's GongCurrentTrack handler.  The GongCurrentTrack
	handler unchecks the track that is currently playing and moves the player
	on to the next track. */
- (IBAction)gong:(id)sender {
		/* play the gong sound */
	[self.gongSound play];
		/* call the GongCurrentTrack handler */
	[self.myScript gongCurrentTrack];
		/* update the UI */
	[self updatePlayerStatus];
}


	/* repeatsetting is called when the user clicks on the repeat button
	displayed in the window.  This routine cycles through the repeat settings
	for the remote player for the currently selected track.  */
- (IBAction)repeatsetting:(id)sender {

		/* get the index of the currently selected row */
	int playlistRow = [playlists selectedRow];
	
		/* if there is a playlist name selected in the list of playlists... */
	if ( playlistRow != -1 ) {
		
			/* get the name of the currently selected playlist */
		NSString* playlistName = [self.playlistItems objectAtIndex:playlistRow];
		int repeatSetting;
		
			/* call the GetPlaylistRepeat handler in the AppleScript to find out the current setting */
		repeatSetting = [self.myScript getRepeatForPlaylist: playlistName];
		
			/* there are three possible settings, increment to the next one using modulo arithmetic */
		repeatSetting = (repeatSetting + 1) % 3;
				
			/* call the SetPlaylistRepeat AppleScript handler to set the new repeat setting */
		[self.myScript setRepeat:repeatSetting forPlaylist:playlistName];
		
			/* update the button's image to display the new setting in the ui. */
		[repeatbutton setImage:[self.imagesTable objectAtIndex:(kRepeatOffImage + repeatSetting)]];
	}
}


	/* shufflesetting is called when the user clicks on the shuffle button.  In this routine
	we advance the shuffle setting for the currently selected playlist.   */
- (IBAction)shufflesetting:(id)sender {

		/* get the index of the currently selected playlist */
	int playlistRow = [playlists selectedRow];
	
		/* if there is a selected playlist... */
	if ( playlistRow != -1 ) {
		int shuffleSetting;
	
			/* get the name of the currently selected playlist */
		NSString* playlistName = [self.playlistItems objectAtIndex:playlistRow];
		
			/* call the AppleScript handler GetPlaylistShuffle to retrieve the current
			shuffle setting for the named playlist. */
		shuffleSetting = [self.myScript getShuffleForPlaylist:playlistName];
		
			/* increment the shuffle setting to the next position using module arithmetic. */
		shuffleSetting = (shuffleSetting + 1) % 2;
		
			/* call the AppleScript SetPlaylistShuffle handler to set the new shuffle setting. */
		[self.myScript setShuffle:shuffleSetting forPlaylist:playlistName];
		
			/* update the shuffle button's image to reflect the new setting */
		[shufflebutton setImage:[self.imagesTable objectAtIndex:(kShuffleOffImage+shuffleSetting)]];
	}
}


	/* adjustvolume: is called whenever the volume slider is activated by
	the user clicking the mouse.  Here, we call through to our AppleScript
	that in turn calls through to the remote iTunes app to set the volume.
	We have turned on continuous action calling in interface builder so this
	routine will be called continuously while the slider is being moved. */
- (IBAction)adjustvolume:(id)sender {
	
		/* Call the AppleScript SetRemoteVolume handler to change the volume setting */
	[self.myScript setRemoteVolume: [volumesetting intValue]];
	
}


	/* goback is called whenever the user clicks on the on the go back button. */
- (IBAction)goback:(id)sender {	
	
		/* call the GoToPreviousTrack AppleScript handler */
	[self.myScript goToPreviousTrack];
	
		/* update the ui to reflect the new player status. */
	[self updatePlayerStatus];
}


	/* goback is called whenever the user clicks on the on the skip ahead button. */
- (IBAction)goforward:(id)sender {
	
		/* call the GoToNextTrack AppleScript handler */
	[self.myScript goToNextTrack];
	
		/* update the ui to reflect the new player status. */
	[self updatePlayerStatus];
}


	/* playpause is called whenever the user clicks on the play button.  This routine
	calls through to the AppleScript to turn the remote player on or off. */
- (IBAction)playpause:(id)sender {
	BOOL nextPlayerState;
		
		/* call ReportRemotePlayerState to find out if the remote player is playing */
	RemotePlayerState* playerInfo = [self.myScript getRemotePlayerState];
		
		/* increment the player state to it's next position using modulo arithmetic */
	nextPlayerState = ! playerInfo.isPlaying;
		
		/* call the SwitchRemotePlayerState AppleScript handler to set the new player state */
	[self.myScript setRemotePlayerState: nextPlayerState];
		
		/* update the ui to reflect the new settings */
	[self updatePlayerStatus];
}


@end
