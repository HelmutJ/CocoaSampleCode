/*
     File: JSWrappers.m 
 Abstract: Conveience class used to gather
 commonly called sequences into some simple class methods for calling
 the JavaScriptCore Framework.  The methods defined in this class
 are used again and again throughout the sample.  
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

#import "JSWrappers.h"
#import "NSStringExtras.h"




@implementation JSWrappers

@synthesize jsContext;




- (id)initWithContext:(JSGlobalContextRef)theContext {
	if ((self = [super init]) != nil) {
	
		self.jsContext = theContext;

	}
	return self;
}



- (void)dealloc {

	self.jsContext = NULL;

	[super dealloc];
}





	/* -vsCallJSFunction:withParameters: is much like the vsprintf function in that
	it receives a va_list rather than a variable length argument list.  This
	is a simple utility for calling JavaScript functions in a JavaScriptContext
	that is called by the other call*JSFunction methods in this file to do the
	actual work.  The caller provides a function name and the parameter va_list,
	and -vsCallJSFunction:withParameters: uses those to call the function in the
	JavaScriptCore context.  Only NSString and NSNumber values can be provided
	as parameters.  The result returned is the same as the value returned by
	the function,  or NULL if an error occured.  */
- (JSValueRef)vsCallJSFunction:(NSString *)name withArg:(id)firstParameter andArgList:(va_list)args {

		/* default result */
	JSValueRef theResult = NULL;
	
			/* try to find the named function defined as a property on the global object */
	JSStringRef functionNameString = [name jsStringValue];
	if ( functionNameString != NULL ) {

			/* retrieve the function object from the global object. */
		JSValueRef jsFunctionObject =
				JSObjectGetProperty( self.jsContext,
						JSContextGetGlobalObject( self.jsContext ), functionNameString, NULL );
				
			/* if we found a property, verify that it's a function */
		if ( ( jsFunctionObject != NULL ) && JSValueIsObject( self.jsContext, jsFunctionObject ) ) {
			const size_t kMaxArgCount = 20;
			id nthID;
			BOOL argsOK = YES;
			size_t argumentCount = 0;
			JSValueRef arguments[kMaxArgCount];
			
				/* convert the function reference to a function object */
			JSObjectRef jsFunction = JSValueToObject( self.jsContext, jsFunctionObject, NULL );
				
				/* index through the parameters until we find a nil one,
				or exceed our maximu argument count */
			for ( nthID = firstParameter; 
				argsOK && ( nthID != nil ) && ( argumentCount < kMaxArgCount );
				nthID = va_arg( args, id ) ) {
			
				if ( [nthID isKindOfClass: [NSNumber class]] ) {
				
					arguments[argumentCount++] = JSValueMakeNumber( self.jsContext, [nthID doubleValue] );
							
				} else if ( [nthID isKindOfClass: [NSString class]] ) {
				
					JSStringRef argString = [nthID jsStringValue];
					if ( argString != NULL ) {
						arguments[argumentCount++] = 
								JSValueMakeString( self.jsContext, argString );
						JSStringRelease( argString );
					} else {
						argsOK = NO;
					}
				} else {
				
					NSLog(@"bad parameter type for item %lu (%@) in vsCallJSFunction:withArg:andArgList:",
						argumentCount, nthID);
					argsOK = NO; /* unknown parameter type */
				}
			}
				/* call through to the function */
			if ( argsOK ) {
				theResult = JSObjectCallAsFunction(self.jsContext, jsFunction,
										NULL, argumentCount, arguments, NULL);
			}
		}
				
		JSStringRelease( functionNameString );
	}
	return theResult;
}

		
		
	/* -callJSFunction:withParameters: is a simple utility for calling JavaScript
	functions in a JavaScriptContext.  The caller provides a function
	name and a nil terminated list of parameters, and callJSFunction
	uses those to call the function in the JavaScriptCore context.  Only
	NSString and NSNumber values can be provided as parameters.  The
	result returned is the same as the value returned by the function,
	or NULL if an error occured.  */
- (JSValueRef)callJSFunction:(NSString *)name withParameters:(id)firstParameter,... {
	JSValueRef theResult = NULL;
	va_list args;

	va_start( args, firstParameter );
	theResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

	return theResult;
}



	/* -callBooleanJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a BOOL result.  It will return NO if the function is not
	defined in the context or if an error occurs. */
- (BOOL)callBooleanJSFunction:(NSString *)name withParameters:(id)firstParameter,... {
	BOOL theResult;
	va_list args;

		/* call the function */
	va_start( args, firstParameter );
	JSValueRef functionResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

		/* convert the result, if there is one, into the objective-c type */
	if ( ( functionResult != NULL ) && JSValueIsBoolean( self.jsContext, functionResult ) ) {
		 theResult = ( JSValueToBoolean(self.jsContext, functionResult ) ? YES : NO );
	} else {
		theResult = NO;
	}
	return theResult;
}



	/* -callNumericJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a NSNumber * result.  It will return nil if the function is not
	defined in the context, if the result returned by the function cannot be converted
	into a number, or if an error occurs. */
- (NSNumber *)callNumericJSFunction:(NSString*)name withParameters:(id)firstParameter,... {
	NSNumber *theResult;
	va_list args;

		/* call the function */
	va_start( args, firstParameter );
	JSValueRef functionResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

		/* convert the result, if there is one, into the objective-c type */
	if ( ( functionResult != NULL ) && JSValueIsNumber( self.jsContext, functionResult ) ) {
		 theResult = [NSNumber numberWithDouble: JSValueToNumber( self.jsContext, functionResult, NULL )];
	} else {
		theResult = nil;
	}
	return theResult;
}



	/* -callStringJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a NSNumber * result.  It will return nil if the function is not
	defined in the context, if the result returned by the function cannot be converted
	into a string,  or if an error occurs. */
- (NSString *)callStringJSFunction:(NSString *)name withParameters:(id)firstParameter,... {
	NSString *theResult = nil;
	va_list args;

		/* call the function */
	va_start( args, firstParameter );
	JSValueRef functionResult = [self vsCallJSFunction: name withArg: firstParameter andArgList: args];
	va_end( args );

		/* convert the result, if there is one, into the objective-c type */
	if ( functionResult != NULL ) {
	
			/* attempt to convert the result into a NSString */
		theResult = [NSString stringWithJSValue:functionResult fromContext: self.jsContext];
	}
	
	return theResult;
}




	/* -addGlobalObject:ofClass:withPrivateData: adds an object of the given class 
	and name to the global object of the JavaScriptContext.  After this call, scripts
	running in the context will be able to access the object using the name. */
- (void)addGlobalObject:(NSString *)objectName ofClass:(JSClassRef)theClass
			withPrivateData:(void *)theData {
			
		/* create a new object of the given class */
	JSObjectRef theObject = JSObjectMake( self.jsContext, theClass, theData );
	if ( theObject != NULL ) {
			
			/* protect the value so it isn't eligible for garbage collection */
		JSValueProtect( self.jsContext, theObject );
		
			/* convert the name to a JavaScript string */
		JSStringRef objectJSName = [objectName jsStringValue];
		if ( objectJSName != NULL ) {
		
				/* add the object as a property of the context's global object */
			JSObjectSetProperty( self.jsContext, JSContextGetGlobalObject( self.jsContext ),
					objectJSName, theObject, kJSPropertyAttributeReadOnly, NULL );
			
				/* done with our reference to the name */
			JSStringRelease( objectJSName );
		}
	}
}



	/* -addGlobalStringProperty:withValue: adds a string with the given name to the
	global object of the JavaScriptContext.  After this call, scripts running in
	the context will be able to access the string using the name. */
- (void)addGlobalStringProperty:(NSString *)name withValue:(NSString *)theValue {

		/* convert the name to a JavaScript string */
	JSStringRef propertyName = [name jsStringValue];
	if ( propertyName != NULL ) {
	
			/* convert the property value into a JavaScript string */
		JSStringRef propertyValue = [theValue jsStringValue];
		if ( propertyValue != NULL ) {
		
				/* copy the property value into the JavaScript context */
			JSValueRef valueInContext = JSValueMakeString( self.jsContext, propertyValue );
			if ( valueInContext != NULL ) {
			
					/* add the property into the context's global object */
				JSObjectSetProperty( self.jsContext, JSContextGetGlobalObject( self.jsContext ),
						propertyName, valueInContext, kJSPropertyAttributeReadOnly, NULL );
			}
				/* done with our reference to the property value */
			JSStringRelease( propertyValue );
		}
			/* done with our reference to the property name */
		JSStringRelease( propertyName );
	}
}



	/* -addGlobalFunctionProperty:withCallback: adds a function with the given name to the
	global object of the JavaScriptContext.  After this call, scripts running in
	the context will be able to call the function using the name. */
- (void)addGlobalFunctionProperty:(NSString *)name
		withCallback:(JSObjectCallAsFunctionCallback)theFunction {
		
		/* convert the name to a JavaScript string */
	JSStringRef functionName = [name jsStringValue];
	if ( functionName != NULL ) {
			
			/* create a function object in the context with the function pointer. */
		JSObjectRef functionObject =
			JSObjectMakeFunctionWithCallback( self.jsContext, functionName, theFunction );
		if ( functionObject != NULL ) {
		
				/* add the function object as a property of the global object */
			JSObjectSetProperty( self.jsContext, JSContextGetGlobalObject( self.jsContext ),
				functionName, functionObject, kJSPropertyAttributeReadOnly, NULL );
		}
			/* done with our reference to the function name */
		JSStringRelease( functionName );
	}
}



	/* -evaluateJavaScript: evaluates a string containing a JavaScript in the
	JavaScriptCore context and returns the result as a string.  If an error
	occurs or the result returned by the script cannot be converted into a 
	string, then nil is returned. */
- (NSString *)evaluateJavaScript:(NSString *)theJavaScript {

	NSString *resultString = nil;
	
		/* coerce the contents of the script edit text field in the window into
		a string inside of the JavaScript context. */
	JSStringRef scriptJS = [theJavaScript jsStringValue];
	if ( scriptJS != NULL ) {
		
			/* evaluate the string as a JavaScript inside of the JavaScript context. */
		JSValueRef result = JSEvaluateScript( self.jsContext, scriptJS, NULL, NULL, 0, NULL );
		if ( result != NULL) {
		
				/* attempt to convert the result into a NSString */
			resultString = [NSString stringWithJSValue:result fromContext: self.jsContext];
					
		}
			/* done with our reference to the script string */
		JSStringRelease( scriptJS );
	}
	return resultString;
}





@end
