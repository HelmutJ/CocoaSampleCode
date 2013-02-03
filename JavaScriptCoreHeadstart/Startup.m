/*
     File: Startup.m 
 Abstract: Startup javascript class.  This
 file contains only one function that returns a reference to the JavaScript
 class definition for the startup object.  The startup object allows
 JavaScripts running in either the WebView's JavaScript context or in
 the Controller's JavaScript context to access the window displaying
 the startup script. 
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
#import "Startup.h"
#import "Controller.h"
#import "NSStringExtras.h"






	/* getter callback for the 'visible' property */
static JSValueRef startupVisible( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return true if the startup window is visible */
	return JSValueMakeBoolean( ctx, ([cself.startupWindow isVisible] ? true : false) );
}



	/* getter callback for the 'front' property */
static JSValueRef startupFront( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* return true if the startup window is the front and active window */
	return JSValueMakeBoolean( ctx, ([cself.startupWindow isKeyWindow] ? true : false) );
}



	/* getter callback for the 'script' property */
static JSValueRef startupScript( JSContextRef ctx, JSObjectRef object,
			JSStringRef propertyName, JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( object );
	
		/* copy the script text in the startup window and return it to JavaScript as a string. */
	return JSValueMakeString( ctx, [[[cself.startupScriptText textStorage] string] jsStringValue] );
}




	/* startupStaticValues contains the list of value properties
	defined for the startup class.  Each entry in the list includes the
	property name, a pointer to a getter callback (or NULL), a pointer
	to a setter callback (or NULL),  and some attribute flags.  Getters
	for the property values are defined above.  No setters have been
	provided for any of the properties.
	
	Note we have set the attributes to both kJSPropertyAttributeDontDelete
	and kJSPropertyAttributeReadOnly.  These attributes are to prevent
	wayward scripts from changing or removing these values. */

static JSStaticValue startupStaticValues[] = {
	{ "visible", startupVisible, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "front", startupFront, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "script", startupScript, NULL, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ 0, 0, 0, 0 }
};



	/* function callback for the 'show' property */
static JSValueRef startupShow( JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
			size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	
		/* show the startup window and make it the front window. */
	[cself.startupWindow makeKeyAndOrderFront: cself];
	
		/* return null to the JavaScript */
	return JSValueMakeNull( ctx );
}


	/* function callback for the 'hide' property */
static JSValueRef startupHide( JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
			size_t argumentCount, const JSValueRef arguments[], JSValueRef *exception ) {
	
		/* a reference to the Controller object was stored in
		the private data field for the object when it was created. */
	Controller *cself = (Controller *) JSObjectGetPrivate( thisObject );
	
		/* close the startup window */
	[cself.startupWindow close];
	
		/* return null to the JavaScript */
	return JSValueMakeNull( ctx );
}



	/* startupStaticFunctions contains the list of function properties
	defined for the startup class.  Each entry in the list includes the
	property name, a pointer to the associated callback (defined above),
	and some attribute flags.  It is a zero terminated list with the last
	entry set to all zeros.
	
	Note we have set the attributes to both kJSPropertyAttributeDontDelete
	and kJSPropertyAttributeReadOnly.  These attributes are to prevent
	wayward scripts from changing or removing these values. */

static JSStaticFunction startupStaticFunctions[] = {
	{ "show", startupShow, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ "hide", startupHide, kJSPropertyAttributeDontDelete | kJSPropertyAttributeReadOnly },
	{ 0, 0, 0 }
};



	/* StartupClass returns a JavaScriptCore class reference that you can use
	for creating objects manipulating the startup script window.
	
	Objects defined by this class have the following properties
	and methods that can be accessed from JavaScripts in both the
	Controller's JavaScript and from inside of scripts running
	in the WebView displayed in the browser window.
	
	properties:
	
		visible (read only) - true if the pageload window is visible
		front (read only) - true if the pageload window is the front window
		script (read only) - the page load script text

	methods:
	
		show() - display the pageload script window and make it the front window.
		hide() - hide the pageload script window.

	*/

JSClassRef StartupClass( void ) {

		/* we only need one definition for this class, so we cache the
		result between calls. */
	static JSClassRef startupClass = NULL;
	if ( startupClass == NULL ) {
	
			/* initialize the class definition structure.  It contains
			a lot of procedure pointers, so this step is very important. */
		JSClassDefinition startupClassDefinition = kJSClassDefinitionEmpty;
		
			/* set the pointers to our static values and functions */
		startupClassDefinition.staticValues = startupStaticValues;
		startupClassDefinition.staticFunctions = startupStaticFunctions;
		
			/* create the class */
		startupClass = JSClassCreate( &startupClassDefinition );
    }
    return startupClass;
}
