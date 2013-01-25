### MyMediaPlayList ###

===========================================================================
DESCRIPTION:

Implements a movie playlist application using QTKit on Mac OS X 10.6. Users can open any number of movies to create a movie playlist, and the program will automatically play these movies in sequence. Movie playlists can be saved to disk, and the program allows copy and paste operations between different playlists. A movie scrubber control gives you the ability to play a movie starting at any given point in the movie timeline. There is also a search field to locate any movie item in the playlist.

A QTKit QTMovie object is created for each movie in the playlist. These QTMovie objects are instantiated with the QTMovie movieWithAttributes method using the QTMovieOpenForPlaybackAttribute flag. This flag specifies the movie will be used for playback only (no editing), to use the QuickTime X media architecture for efficient, high-performance playback of the media, and to open the movie asynchronously. The program will handle the different movie load states as the movie loads.

===========================================================================
BUILD REQUIREMENTS:

Mac OS X 10.6

===========================================================================
RUNTIME REQUIREMENTS:

Mac OS X 10.6

===========================================================================
PACKAGING LIST:

MyDocument.h
MyDocument.m
- A NSDocument subclass. Each document contains a movie playlist, which is simply a list of movies to be played in sequence. A PlaylistItem object is created for each movie in the play list. Each PlaylistItem contains a QTMovie object for the movie to be played.

PlaylistItem.h
PlaylistItem.m
- A PlaylistItem object represents a single movie in a list of movies that are to be played. A PlaylistItem object conforms to the NSCoding protocol to allow a playlist to be written to a file on disk. It also conforms to the NSPasteboardWriting and NSPasteboardReading protocols to enable copy and paste operations between different playlists.

MyDocument.xib
- The nib file that implements the NSDocument subclass

MainMenu.xib
- The nib file containing the main window.



===========================================================================
CHANGES FROM PREVIOUS VERSIONS:

Version 1.1
- Update for Xcode 4

Version 1.0
- First version.

===========================================================================
Copyright (C) 2010 - 2011 Apple Inc. All rights reserved.
