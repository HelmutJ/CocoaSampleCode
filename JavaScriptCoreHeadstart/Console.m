/*
     File: Console.m 
 Abstract: Console javascript class.  This
 file contains only one function that returns a reference to the JavaScript
 class definition for the console object.  The console object allows
 JavaScripts running in either the WebView's JavaScript context or in
 the Controller's JavaScript context to access the window displaying
 the console log.  This class also allows scripts running in either context
 to run JavaScripts in the main Controller's JavaScript Context. 
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
#import "Console.h"
#import "Controller.h"
#import "NSStringExtras.h"






	/* getter callback for the 'visible' property */
static JSValueRef consoleVisible( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return true if the console window is visible */
	return JSValueMakeBoolean( ctx, ([cself.consoleWindow isVisible] ? true : false) );
}



	/* getter callback for the 'front' property */
static JSValueRef consoleFront( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return true if the console window is the front and active window */
	return JSValueMakeBoolean( ctx, ([cself.consoleWindow isKeyWindow] ? true : false) );
}



	/* getter callback for the 'text' property */
static JSValueRef consoleText( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* copy the console log text in the console window and return it to JavaScript as a string. */
	return JSValueMakeString( ctx, [[[cself.scriptText textStorage] string] jsStringValue] );
}



	/* setter callback for the 'text' property */
static bool consoleSetText( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef value, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	bool theResult = false;
	
		/* verify that the value provided is the proper type */
	if ( JSValueIsString( ctx, value ) ) {
	
			/* replace all of the text in the console log with the new string */
		NSUInteger p = [[[cself.consoleText textStorage ] string ] length ];
		[cself.consoleText setSelectedRange: NSMakeRange( 0, p ) ];
		[cself.consoleText insertText: [NSString stringWithJSValue: value fromContext: ctx]];
		
			/* return success */
		theResult = true;
	}
	return theResult;
}



	/* getter callback for the 'script' property */
static JSValueRef consoleScript( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );

		/* copy the script text in the console window and return it to JavaScript as a string. */
	return JSValueMakeString( ctx, [[[cself.scriptText textStorage] string] jsStringValue] );
}



	/* setter callback for the 'script' property */
static bool consoleSetScript( JSContextRef ctx, JSObjectRef object, 
			JSStringRef propertyName, JSValueRef value, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	bool theResult = false;
	
		/* verify that the value provided is the proper type */
	if ( JSValueIsString( ctx, value ) ) {
	
			/* replace all of the text in the console's script field with the new string */
		NSUInteger p = [[[cself.scriptText textStorage ] string ] length ];
		[cself.scriptText setSelectedRange: NSMakeRange( p, p ) ];
		[cself.scriptText insertText: [NSString stringWithJSValue: value fromContext: ctx]];
		
			/* return success */
		theResult = true;
	}
	return theResult;
}



	/* consoleStaticValues contains the list of value properties
	defined for the console class.  Each entry in the list includes the
	property name, a pointer to a getter callback (or NULL), a pointer
	to a setter callback (or NULL),  and some attribute flags.  Getters
	and setters for the property values are defined above.
	
	Note we have set the attributes to both kJSPropertyAttributeDontDelete
	and kJSPropertyAttributeReadOnly.  These attributes are to prevent
	wayward scripts from changing or removing these values. */

static JSStaticValue consoleStaticValues[] = {
	{ "visible", consoleVisible, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "front", consoleFront, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "text", consoleText, consoleSetText, kJSPropertyAttributeDontDelete },
	{ "script", consoleScript, consoleSetScript, kJSPropertyAttributeDontDelete },
	{ 0, 0, 0, 0 }
};



	/* function callback for the 'show' property */
static JSValueRef consoleShow( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount, 
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	
		/* show the console window and make it the front window. */
	[cself.consoleWindow makeKeyAndOrderFront: nil];
	
		/* return null to the JavaScript */
	return JSValueMakeNull( ctx );
}



	/* function callback for the 'hide' property */
static JSValueRef consoleHide( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount,
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	
		/* close the pageload window */
	[cself.consoleWindow close];
	
		/* return null to the JavaScript */
	return JSValueMakeNull( ctx );
}



	/* function callback for the 'log' property */
static JSValueRef consoleLog( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount,
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	
		/* if we have at least one argument... */
	if ( argumentCount >= 1 ) {
	
			/* convert the first parameter into a NSString */
		NSString *theMessage = [NSString stringWithJSValue:arguments[0] fromContext: ctx];
		
			/* if there is a message, display it */
		if ( theMessage != NULL ) {
		
				/* if we have a result string to display, display it at the bottom of the window
				in the result text field.  */
			[cself appendMessageToConsole: theMessage];
		}
	}
	
		/* return null to JavaScript */
	return JSValueMakeNull( ctx );
}



	/* function callback for the 'eval' property */
static JSValueRef consoleEvalScript( JSContextRef ctx, JSObjectRef function,
			JSObjectRef thisObject, size_t argumentCount,
			const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	JSValueRef theResult = NULL;
	static int cEvalLevel = 0; /* guard against infinite recursion */
	const int cEvalMax = 20;
	
		/* add all of the parameters into an NSArray as strings */
	if ( ( argumentCount >= 1 ) && JSValueIsString( ctx, arguments[0] ) && ( cEvalLevel < cEvalMax ) ) {
			
			/* increment recursion guard counter */
		cEvalLevel++;
		
			/* get the argument as a string */
		JSStringRef theScript = JSValueToStringCopy( ctx, arguments[0], NULL );
		if ( theScript != NULL ) {
							
				/* evaluate the string in the Controller's context */
			JSValueRef result = JSEvaluateScript( cself.mainJSContext, theScript, NULL, NULL, 0, NULL );
			
				/* copy the result over to the calling context. */
			if ( result != NULL ) {
			
					/* if we're calling from the Controller's context, simply return the
					result.  It's okay to do so because the result object is already
					in the correct context. */
				if ( ctx == cself.mainJSContext ) {
				
					theResult = result;
					
				} else {
						/* value reference for returned by the script is in a different
						context than the calling context so we need to transfer it over
						to the caller's context. */
					if ( JSValueIsString( cself.mainJSContext, result ) ) {
						JSStringRef stringResult = JSValueToStringCopy( cself.mainJSContext, result, NULL );
						if ( stringResult != NULL ) {
							theResult = JSValueMakeString( ctx, stringResult );
							JSStringRelease( stringResult );
						}
					} else if ( JSValueIsNumber( cself.mainJSContext, result ) ) {
						theResult = JSValueMakeNumber( ctx, JSValueToNumber( cself.mainJSContext, result, NULL ) );
					} else if ( JSValueIsBoolean( cself.mainJSContext, result ) ) {
						theResult = JSValueMakeBoolean( ctx, JSValueToBoolean(cself.mainJSContext, result ));
					} else if ( JSValueIsNull( cself.mainJSContext, result ) ) {
						theResult = JSValueMakeNull( ctx );
					} else {
						theResult = JSValueMakeUndefined( ctx );
					}
				}
			}
			JSStringRelease( theScript );
		}
		
			/* decrement the recursion guard counter */
		--cEvalLevel;
		
	}
		/* return the result, or null if none found */
	return ( ( theResult != NULL ) ? theResult : JSValueMakeNull( ctx ) );
}




	/* consoleStaticFunctions contains the list of function properties
	defined for the console class.  Each entry in the list includes the
	property name, a pointer to the associated callback (defined above),
	and some attribute flags.  It is a zero terminated list with the last
	entry set to all zeros.  
	
	Note we have set the attributes to both kJSPropertyAttributeDontDelete
	and kJSPropertyAttributeReadOnly.  These attributes are to prevent
	wayward scripts from changing or removing these values. */

static JSStaticFunction consoleStaticFunctions[] = {
	{ "show", consoleShow, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "hide", consoleHide, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "log", consoleLog, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "eval", consoleEvalScript, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ 0, 0, 0 }
};




	/* ConsoleClass returns a JavaScriptCore class reference that you can use
	for creating objects manipulating the console window.  This class also
	contains methods for executing scripts in the main Controller's JavaScript
	context.
	
	Objects defined by this class have the following properties
	and methods that can be accessed from JavaScripts in both the
	Controller's JavaScript and from inside of scripts running
	in the WebView displayed in the browser window.
	
	properties:

		visible (read only) - true if the pageload window is visible
		front (read only) - true if the pageload window is the front window
		script (read/write) - the console log text displayed in the window
		script (read/write) - the script text displayed in the window

	methods:
	
		show() - display the pageload script window and make it the front window.
		hide() - hide the pageload script window.
		log( string(s) ) - add the strings to the console text as
					a single new line.
		eval( string ) - evaluate the javascript in the string in the
				main Controller's JavaScript context.  Returns the value
				returned by the script (strings, numbers, and booleans only).

	*/
JSClassRef ConsoleClass( void ) {

		/* we only need one definition for this class, so we cache the
		result between calls. */
	static JSClassRef consoleClass = NULL;
	if ( consoleClass == NULL ) {
	
			/* initialize the class definition structure.  It contains
			a lot of procedure pointers, so this step is very important. */
		JSClassDefinition consoleClassDefinition = kJSClassDefinitionEmpty;
		
			/* set the pointers to our static values and functions */
		consoleClassDefinition.staticValues = consoleStaticValues;
		consoleClassDefinition.staticFunctions = consoleStaticFunctions;
		
			/* create the class */
		consoleClass = JSClassCreate( &consoleClassDefinition );
    }
    return consoleClass;
}
