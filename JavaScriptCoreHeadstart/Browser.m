/*
     File: Browser.m 
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


#import <Cocoa/Cocoa.h>
#import "Browser.h"
#import "Controller.h"
#import "NSStringExtras.h"





	/* getter callback for the 'progress' property */
static JSValueRef browserProgress( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return true if the progress bar is visible */
	return JSValueMakeBoolean( ctx, ( [cself.progressBar isHidden] ? false : true ) );
}



	/* setter callback for the 'progress' property */
static bool browserSetProgress( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef value, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	bool theResult = false;
	
		/* verify that the value is of the proper type */
	if ( JSValueIsBoolean( ctx, value ) ) {
	
			/* start/stop the progress bar - the progress
			bar has been set to hide itself when it is not
			animating.  */
		if ( JSValueToBoolean( ctx, value ) ) {
			[cself.progressBar startAnimation: cself];
		} else {
			[cself.progressBar stopAnimation: cself];
		}
		
			/* return success */
		theResult = true;
	}
	return theResult;
}



	/* getter callback for the 'loading' property */
static JSValueRef browserLoading( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return true if we are in the midst of loading a page */
	return JSValueMakeBoolean( ctx, ( cself.isLoadingPage ? true : false ) );
}



	/* getter callback for the 'message' property */
static JSValueRef browserMessage( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return the text currently displayed at the bottom of the window */
	return JSValueMakeString( ctx, [[cself.messageText stringValue] jsStringValue] );
}



	/* setter callback for the 'message' property */
static bool browserSetMessage( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef value, JSValueRef* exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	bool theResult = false;
	
		/* verify that the new value is of the proper type */
	if ( JSValueIsString( ctx, value ) ) {
	
			/* display the new value in the message field at the bottom of the window */
		[cself.messageText setStringValue: [NSString stringWithJSValue: value fromContext: ctx]];
		
			/* return success */
		theResult = true;
	}
	return theResult;
}



	/* getter callback for the 'title' property */
static JSValueRef browserTitle( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return the main window's title */
	return JSValueMakeString( ctx, [[cself.browserWindow title] jsStringValue] );
}



	/* setter callback for the 'title' property */
static bool browserSetTitle( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef value, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	bool theResult = false;
	
		/* verify that the new value is of the proper type */
	if ( JSValueIsString( ctx, value ) ) {
	
			/* set the main browser window's title */
		[cself.browserWindow setTitle: [NSString stringWithJSValue: value fromContext: ctx]];
		
			/* return success */
		theResult = true;
	}
	return theResult;
}




	/* getter callback for the 'url' property */
static JSValueRef browserURL( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return the text from the url field at the top of the
		browser window */
	return JSValueMakeString( ctx, [[cself.theURL stringValue] jsStringValue] );
}


	/* setter callback for the 'url' property */
static bool browserSetURL( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef value, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	bool theResult = false;

		/* verify that the new value is of the proper type */
	if ( JSValueIsString( ctx, value ) ) {

			/* set the text from the url field at the top of the
			browser window */
		[cself.theURL setStringValue: [NSString stringWithJSValue: value fromContext: ctx] ];
		
			/* return success */
		theResult = true;
	}
	return theResult;
}


	/* getter callback for the 'backlink' property */
static JSValueRef browserBackLink( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	JSValueRef theResult = NULL;
	
		/* if there is a back item in the WebView's history list,
		then return the url for that item, otherwise return null. */
	WebHistoryItem *backItem = [[cself.theWebView backForwardList] backItem ];
	if ( backItem ) {
		theResult = JSValueMakeString( ctx, [[backItem URLString] jsStringValue] );
	} else {
		theResult = JSValueMakeNull( ctx );
	}
	return theResult;
}



	/* getter callback for the 'forwardlink' property */
static JSValueRef browserForwardLink( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	JSValueRef theResult = NULL;

		/* if there is a forward item in the WebView's history list,
		then return the url for that item, otherwise return null. */
	WebHistoryItem *forwardItem = [[cself.theWebView backForwardList] forwardItem ];
	if ( forwardItem ) {
		theResult = JSValueMakeString( ctx, [[forwardItem URLString] jsStringValue] );
	} else {
		theResult = JSValueMakeNull( ctx );
	}
	return theResult;
}



	/* browserStaticValues contains the list of value properties
	defined for the browser class.  Each entry in the list includes the
	property name, a pointer to a getter callback (or NULL), a pointer
	to a setter callback (or NULL),  and some attribute flags.  Getters
	and setters for the property values are defined above.  
	
	Note we have set the attributes to both kJSPropertyAttributeDontDelete
	and kJSPropertyAttributeReadOnly.  These attributes are to prevent
	wayward scripts from removing or, in some cases, changing these values. */

static JSStaticValue browserStaticValues[] = {
	{ "progress", browserProgress, browserSetProgress, kJSPropertyAttributeDontDelete },
	{ "loading", browserLoading, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "message", browserMessage, browserSetMessage, kJSPropertyAttributeDontDelete },
	{ "title", browserTitle, browserSetTitle, kJSPropertyAttributeDontDelete },
	{ "url", browserURL, browserSetURL, kJSPropertyAttributeDontDelete },
	{ "backlink", browserBackLink, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "forwardlink", browserForwardLink, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ 0, 0, 0, 0 }
};






	/* function callback for the 'load' property */
static JSValueRef browserLoad( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount,
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	
		/* if there is at least one argument to the function and it is a string... */
	if ( ( argumentCount >= 1 ) && JSValueIsString( ctx, arguments[0] ) ) {
	
			/* convert the first argument into a url and ask the WebView
			to load the url. */
		[[cself.theWebView mainFrame]
			loadRequest: [NSURLRequest requestWithURL:
				[NSURL URLWithString:
					[NSString stringWithJSValue: arguments[0] fromContext: ctx]]]];
	}
		/* return null to JavaScript */
	return JSValueMakeNull( ctx );
}




	/* function callback for the 'back' property */
static JSValueRef browserBack( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount,
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );

		/* add all of the parameters into an NSArray as strings */
	[cself.theWebView goBack];
	
		/* return null to JavaScript */
	return JSValueMakeNull( ctx );
}




	/* function callback for the 'forward' property */
static JSValueRef browserForward( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount,
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );

		/* add all of the parameters into an NSArray as strings */
	[cself.theWebView goForward];
	
		/* return null to JavaScript */
	return JSValueMakeNull( ctx );
}



	/* function callback for the 'eval' property */
static JSValueRef browserEvaluateScript( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount,
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	JSValueRef theResult = NULL;
	static int bEvalLevel = 0; /* guard against infinite recursion */
	const int bEvalMax = 20;
	
		/* add all of the parameters into an NSArray as strings */
	if ( ( argumentCount >= 1 ) && JSValueIsString( ctx, arguments[0] ) && ( bEvalLevel < bEvalMax ) ) {
		
			/* increment recursion guard counter */
		bEvalLevel++;
		
			/* get the argument as a string */
		JSStringRef theScript = JSValueToStringCopy( ctx, arguments[0], NULL );
		if ( theScript != NULL ) {
				
				/* get the argument as a string */
			JSGlobalContextRef webViewContext = [[cself.theWebView mainFrame] globalContext];
			
				/* evaluate the string in the browser's context */
			JSValueRef result = JSEvaluateScript( webViewContext, theScript, NULL, NULL, 0, NULL );
			
				/* copy the result over to the calling context. */
			if ( result != NULL ) {
			
					/* if we're calling from the webView's context, simply return the
					result.  It's okay to do so because the result object is already
					in the correct context. */
				if ( ctx == webViewContext ) {
					theResult = result;
				} else {
						/* value reference for returned by the script is in a different
						context than the calling context so we need to transfer it over
						to the caller's context  */
					if ( JSValueIsString( webViewContext, result ) ) {
						JSStringRef stringResult = JSValueToStringCopy( webViewContext, result, NULL );
						if ( stringResult != NULL ) {
							theResult = JSValueMakeString( ctx, stringResult );
							JSStringRelease( stringResult );
						}
					} else if ( JSValueIsNumber( webViewContext, result ) ) {
						theResult = JSValueMakeNumber( ctx, JSValueToNumber( webViewContext, result, NULL ) );
					} else if ( JSValueIsBoolean( webViewContext, result ) ) {
						theResult = JSValueMakeBoolean( ctx, JSValueToBoolean( webViewContext, result ) );
					} else if ( JSValueIsNull( webViewContext, result ) ) {
						theResult = JSValueMakeNull( ctx );
					} else {
						theResult = JSValueMakeUndefined( ctx );
					}
				}
			}
			JSStringRelease( theScript );
		}
			/* decrement recursion guard counter */
		--bEvalLevel;
	}
	
		/* return the result, or null if none found */
	return ( ( theResult != NULL ) ? theResult : JSValueMakeNull( ctx ) );
}



	/* browserStaticFunctions contains the list of function properties
	defined for the browser class.  Each entry in the list includes the
	property name, a pointer to the associated callback (defined above),
	and some attribute flags.  It is a zero terminated list with the last
	entry set to all zeros.
	
	Note we have set the attributes to both kJSPropertyAttributeDontDelete
	and kJSPropertyAttributeReadOnly.  These attributes are to prevent
	wayward scripts from changing or removing these values. */
	
static JSStaticFunction browserStaticFunctions[] = {
	{ "load", browserLoad, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "back", browserBack, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "forward", browserForward, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "eval", browserEvaluateScript, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ 0, 0, 0 }
};




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
JSClassRef BrowserClass( void ) {

		/* we only need one definition for this class, so we cache the
		result between calls. */
	static JSClassRef browserClass = NULL;
	if ( browserClass == NULL ) {
	
			/* initialize the class definition structure.  It contains
			a lot of procedure pointers, so this step is very important. */
		JSClassDefinition browserClassDefinition = kJSClassDefinitionEmpty;
		
			/* set the pointers to our static values and functions */
		browserClassDefinition.staticValues = browserStaticValues;
		browserClassDefinition.staticFunctions = browserStaticFunctions;
		
			/* create the class */
		browserClass = JSClassCreate( &browserClassDefinition );
    }
    return browserClass;
}
