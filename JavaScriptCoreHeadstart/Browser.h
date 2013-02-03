/*
     File: Browser.h
 Abstract: Browser JavaScript class.  This
 file contains only one function that returns a reference to the JavaScript
 class definition for the browser object.  The browser object allows
 JavaScripts running in either the WebView's JavaScript context or in
 the Controller's JavaScript context to access the main browser
 window and items it contains.  This class also allows scripts
 running in either context to run JavaScripts in the main WebView's
 JavaScript JavaScript Context.
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

#import <JavaScriptCore/JavaScriptCore.h>

	/* BrowserClass returns a JavaScriptCore class reference that you can use
	for creating objects manipulating the browser window.  This class also
	contains methods for executing scripts in the WebView's JavaScript
	context.
	
	Objects defined by this class have the following properties
	and methods that can be accessed from JavaScripts in both the
	Controller's JavaScript and from inside of scripts running
	in the WebView displayed in the browser window.
	
	properties:

		progress (boolean, read/write) - set to true to display the animated progress bar
		loading (boolean, read only) - true while loading a page
		message (string, read/write) - status message displayed at the bottom of the window
		title (string, read/write) - the window's title
		url (string, read/write) - the contents of the url field
		backlink (string or null, read only) - url from the history to the next page back (if there is one)
		forwardlink (string, read only) - url from the history to the next page forward (if there is one)

	methods:
	
		load( url ) - load the url in the WebView
		back() - if there is a back link in the history, go to that link.
		forward() - if there is a forward link in the history, go to that link.
		eval( string ) - evaluate the javascript in the string in the
				WebView's JavaScript context.    Returns the value
				returned by the script (strings, numbers, and booleans only).
	*/

JSClassRef BrowserClass( void );



