//
// File:       HID_Name_Lookup.c
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2002-2008 Apple Inc. All Rights Reserved.
//

#include "HID_Name_Lookup.h"
#include "HID_Utilities_Internal.h"

// ---------------------------------
#if 0
// not used
static CFPropertyListRef XML_HIDCookieStringLoad (void)
{
	CFPropertyListRef tCFPropertyListRef = NULL;
	CFURLRef resFileCFURLRef = CFBundleCopyResourceURL(CFBundleGetMainBundle(),CFSTR("HID_cookie_strings"),CFSTR("plist"),NULL);
	CFDataRef resCFDataRef;

	if (CFURLCreateDataAndPropertiesFromResource(kCFAllocatorDefault,resFileCFURLRef,&resCFDataRef,nil,nil,nil))
	{
		if (NULL != resCFDataRef)
		{
			CFStringRef errorString;

			tCFPropertyListRef = CFPropertyListCreateFromXMLData(kCFAllocatorDefault,resCFDataRef,kCFPropertyListImmutable,&errorString);
			if (NULL == tCFPropertyListRef)
				CFShow(errorString);
			CFRelease(resCFDataRef);
		}
	}
	if (NULL != resFileCFURLRef)
		CFRelease(resFileCFURLRef);
	return tCFPropertyListRef;
}

// ---------------------------------

static Boolean XML_NameSearch(const int pVendorID,const int pProductID,const int pCookie,char* pCstr)
{
	static CFPropertyListRef tCFPropertyListRef = NULL;
	Boolean results = false;

	if (NULL == tCFPropertyListRef)
		tCFPropertyListRef = XML_HIDCookieStringLoad ();
	if (NULL != tCFPropertyListRef)
	{
		if (CFDictionaryGetTypeID() == CFGetTypeID(tCFPropertyListRef))
		{
			CFDictionaryRef vendorCFDictionaryRef;
			CFStringRef	vendorKeyCFStringRef;
			vendorKeyCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault,NULL,CFSTR("%d"),pVendorID);

			if (CFDictionaryGetValueIfPresent(tCFPropertyListRef,vendorKeyCFStringRef,(const void**) &vendorCFDictionaryRef))
			{
				CFDictionaryRef productCFDictionaryRef;
				CFStringRef	productKeyCFStringRef;
				CFStringRef	vendorCFStringRef;

				if (CFDictionaryGetValueIfPresent(vendorCFDictionaryRef,CFSTR("Name"),(const void**) &vendorCFStringRef))
				{
					//CFShow(vendorCFStringRef);
				}
				productKeyCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault,NULL,CFSTR("%d"),pProductID);

				if (CFDictionaryGetValueIfPresent(vendorCFDictionaryRef,productKeyCFStringRef,(const void**) &productCFDictionaryRef))
				{
					CFStringRef fullCFStringRef;
					CFStringRef	cookieKeyCFStringRef;
					CFStringRef	productCFStringRef;
					CFStringRef	cookieCFStringRef;

					if (CFDictionaryGetValueIfPresent(productCFDictionaryRef,CFSTR("Name"),(const void**) &productCFStringRef))
					{
						//CFShow(productCFStringRef);
					}
					cookieKeyCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault,NULL,CFSTR("%d"),pCookie);

					if (CFDictionaryGetValueIfPresent(productCFDictionaryRef,cookieKeyCFStringRef,(const void**) &cookieCFStringRef))
					{
						fullCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault,NULL,CFSTR("%@ %@ %@"),
												 vendorCFStringRef,productCFStringRef,cookieCFStringRef);
						// CFShow(cookieCFStringRef);
					}
#if 1	// set true while debugging to create a "fake" device, element, cookie string.
					else
					{
						fullCFStringRef = CFStringCreateWithFormat(kCFAllocatorDefault,NULL,CFSTR("%@ %@ #%@"),
												 vendorCFStringRef,productCFStringRef,cookieKeyCFStringRef);
					}
#endif
					if (fullCFStringRef)
					{
						// CFShow(fullCFStringRef);
						results = CFStringGetCString(
								   fullCFStringRef,pCstr,CFStringGetLength(fullCFStringRef) * sizeof(UniChar) + 1,kCFStringEncodingMacRoman);
						CFRelease(fullCFStringRef);
					}
					CFRelease(cookieKeyCFStringRef);
				}
				CFRelease(productKeyCFStringRef);
			}
			CFRelease(vendorKeyCFStringRef);
		}
		//CFRelease(tCFPropertyListRef);
	}
	return results;
}
#endif

void GetElementNameFromVendorProduct (int vendorID, int productID, int cookie, char * pName)
{
#if 0
	XML_NameSearch (vendorID, productID, cookie, pName); // load from plist
#else // old static code
	*pName = 0; // clear name
	switch (vendorID) {
		case kMacallyID:
			switch (productID) {
				case kiShockID:
					switch (cookie) {
						case 3: sprintf (pName, "D-Pad Up"); break;
						case 4: sprintf (pName, "D-Pad Down"); break;
						case 5: sprintf (pName, "D-Pad Left"); break;
						case 6: sprintf (pName, "D-Pad Right"); break;
						case 7: sprintf (pName, "Up Button"); break;
						case 8: sprintf (pName, "Right Button"); break;
						case 9: sprintf (pName, "Down Button"); break;
						case 10: sprintf (pName, "Left Button"); break;
						case 11: sprintf (pName, "C Button"); break;
						case 12: sprintf (pName, "B Button [Select]"); break;
						case 13: sprintf (pName, "A Button [Start]"); break;
						case 14: sprintf (pName, "F Button"); break;
						case 15: sprintf (pName, "R1 Trigger"); break;
						case 16: sprintf (pName, "R2 Trigger"); break;
						case 17: sprintf (pName, "L1 Trigger"); break;
						case 18: sprintf (pName, "L2 Trigger"); break;
						case 19: sprintf (pName, "Left Stick Button"); break;
						case 20: sprintf (pName, "Right Stick Button"); break;
						case 21: sprintf (pName, "D Button"); break;
						case 22: sprintf (pName, "E Button"); break;
						case 23: sprintf (pName, "Left Stick X-Axis"); break;
						case 24: sprintf (pName, "Left Stick Y-Axis"); break;
						case 25: sprintf (pName, "Right Stick X-Axis"); break;
						case 26: sprintf (pName, "Right Stick Y-Axis"); break;
					}
					break;
			}
			break;
	}
#endif
}
