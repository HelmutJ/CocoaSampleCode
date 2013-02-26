/*

File:ConversionEngine.m

Abstract: A simple conversion engine.  This converts number strings into one of the formats supported by NSNumberFormatter.

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

Copyright (C) 2007 Apple Inc. All Rights Reserved.

*/
#import "ConversionEngine.h"


@implementation ConversionEngine

-(void)awakeFromNib
{
	[self setConversionMode:NSNumberFormatterDecimalStyle];
	
}

-(NSString*)convert:(NSString*)string
{
	// Allocate the formatter lazily
	// We want to use the 10.4 methods of NSNumberFormatter so we allocate it here and set the default behavior to the 10.4 behavior.
	// See comment below from documentation.
	
	/*
	Important:  The pre-Mac OS X v10.4 methods of NSNumberFormatter are not compatible with the methods added for Mac OS X v10.4. An NSNumberFormatter object should not invoke methods in these different behavior groups indiscriminately. Use the old-style methods if you have configured the number-formatter behavior to be NSNumberFormatterBehavior10_0. Use the new methods instead of the older-style ones if you have configured the number-formatter behavior to be NSNumberFormatterBehavior10_4.
	Note also that number formatters created in Interface Builder use the Mac OS X v10.0 behavior—see NSNumberFormatter on Mac OS X v10.4.
	*/
	
	if ( formatter == nil ) {
		// Specify that we want the modern 10.4 behavior
		[NSNumberFormatter setDefaultFormatterBehavior:NSNumberFormatterBehavior10_4];
		// Now allocate our formatter
		formatter = [[NSNumberFormatter alloc] init];		
	}
	// Convert the string into a number first
	// We set the conversion style each time in case it has changed.
	[formatter setNumberStyle:NSNumberFormatterNoStyle];
	
	NSNumber*		number = [formatter numberFromString:string];
	
	// Now convert the number to the right format string
	[formatter setNumberStyle:[self conversionMode]];
	return [formatter stringFromNumber:number];
}

-(NSNumberFormatterStyle)conversionMode {
	return conversionMode;
}

-(void)setConversionMode:(NSNumberFormatterStyle)mode
{
	conversionMode = mode;
}

@end
