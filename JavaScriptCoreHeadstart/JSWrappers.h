/*
     File: JSWrappers.h
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


#import <Cocoa/Cocoa.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import <stdarg.h>



@interface JSWrappers : NSObject {
	JSGlobalContextRef jsContext;
}

	/* property definition for the JavaScript context reference */
@property(assign, readwrite) JSGlobalContextRef jsContext;


	/* allocation functions.  In this class, we maintain a reference
	to a JavaScript context and we use that context in all of
	the calls, as necessary. */ 
- (id)initWithContext:(JSGlobalContextRef)theContext;
- (void)dealloc;


	/* -callJSFunction:withParameters: is a simple utility for calling JavaScript
	functions in a JavaScriptContext.  The caller provides a function
	name and a nil terminated list of parameters, and callJSFunction
	uses those to call the function in the JavaScriptCore context.  Only
	NSString and NSNumber values can be provided as parameters.  The
	result returned is the same as the value returned by the function,
	or NULL if an error occured.  */
- (JSValueRef)callJSFunction:(NSString *)name withParameters:(id)firstParameter,...;


	/* -callBooleanJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a BOOL result.  It will return NO if the function is not
	defined in the context or if an error occurs. */
- (BOOL)callBooleanJSFunction:(NSString *)name withParameters:(id)firstParameter,...;


	/* -callNumericJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a NSNumber * result.  It will return nil if the function is not
	defined in the context, if the result returned by the function cannot be converted
	into a number, or if an error occurs. */
- (NSNumber *)callNumericJSFunction:(NSString *)name withParameters:(id)firstParameter,...;


	/* -callStringJSFunction:withParameters: is similar to -callJSFunction:withParameters:
	except it returns a NSNumber * result.  It will return nil if the function is not
	defined in the context, if the result returned by the function cannot be converted
	into a string,  or if an error occurs. */
- (NSString *)callStringJSFunction:(NSString *)name withParameters:(id)firstParameter,...;




	/* -addGlobalObject:ofClass:withPrivateData: adds an object of the given class 
	and name to the global object of the JavaScriptContext.  After this call, scripts
	running in the context will be able to access the object using the name. */
- (void)addGlobalObject:(NSString *)objectName ofClass:(JSClassRef)theClass withPrivateData:(void *)theData;


	/* -addGlobalStringProperty:withValue: adds a string with the given name to the
	global object of the JavaScriptContext.  After this call, scripts running in
	the context will be able to access the string using the name. */
- (void)addGlobalStringProperty:(NSString *)name withValue:(NSString *)theValue;


	/* -addGlobalFunctionProperty:withCallback: adds a function with the given name to the
	global object of the JavaScriptContext.  After this call, scripts running in
	the context will be able to call the function using the name. */
- (void)addGlobalFunctionProperty:(NSString *)name withCallback:(JSObjectCallAsFunctionCallback)theFunction;


	/* -evaluateJavaScript: evaluates a string containing a JavaScript in the
	JavaScriptCore context and returns the result as a string.  If an error
	occurs or the result returned by the script cannot be converted into a 
	string, then nil is returned. */
- (NSString *)evaluateJavaScript:(NSString*)theJavaScript;

@end



