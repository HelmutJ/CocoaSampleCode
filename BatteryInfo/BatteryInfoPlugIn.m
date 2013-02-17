/*
	    File: BatteryInfoPlugIn.m
	Abstract: BatteryInfoPlugin class.
	 Version: 1.0
	
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
	
	Copyright (C) 2009 Apple Inc. All Rights Reserved.
	
*/

/* It's highly recommended to use CGL macros instead of changing the current context for plug-ins that perform OpenGL rendering */
#import <OpenGL/CGLMacro.h>

#import <IOKit/ps/IOPowerSources.h>
#import <IOKit/ps/IOPSKeys.h>

#import "BatteryInfoPlugIn.h"

#define	kQCPlugIn_Name				@"Battery Info"
#define	kQCPlugIn_Description		@"This patch returns information about the primary battery."

@implementation BatteryInfoPlugIn

/* We need to declare the input / output properties as dynamic as Quartz Composer will handle their implementation */
@dynamic outputInstalled, outputConnected, outputCharging, outputCurrent, outputVoltage, outputCapacity, outputMaxCapacity;

+ (NSDictionary*) attributes
{
	/* Return the attributes of this plug-in */
	return [NSDictionary dictionaryWithObjectsAndKeys:kQCPlugIn_Name, QCPlugInAttributeNameKey, kQCPlugIn_Description, QCPlugInAttributeDescriptionKey, nil];
}

+ (NSDictionary*) attributesForPropertyPortWithKey:(NSString*)key
{
	/* Return the attributes for the plug-in property ports */
	if([key isEqualToString:@"outputInstalled"])
	return [NSDictionary dictionaryWithObject:@"Installed" forKey:QCPortAttributeNameKey];
	if([key isEqualToString:@"outputCharging"])
	return [NSDictionary dictionaryWithObject:@"Charging" forKey:QCPortAttributeNameKey];
	if([key isEqualToString:@"outputConnected"])
	return [NSDictionary dictionaryWithObject:@"Power Connected" forKey:QCPortAttributeNameKey];
	if([key isEqualToString:@"outputCurrent"])
	return [NSDictionary dictionaryWithObject:@"Current (mA)" forKey:QCPortAttributeNameKey];
	if([key isEqualToString:@"outputVoltage"])
	return [NSDictionary dictionaryWithObject:@"Voltage (mV)" forKey:QCPortAttributeNameKey];
	if([key isEqualToString:@"outputCapacity"])
	return [NSDictionary dictionaryWithObject:@"Capacity" forKey:QCPortAttributeNameKey];
	if([key isEqualToString:@"outputMaxCapacity"])
	return [NSDictionary dictionaryWithObject:@"Maximum Capacity" forKey:QCPortAttributeNameKey];
	
	return nil;
}

+ (QCPlugInExecutionMode) executionMode
{
	/* This plug-in is a provider (it provides data from an external source) */
	return kQCPlugInExecutionModeProvider;
}

+ (QCPlugInTimeMode) timeMode
{
	/* This plug-in does not depend on the time (time parameter is completely ignored in the -execute:atTime:withArguments: method) but we need idling */
	return kQCPlugInTimeModeIdle;
}

@end

@implementation BatteryInfoPlugIn (Execution)

- (BOOL) startExecution:(id<QCPlugInContext>)context
{
	/* Setup */
	
	return YES;
}

- (BOOL) execute:(id<QCPlugInContext>)context atTime:(NSTimeInterval)time withArguments:(NSDictionary*)arguments
{
	CFTypeRef				info;
	CFArrayRef				list;
	CFDictionaryRef			battery;
	
	info = IOPSCopyPowerSourcesInfo();
	if(info == NULL)
	return NO;
	list = IOPSCopyPowerSourcesList(info);
	if(list == NULL) {
		CFRelease(info);
		return NO;
	}
	
	if(CFArrayGetCount(list) && (battery = IOPSGetPowerSourceDescription(info, CFArrayGetValueAtIndex(list, 0)))) {
		self.outputInstalled = [[(NSDictionary*)battery objectForKey:@kIOPSIsPresentKey] boolValue];
		self.outputConnected = [(NSString*)[(NSDictionary*)battery objectForKey:@kIOPSPowerSourceStateKey] isEqualToString:@kIOPSACPowerValue];
		self.outputCharging = [[(NSDictionary*)battery objectForKey:@kIOPSIsChargingKey] boolValue];
		self.outputCurrent = [[(NSDictionary*)battery objectForKey:@kIOPSCurrentKey] doubleValue];
		self.outputVoltage = [[(NSDictionary*)battery objectForKey:@kIOPSVoltageKey] doubleValue];
		self.outputCapacity = [[(NSDictionary*)battery objectForKey:@kIOPSCurrentCapacityKey] doubleValue];
		self.outputMaxCapacity = [[(NSDictionary*)battery objectForKey:@kIOPSMaxCapacityKey] doubleValue];
	}
	else {
		self.outputInstalled = NO;
		self.outputConnected = NO;
		self.outputCharging = NO;
		self.outputCurrent = 0.0;
		self.outputVoltage = 0.0;
		self.outputCapacity = 0.0;
		self.outputMaxCapacity = 0.0;
	}
	
	CFRelease(list);
	CFRelease(info);
	
	return YES;
}

- (void) stopExecution:(id<QCPlugInContext>)context
{
	/* Clean up*/
}

@end
