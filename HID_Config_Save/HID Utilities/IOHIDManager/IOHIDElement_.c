//     File: IOHIDElement_.c
// Abstract: convieance functions for IOHIDElementGetProperty
//  Version: 5.0
// 
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
// Inc. ("Apple") in consideration of your agreement to the following
// terms, and your use, installation, modification or redistribution of
// this Apple software constitutes acceptance of these terms.  If you do
// not agree with these terms, please do not use, install, modify or
// redistribute this Apple software.
// 
// In consideration of your agreement to abide by the following terms, and
// subject to these terms, Apple grants you a personal, non-exclusive
// license, under Apple's copyrights in this original Apple software (the
// "Apple Software"), to use, reproduce, modify and redistribute the Apple
// Software, with or without modifications, in source and/or binary forms;
// provided that if you redistribute the Apple Software in its entirety and
// without modifications, you must retain this notice and the following
// text and disclaimers in all such redistributions of the Apple Software.
// Neither the name, trademarks, service marks or logos of Apple Inc. may
// be used to endorse or promote products derived from the Apple Software
// without specific prior written permission from Apple.  Except as
// expressly stated in this notice, no other rights or licenses, express or
// implied, are granted by Apple herein, including but not limited to any
// patent rights that may be infringed by your derivative works or by other
// works in which the Apple Software may be incorporated.
// 
// The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
// MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
// THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
// OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
// 
// IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
// OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
// MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
// AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
// STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.
// 
// Copyright (C) 2010 Apple Inc. All Rights Reserved.
// 
// *****************************************************
#pragma mark - includes & imports
// -----------------------------------------------------

#include "IOHIDElement_.h"

// *****************************************************
#pragma mark - typedef's, struct's, enums, defines, etc.
// -----------------------------------------------------

// *****************************************************
#pragma mark - local (static) function prototypes
// -----------------------------------------------------

// *****************************************************
#pragma mark - exported globals
// -----------------------------------------------------

// *****************************************************
#pragma mark - local (static) globals
// -----------------------------------------------------

// *****************************************************
#pragma mark - exported function implementations
// -----------------------------------------------------

// *************************************************************************
//
// HIDIsValidElement(inIOHIDElementRef)
//
// Purpose:	validate this element
//
// Inputs:	inIOHIDElementRef	- the element
//
// Returns:	Boolean			- TRUE if this is a valid element ref
//
Boolean HIDIsValidElement(IOHIDElementRef inIOHIDElementRef) {
	Boolean result = FALSE; // assume failure (pessimist!)
	
	if (inIOHIDElementRef) {
		if (CFGetTypeID(inIOHIDElementRef) ==IOHIDElementGetTypeID() ) {
			result = TRUE;
		}
	}
	
	return (result);
} // HIDIsValidElement

// *************************************************************************
//
// IOHIDElement_GetValue(inIOHIDElementRef, inIOHIDValueScaleType)
//
// Purpose:	returns the current value for an element(polling)
//
// Notes:	will return 0 on error conditions which should be accounted for by application
//
// Inputs:	inIOHIDElementRef	- the element
// inIOHIDValueScaleType	- scale type (calibrated or physical)
//
// Returns:	double		- current value for element
//
double IOHIDElement_GetValue(IOHIDElementRef inIOHIDElementRef, IOHIDValueScaleType inIOHIDValueScaleType) {
	double        result = 0;
	IOHIDValueRef tIOHIDValueRef;
	
	if ( kIOReturnSuccess == IOHIDDeviceGetValue(IOHIDElementGetDevice(inIOHIDElementRef), inIOHIDElementRef, &tIOHIDValueRef) ) {
		result = IOHIDValueGetScaledValue(tIOHIDValueRef, inIOHIDValueScaleType);
	}
	
	return (result);
}   // IOHIDElement_GetValue

// *************************************************************************
//
// IOHIDElement_GetCalibrationMin(inIOHIDElementRef)
//
// Purpose:	get the minimum bounds for a calibrated value for this element
//
// Inputs:  inIOHIDElementRef - the IOHIDElementRef for this element
//
// Returns:	double - the minimum Calibration value for this element
//

double IOHIDElement_GetCalibrationMin(IOHIDElementRef inIOHIDElementRef) {
	double result;
	
	if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationMinKey), &result) ) {
		if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementMaxKey), &result) ) {
			result = 0x7FFFFFFF;
		}
		
		IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationMinKey), result);
	}
	
	return (result);
}   // IOHIDElement_GetCalibrationMin

// *************************************************************************
//
// IOHIDElement_SetCalibrationMin(inIOHIDElementRef, inValue)
//
// Purpose:	set the minimum bounds for a calibrated value for this element
//
// Inputs:  inIOHIDElementRef	- the IOHIDElementRef for this element
// inValue			- the minimum bounds for a calibrated value for this element
//
// Returns:	nothing
//

void IOHIDElement_SetCalibrationMin(IOHIDElementRef inIOHIDElementRef, double inValue) {
	IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationMinKey), inValue);
}   // IOHIDElement_SetCalibrationMin

// *************************************************************************
//
// IOHIDElement_GetCalibrationMax(inIOHIDElementRef)
//
// Purpose:	get the maximum bounds for a calibrated value for this element
//
// Inputs:  inIOHIDElementRef - the IOHIDElementRef for this element
//
// Returns:	double - the maximum Calibration value for this element
//

double IOHIDElement_GetCalibrationMax(IOHIDElementRef inIOHIDElementRef) {
	double result;
	
	if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationMaxKey), &result) ) {
		if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementMinKey), &result) ) {
			result = -0x7FFFFFFF;
		}
		
		IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationMaxKey), result);
	}
	
	return (result);
}   // IOHIDElement_GetCalibrationMax

// *************************************************************************
//
// IOHIDElement_SetCalibrationMax(inIOHIDElementRef, inValue)
//
// Purpose:	set the maximum bounds for a calibrated value for this element
//
// Inputs:  inIOHIDElementRef	- the IOHIDElementRef for this element
// inValue			- the maximum Calibration value for this element
//
// Returns:	nothing
//

void IOHIDElement_SetCalibrationMax(IOHIDElementRef inIOHIDElementRef, double inValue) {
	IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationMaxKey), inValue);
}   // IOHIDElement_SetCalibrationMax

// *************************************************************************
//
// IOHIDElement_GetCalibrationSaturationMin(inIOHIDElementRef)
//
// Purpose:	get the mininum tolerance to be used when calibrating a logical element value
//
// Inputs:  inIOHIDElementRef - the IOHIDElementRef for this element
//
// Returns:	double - the maximum Calibration value for this element
//

double IOHIDElement_GetCalibrationSaturationMin(IOHIDElementRef inIOHIDElementRef) {
	double result;
	
	if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationSaturationMinKey), &result) ) {
		if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementMinKey), &result) ) {
			result = -0x7FFFFFFF;
		}
		
		IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationSaturationMinKey), result);
	}
	
	return (result);
}   // IOHIDElement_GetCalibrationSaturationMin

// *************************************************************************
//
// IOHIDElement_SetCalibrationSaturationMin(inIOHIDElementRef, inValue)
//
// Purpose:	set the mininum tolerance to be used when calibrating a logical element value
//
// Inputs:  inIOHIDElementRef	- the IOHIDElementRef for this element
// inValue			- the maximum Calibration value for this element
//
// Returns:	nothing
//

void IOHIDElement_SetCalibrationSaturationMin(IOHIDElementRef inIOHIDElementRef, double inValue) {
	IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationSaturationMinKey), inValue);
}   // IOHIDElement_SetCalibrationSaturationMin

// *************************************************************************
//
// IOHIDElement_GetCalibrationSaturationMax(inIOHIDElementRef)
//
// Purpose:	get the maximum tolerance to be used when calibrating a logical element value
//
// Inputs:  inIOHIDElementRef - the IOHIDElementRef for this element
//
// Returns:	double - the maximum Calibration value for this element
//

double IOHIDElement_GetCalibrationSaturationMax(IOHIDElementRef inIOHIDElementRef) {
	double result;
	
	if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), &result) ) {
		if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementMinKey), &result) ) {
			result = -0x7FFFFFFF;
		}
		
		IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), result);
	}
	
	return (result);
}   // IOHIDElement_GetCalibrationSaturationMax

// *************************************************************************
//
// IOHIDElement_SetCalibrationSaturationMax(inIOHIDElementRef, inValue)
//
// Purpose:	set the maximum tolerance to be used when calibrating a logical element value
//
// Inputs:  inIOHIDElementRef	- the IOHIDElementRef for this element
// inValue			- the maximum Calibration value for this element
//
// Returns:	nothing
//

void IOHIDElement_SetCalibrationSaturationMax(IOHIDElementRef inIOHIDElementRef, double inValue) {
	IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationSaturationMaxKey), inValue);
}   // IOHIDElement_SetCalibrationSaturationMax

// *************************************************************************
//
// IOHIDElement_GetCalibrationDeadZoneMin(inIOHIDElementRef)
//
// Purpose:	get the minimum bounds near the midpoint of a logical value in which the value is ignored
//
// Inputs:  inIOHIDElementRef - the IOHIDElementRef for this element
//
// Returns:	double - the maximum Calibration value for this element
//

double IOHIDElement_GetCalibrationDeadZoneMin(IOHIDElementRef inIOHIDElementRef) {
	double result;
	
	if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationDeadZoneMinKey), &result) ) {
		if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementMinKey), &result) ) {
			result = -0x7FFFFFFF;
		}
		
		IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationDeadZoneMinKey), result);
	}
	
	return (result);
}   // IOHIDElement_GetCalibrationDeadZoneMin

// *************************************************************************
//
// IOHIDElement_SetCalibrationDeadZoneMin(inIOHIDElementRef, inValue)
//
// Purpose:	set the minimum bounds near the midpoint of a logical value in which the value is ignored
//
// Inputs:  inIOHIDElementRef	- the IOHIDElementRef for this element
// inValue			- the maximum Calibration value for this element
//
// Returns:	nothing
//

void IOHIDElement_SetCalibrationDeadZoneMin(IOHIDElementRef inIOHIDElementRef, double inValue) {
	IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationDeadZoneMinKey), inValue);
}   // IOHIDElement_SetCalibrationDeadZoneMin

// *************************************************************************
//
// IOHIDElement_GetCalibrationDeadZoneMax(inIOHIDElementRef)
//
// Purpose:	get the maximum bounds near the midpoint of a logical value in which the value is ignored
//
// Inputs:  inIOHIDElementRef - the IOHIDElementRef for this element
//
// Returns:	double - the maximum Calibration value for this element
//

double IOHIDElement_GetCalibrationDeadZoneMax(IOHIDElementRef inIOHIDElementRef) {
	double result;
	
	if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationDeadZoneMaxKey), &result) ) {
		if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementMinKey), &result) ) {
			result = -0x7FFFFFFF;
		}
		
		IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationDeadZoneMaxKey), result);
	}
	
	return (result);
}   // IOHIDElement_GetCalibrationDeadZoneMax

// *************************************************************************
//
// IOHIDElement_SetCalibrationDeadZoneMax(inIOHIDElementRef, inValue)
//
// Purpose:	set the maximum bounds near the midpoint of a logical value in which the value is ignored
//
// Inputs:  inIOHIDElementRef	- the IOHIDElementRef for this element
// inValue			- the maximum Calibration value for this element
//
// Returns:	nothing
//

void IOHIDElement_SetCalibrationDeadZoneMax(IOHIDElementRef inIOHIDElementRef, double inValue) {
	IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationDeadZoneMaxKey), inValue);
}   // IOHIDElement_SetCalibrationDeadZoneMax

// *************************************************************************
//
// IOHIDElement_GetCalibrationGranularity(inIOHIDElementRef)
//
// Purpose:	get the level of detail returned for a calibrated element value
//
// Inputs:  inIOHIDElementRef - the IOHIDElementRef for this element
//
// Returns:	double_t - the maximum Calibration value for this element
//

double_t IOHIDElement_GetCalibrationGranularity(IOHIDElementRef inIOHIDElementRef) {
	double result;
	
	if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationGranularityKey), &result) ) {
		if ( !IOHIDElement_GetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementMinKey), &result) ) {
			result = -0x7FFFFFFF;
		}
		
		IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationGranularityKey), result);
	}
	
	return (result);
}   // IOHIDElement_GetCalibrationGranularity

// *************************************************************************
//
// IOHIDElement_SetCalibrationGranularity(inIOHIDElementRef, inValue)
//
// Purpose:	set the level of detail returned for a calibrated element value
//
// Inputs:  inIOHIDElementRef	- the IOHIDElementRef for this element
// inValue			- the the level of detail for this element
//
// Returns:	nothing
//

void IOHIDElement_SetCalibrationGranularity(IOHIDElementRef inIOHIDElementRef, double_t inValue) {
	IOHIDElement_SetDoubleProperty(inIOHIDElementRef, CFSTR(kIOHIDElementCalibrationGranularityKey), inValue);
}   // IOHIDElement_SetCalibrationGranularity

// *****************************************************
#pragma mark - local (static) function implementations
// -----------------------------------------------------

// *************************************************************************
//
// IOHIDElement_GetLongProperty(inIOHIDElementRef, inKey, outValue)
//
// Purpose:	convieance function to return a long property of an element
//
// Inputs:	inIOHIDElementRef	- the element
// inKey			- CFString for the key
// outValue		- address where to store the value
// Returns:	Boolean			- TRUE if successful
// outValue		- the long property's value
//

Boolean IOHIDElement_GetLongProperty(IOHIDElementRef inIOHIDElementRef, CFStringRef inKey, uint32_t * outValue) {
	Boolean   result = FALSE;
	
	CFTypeRef tCFTypeRef = IOHIDElementGetProperty(inIOHIDElementRef, inKey);
	
	if (tCFTypeRef) {
		// if this is a number
		if ( CFNumberGetTypeID() == CFGetTypeID(tCFTypeRef) ) {
			// get it's value
			result = CFNumberGetValue( (CFNumberRef) tCFTypeRef, kCFNumberSInt32Type, outValue );
		}
	}
	
	return (result);
} /* IOHIDElement_GetLongProperty */

// *************************************************************************
//
// IOHIDElement_SetLongProperty(inIOHIDElementRef, inKey, inValue)
//
// Purpose:	convieance function to set a long property of an element
//
// Inputs:	inIOHIDElementRef	- the element
// inKey			- CFString for the key
// inValue			- the value to set it to
//
// Returns:	nothing
//

void IOHIDElement_SetLongProperty(IOHIDElementRef inIOHIDElementRef, CFStringRef inKey, uint32_t inValue) {
	CFNumberRef tCFNumberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &inValue);
	
	if (tCFNumberRef) {
		IOHIDElementSetProperty(inIOHIDElementRef, inKey, tCFNumberRef);
		CFRelease(tCFNumberRef);
	}
} // IOHIDElement_SetLongProperty

// *************************************************************************
//
// IOHIDElement_GetDoubleProperty(inIOHIDElementRef, inKey, outValue)
//
// Purpose:	convieance function to return a double property of an element
//
// Inputs:	inIOHIDElementRef	- the element
// inKey			- CFString for the key
// outValue		- address where to store the value
// Returns:	Boolean			- TRUE if successful
// outValue		- the double property's value
//

Boolean IOHIDElement_GetDoubleProperty(IOHIDElementRef inIOHIDElementRef, CFStringRef inKey, double * outValue) {
	Boolean   result = FALSE;
	
	CFTypeRef tCFTypeRef = IOHIDElementGetProperty(inIOHIDElementRef, inKey);
	
	if (tCFTypeRef) {
		// if this is a number
		if ( CFNumberGetTypeID() == CFGetTypeID(tCFTypeRef) ) {
			// get it's value
			result = CFNumberGetValue( (CFNumberRef) tCFTypeRef, kCFNumberDoubleType, outValue );
		}
	}
	
	return (result);
} /* IOHIDElement_GetDoubleProperty */

// *************************************************************************
//
// IOHIDElement_SetDoubleProperty(inIOHIDElementRef, inKey, inValue)
//
// Purpose:	convieance function to set a double property of an element
//
// Inputs:	inIOHIDElementRef	- the element
// inKey			- CFString for the key
// inValue			- the value to set it to
//
// Returns:	nothing
//

void IOHIDElement_SetDoubleProperty(IOHIDElementRef inIOHIDElementRef, CFStringRef inKey, double inValue) {
	CFNumberRef tCFNumberRef = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &inValue);
	
	if (tCFNumberRef) {
		IOHIDElementSetProperty(inIOHIDElementRef, inKey, tCFNumberRef);
		CFRelease(tCFNumberRef);
	}
} // IOHIDElement_SetDoubleProperty
// *****************************************************
