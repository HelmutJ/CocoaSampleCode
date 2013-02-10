/*
     File: main.c
 Abstract: DisplayURL creates a CFURL and then uses CFURL functions to parse
 the CFURL and display its components. This is very useful for
 determining the exact behavior of the CFURL functions. DisplayURL
 accepts either a URL or path (from which a URL is created).
 DisplayURL allows you to create relative CFURLs and leave them
 relative, or make them absolute before parsing. And DisplayURL
 allows you to use the delete/append component and extension functions.
 
 Examples:
 DisplayURL "scheme://user:pass@host:1/path/path2/file.html;params?query#fragment"
 DisplayURL -P "/System/Library/"
 
 Note: for the CFURL parsing routines to work correctly, any URL
 strings passed must conform to IETF rfc3986 www.ietf.org/rfc/rfc3986.txt.
 That means reserved characters must be properly escaped.
  Version: 2.1
 
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

#define DEBUG 1
#include <unistd.h>
#include <ctype.h>
#include <sys/param.h>
#include <CoreServices/CoreServices.h>

/******************************************************************************/

static void usage(void)
{
	/* 80-columns    12345678901234567890123456789012345678901234567890123456789012345678901234567890 */
	fprintf(stderr, "usage: DisplayURL [-h] [-P -S <pathStyle>] [[-p -s <pathStyle>] -b <baseURLString>]\n");
	fprintf(stderr, "           [-a] [-c | -C <component>] [-x | -X <extension>] <urlString>\n");
	fprintf(stderr, "    DisplayURL creates a CFURL and then uses the various CFURL functions to\n");
	fprintf(stderr, "    parse the CFURL and display its components. The -c/C (delete/append path\n");
	fprintf(stderr, "    component), -x/X (delete/append path extension), and -a (make URL absolute)\n");
	fprintf(stderr, "    options are applied the the CFURL in that order.\n");
	fprintf(stderr, "        -h                 Shows this help message.\n");
	fprintf(stderr, "        -P                 The urlString is a path instead of a URL.\n");
	fprintf(stderr, "        -S <pathStyle>     The path style of URLString (default is POSIX)\n");
	fprintf(stderr, "                               (p = POSIX, h = HFS, w = Windows).\n");
	fprintf(stderr, "        -p                 The baseURLString is a path instead of a URL.\n");
	fprintf(stderr, "        -s <pathStyle>     The path style of baseURLString (default is POSIX)\n");
	fprintf(stderr, "                               (p = POSIX, h = HFS, w = Windows).\n");
	fprintf(stderr, "        -b <baseURLString> The string used to create baseURL.\n");
	fprintf(stderr, "        -a                 Make the URL absolute.\n");
	fprintf(stderr, "        -c                 Delete last path component.\n");
	fprintf(stderr, "        -C <component>     Append path component.\n");
	fprintf(stderr, "        -x                 Delete path extension.\n");
	fprintf(stderr, "        -X <extension>     Append path extension.\n");
	fprintf(stderr, "        <urlString>        The string used to create the URL.\n");
}

/******************************************************************************/

#define CF_RELEASE_CLEAR(cf)  \
	do {                      \
		if ( (cf) != NULL ) { \
			CFRelease((cf));  \
			(cf) = NULL;        \
		}                     \
	} while ( 0 )

/******************************************************************************/

/*
 * DisplayURLComponent displays the componentType for the url or "(not found)"
 * if that componentType is not found in the url.
 */
static void DisplayURLComponent(
	CFURLRef url,						// input: the URL
	UInt8 *buffer,						// input: the buffer containing the URLs bytes (filled in by CFURLGetBytes)
	CFURLComponentType componentType,	// input: the URL component to display
	const char *componentTypeStr)		// input: the display string for the componentType
{
	CFRange range;
	CFRange rangeIncludingSeparators;
	
	/* now, get the components and display them */
	range = CFURLGetByteRangeForComponent(url, componentType, &rangeIncludingSeparators);
	if ( range.location != kCFNotFound )
	{
		char *componentStr;
		char *componentIncludingSeparatorsStr;
		
		componentStr = malloc(range.length + 1);
		require(componentStr != NULL, malloc_componentStr);
		componentIncludingSeparatorsStr = malloc(rangeIncludingSeparators.length + 1);
		require(componentStr != NULL, malloc_componentIncludingSeparatorsStr);
		
		strncpy(componentStr, (const char *)&buffer[range.location], range.length);
		componentStr[range.length] = 0;
		strncpy(componentIncludingSeparatorsStr, (const char *)&buffer[rangeIncludingSeparators.location], rangeIncludingSeparators.length);
		componentIncludingSeparatorsStr[rangeIncludingSeparators.length] = 0;
		fprintf(stdout, "\t%s: \"%s\" including separators: \"%s\"\n", componentTypeStr, componentStr, componentIncludingSeparatorsStr);
		
		free(componentIncludingSeparatorsStr);
malloc_componentIncludingSeparatorsStr:
		free(componentStr);
malloc_componentStr:
		;
	}
	else
	{
		fprintf(stdout, "\t%s (not found)\n", componentTypeStr);
	}
}

/******************************************************************************/

/*
 * DisplayTagAndString displays the tag and then the str or "(not found)"
 * if str is NULL.
 */
static void DisplayTagAndString(
	CFStringRef tag,	// input: the tag
	CFStringRef str)	// input: the CFString
{
	CFStringRef displayStr;
	UInt8 *buffer;
	CFRange range;
	CFIndex bytesToConvert;
	CFIndex bytesConverted;
	
	if ( str != NULL )
	{
		displayStr = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("\t%@: \"%@\""), tag, str);
	}
	else
	{
		displayStr = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("\t%@: (not found)"), tag);
	}
	require(displayStr != NULL, CFStringCreateWithFormat);
	
	range = CFRangeMake(0, CFStringGetLength(displayStr));
	CFStringGetBytes(displayStr, range, kCFStringEncodingUTF8, 0, false, NULL, 0, &bytesToConvert);
	buffer = malloc(bytesToConvert + 1);
	require(buffer != NULL, malloc_buffer);
	
	CFStringGetBytes(displayStr, range, kCFStringEncodingUTF8, 0, false, buffer, bytesToConvert, &bytesConverted);
	buffer[bytesConverted] = '\0';
	fprintf(stdout, "%s\n", buffer);
	free(buffer);
	
malloc_buffer:

	CF_RELEASE_CLEAR(displayStr);
	
CFStringCreateWithFormat:
	
	return;
}

/******************************************************************************/

static void DisplayFileSystemRepresentation(
	CFURLRef url)						// input: the URL
{
	enum { kBufferSize = MAXPATHLEN * 4 };
	Boolean result;
	UInt8 buffer[kBufferSize];
	
	result = CFURLGetFileSystemRepresentation(url, FALSE, buffer, kBufferSize);
	if ( result )
	{
		fprintf(stdout, "\tCFURLGetFileSystemRepresentation(!resolveAgainstBase): \"%s\"\n", buffer);
	}
	else
	{
		fprintf(stdout, "\tCFURLGetFileSystemRepresentation(!resolveAgainstBase): (failed)\n");
	}
	
	result = CFURLGetFileSystemRepresentation(url, TRUE, buffer, kBufferSize);
	if ( result )
	{
		fprintf(stdout, "\tCFURLGetFileSystemRepresentation(resolveAgainstBase): \"%s\"\n", buffer);
	}
	else
	{
		fprintf(stdout, "\tCFURLGetFileSystemRepresentation(resolveAgainstBase): (failed)\n");
	}
}

/******************************************************************************/

/* HasDirectoryPath returns true if pathString ends with a '/' character */
static Boolean HasDirectoryPath(
	CFStringRef pathString,					// input: the path string
	CFURLPathStyle pathStyle)				// input: the path style
{
	Boolean result;
	
	switch ( pathStyle )
	{
		case kCFURLPOSIXPathStyle:
			result = CFStringGetCharacterAtIndex(pathString, CFStringGetLength(pathString)) == (UniChar)'/';
			break;
		case kCFURLHFSPathStyle:
			result = CFStringGetCharacterAtIndex(pathString, CFStringGetLength(pathString)) == (UniChar)':';
			break;
		case kCFURLWindowsPathStyle:
			result = CFStringGetCharacterAtIndex(pathString, CFStringGetLength(pathString)) == (UniChar)'\\';
			break;
		default:
			result = FALSE;
			break;			
	}
	return ( result );
}

/******************************************************************************/

int main (int argc, char * const argv[])
{
	int err = EXIT_SUCCESS;
	int ch;

	CFStringRef urlString = NULL;
	Boolean urlStringIsPath = FALSE;
	CFURLPathStyle urlStringPathStyle = kCFURLPOSIXPathStyle;
	
	CFStringRef baseURLString = NULL;
	Boolean baseURLStringIsPath = FALSE;
	CFURLPathStyle baseURLStringPathStyle = kCFURLPOSIXPathStyle;
	
	Boolean deletePathExtension = FALSE;
	Boolean appendPathExtension = FALSE;
	CFStringRef pathExtension = NULL;
	
	Boolean deleteLastPathComponent = FALSE;
	Boolean appendPathComponent = FALSE;
	CFStringRef lastPathComponent = NULL;
	
	CFURLRef baseURL = NULL;
	CFURLRef testURL = NULL;
	Boolean makeAbsolute = FALSE;
	CFURLRef tempURL = NULL;

	CFIndex bufferLength;
	UInt8 *buffer = NULL;
	CFIndex componentLength;
	Boolean isAbsolute;
	
	CFStringRef tempStr = NULL;
		
	/* crack command line args */
	while ( ((ch = getopt(argc, argv, "hPS:ps:b:axX:cC:")) != -1) && (err == EXIT_SUCCESS) )
	{
		switch ( ch )
		{
			case 'P':
				urlStringIsPath = TRUE;
				break;
			case 'S':
				/* get pathStyle for urlString */
				switch ( tolower(optarg[0]) )
				{
					case 'p':
						urlStringPathStyle = kCFURLPOSIXPathStyle;
						break;
					case 'h':
						urlStringPathStyle = kCFURLHFSPathStyle;
						break;
					case 'w':
						urlStringPathStyle = kCFURLWindowsPathStyle;
						break;
					default:
						break;
				}
				break;
			case 'p':
				baseURLStringIsPath = TRUE;
				break;
			case 's':
				/* get pathStyle for baseURLString */
				switch ( tolower(optarg[0]) )
				{
					case 'p':
						baseURLStringPathStyle = kCFURLPOSIXPathStyle;
						break;
					case 'h':
						baseURLStringPathStyle = kCFURLHFSPathStyle;
						break;
					case 'w':
						baseURLStringPathStyle = kCFURLWindowsPathStyle;
						break;
					default:
						break;
				}
				break;
			case 'b':
				CF_RELEASE_CLEAR(baseURLString);
				baseURLString = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8 *)optarg, strlen(optarg), kCFStringEncodingUTF8, FALSE);
				require_action(baseURLString != NULL, CFStringCreateWithBytes_baseURLString, err = EXIT_FAILURE);
				break;
			case 'a':
				makeAbsolute = TRUE;
				break;
			case 'x':
				deletePathExtension = TRUE;
				break;
			case 'X':
				appendPathExtension = TRUE;
				CF_RELEASE_CLEAR(pathExtension);
				pathExtension = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8 *)optarg, strlen(optarg), kCFStringEncodingUTF8, FALSE);
				require_action(pathExtension != NULL, CFStringCreateWithBytes_pathExtension, err = EXIT_FAILURE);
				break;
			case 'c':
				deleteLastPathComponent = TRUE;
				break;
			case 'C':
				appendPathComponent = TRUE;
				CF_RELEASE_CLEAR(lastPathComponent);
				lastPathComponent = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8 *)optarg, strlen(optarg), kCFStringEncodingUTF8, FALSE);
				require_action(lastPathComponent != NULL, CFStringCreateWithBytes_lastPathComponent, err = EXIT_FAILURE);
				break;
			case 'h':
			case '?':
			default:
				err = EXIT_FAILURE;
				break;
		}
	}
	/* was the usage parsed correctly? */
	require_action_quiet(!err, command_err, usage(); err = EXIT_FAILURE);
	
	/* were any mutually exclusive options used incorrectly? */
	require_action((!deletePathExtension && !appendPathExtension) || (deletePathExtension != appendPathExtension), command_err, usage(); err = EXIT_FAILURE);
	require_action((!deleteLastPathComponent && !appendPathComponent) || (deleteLastPathComponent != appendPathComponent), command_err, usage(); err = EXIT_FAILURE);
	
	/* there should be one argument left -- the urlString */
	require_action((argc - optind) == 1, command_err, usage(); err = EXIT_FAILURE);
	urlString = CFStringCreateWithBytes(kCFAllocatorDefault, (UInt8 *)argv[optind], strlen(argv[optind]), kCFStringEncodingUTF8, FALSE);
	require_action(urlString != NULL, command_err, usage(); err = EXIT_FAILURE);
	
	if ( baseURLString )
	{
		/* create the url with a baseURL */
		if ( baseURLStringIsPath )
		{
			baseURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, baseURLString, baseURLStringPathStyle, TRUE);
			require_action(baseURL != NULL, command_err, usage(); err = EXIT_FAILURE);
		}
		else
		{
			baseURL = CFURLCreateWithString(kCFAllocatorDefault, baseURLString, NULL);
			require_action(baseURL != NULL, command_err, usage(); err = EXIT_FAILURE);
		}
		
		if ( urlStringIsPath )
		{
			testURL = CFURLCreateWithFileSystemPathRelativeToBase(kCFAllocatorDefault, urlString, urlStringPathStyle, HasDirectoryPath(urlString, urlStringPathStyle), baseURL);
			require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
		}
		else
		{
			testURL = CFURLCreateWithString(kCFAllocatorDefault, urlString, baseURL);
			require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
		}
	}
	else
	{
		/* create the url without a baseURL */
		if ( urlStringIsPath )
		{
			testURL = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, urlString, urlStringPathStyle, TRUE);
			require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
		}
		else
		{
			testURL = CFURLCreateWithString(kCFAllocatorDefault, urlString, NULL);
			require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
		}
	}
	
	/* manipulate last path component before manipulating extension */
	if ( deleteLastPathComponent )
	{
		tempURL = testURL;
		testURL = CFURLCreateCopyDeletingLastPathComponent(kCFAllocatorDefault, tempURL);
		CF_RELEASE_CLEAR(tempURL);
		require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
	}
	else if ( appendPathComponent )
	{
		tempURL = testURL;
		/* the component being appended to a CFURL is always kCFURLPOSIXPathStyle because that's the internal representation */
		testURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorDefault, tempURL, lastPathComponent, HasDirectoryPath(lastPathComponent, kCFURLPOSIXPathStyle));
		CF_RELEASE_CLEAR(tempURL);
		require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
	}
	
	/* manipulate extension */
	if ( deletePathExtension )
	{
		tempURL = testURL;
		testURL = CFURLCreateCopyDeletingPathExtension(kCFAllocatorDefault, tempURL);
		CF_RELEASE_CLEAR(tempURL);
		require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
	}
	else if ( appendPathExtension )
	{
		tempURL = testURL;
		testURL = CFURLCreateCopyAppendingPathExtension(kCFAllocatorDefault, tempURL, pathExtension);
		CF_RELEASE_CLEAR(tempURL);
		require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
	}
	
	/* make testURL absolute if requested */
	if ( makeAbsolute )
	{
		tempURL = testURL;
		testURL = CFURLCopyAbsoluteURL(tempURL);
		CF_RELEASE_CLEAR(tempURL);
	}
	require_action(testURL != NULL, command_err, usage(); err = EXIT_FAILURE);
	
	/*
	 * There are accessor functions to get the most common URL components and info.
	 */
	fprintf(stdout, "Components and info from accessor functions:\n");
	
	DisplayTagAndString(CFSTR("CFURLGetString()"), CFURLGetString(testURL));
	
	DisplayTagAndString(CFSTR("CFURLGetString(CFURLGetBaseURL())"), (CFURLGetBaseURL(testURL) != NULL) ? CFURLGetString(CFURLGetBaseURL(testURL)) : NULL);
	
	tempStr = CFURLCopyScheme(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyScheme()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyNetLocation(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyNetLocation()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyPath(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyPath()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	/* CFURLCopyStrictPath has an isAbsolute output parameter that indicates if the URL's path is absolute */
	tempStr = CFURLCopyStrictPath(testURL, &isAbsolute);
	DisplayTagAndString(CFSTR("CFURLCopyStrictPath()"), tempStr);
	fprintf(stdout, "\t\tisAbsolute = %s\n", isAbsolute ? "TRUE" : "FALSE");
	CF_RELEASE_CLEAR(tempStr);
	
	DisplayFileSystemRepresentation(testURL);
	
	tempStr = CFURLCopyFileSystemPath(testURL, kCFURLPOSIXPathStyle);
	DisplayTagAndString(CFSTR("CFURLCopyFileSystemPath(kCFURLPOSIXPathStyle)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyFileSystemPath(testURL, kCFURLHFSPathStyle);
	DisplayTagAndString(CFSTR("CFURLCopyFileSystemPath(kCFURLHFSPathStyle)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyFileSystemPath(testURL, kCFURLWindowsPathStyle);
	DisplayTagAndString(CFSTR("CFURLCopyFileSystemPath(kCFURLWindowsPathStyle)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	DisplayTagAndString(CFSTR("CFURLHasDirectoryPath()"), CFURLHasDirectoryPath(testURL) ? CFSTR("TRUE") : CFSTR("FALSE"));
	
	tempStr = CFURLCopyLastPathComponent(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyLastPathComponent()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyPathExtension(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyPathExtension()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyResourceSpecifier(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyResourceSpecifier()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyUserName(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyUserName()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyPassword(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyPassword()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyHostName(testURL);
	DisplayTagAndString(CFSTR("CFURLCopyHostName()"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	if ( CFURLGetPortNumber(testURL) != -1 )
	{
		tempStr = CFStringCreateWithFormat(kCFAllocatorDefault, NULL, CFSTR("%d"), CFURLGetPortNumber(testURL));
		DisplayTagAndString(CFSTR("CFURLGetPortNumber()"), tempStr);
		CF_RELEASE_CLEAR(tempStr);
	}
	else
	{
		DisplayTagAndString(CFSTR("CFURLGetPortNumber()"), CFSTR("(no port)"));
	}
	/*
	 * CFURLCopyParameterString, CFURLCopyQueryString, and CFURLCopyFragment all 
	 * have a charactersToLeaveEscaped parameter that controls which, if any,
	 * percent-escaped characters are replaced. NULL means no escape sequences
	 * are removed at all. And empty string means all percent escape sequences
	 * are replaced by their corresponding characters. This example shows the results
	 * using NULL and an empty string.
	 */
	tempStr = CFURLCopyParameterString(testURL, NULL);
	DisplayTagAndString(CFSTR("CFURLCopyParameterString(NULL)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyParameterString(testURL, CFSTR(""));
	DisplayTagAndString(CFSTR("CFURLCopyParameterString(empty)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyQueryString(testURL, NULL);
	DisplayTagAndString(CFSTR("CFURLCopyQueryString(NULL)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyQueryString(testURL, CFSTR(""));
	DisplayTagAndString(CFSTR("CFURLCopyQueryString(empty)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyFragment(testURL, NULL);
	DisplayTagAndString(CFSTR("CFURLCopyFragment(NULL)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	
	tempStr = CFURLCopyFragment(testURL, CFSTR(""));
	DisplayTagAndString(CFSTR("CFURLCopyFragment(empty)"), tempStr);
	CF_RELEASE_CLEAR(tempStr);
	

	/*
	 * For complete control, you can parse the bytes of the URL with the low-level
	 * CFURLGetByteRangeForComponent function. Percent-escaped characters are never
	 * removed by CFURLGetByteRangeForComponent -- your code will need to use
	 * either CFURLCreateStringByReplacingPercentEscapes or
	 * CFURLCreateStringByReplacingPercentEscapesUsingEncoding
	 * to replace whatever percent-escaped characters you want removed.
	 */
	
	/* determine the buffer size needed and allocate it */
	bufferLength = CFURLGetBytes(testURL, NULL, 0);
	buffer = malloc(bufferLength + 1);
	require_action(buffer != NULL, malloc_buffer, err = EXIT_FAILURE);

	/* get the bytes from the URL */
	componentLength = CFURLGetBytes(testURL, buffer, bufferLength);
	require_action(componentLength != -1, CFURLGetBytes, err = EXIT_FAILURE);

	/* null terminate the buffer and display it */
	buffer[componentLength] = 0;
	fprintf(stdout, "URL bytes: \"%s\"\n", buffer);
	
	fprintf(stdout, "Components from CFURLGetByteRangeForComponent:\n");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentScheme, "kCFURLComponentScheme");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentNetLocation, "kCFURLComponentNetLocation");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentPath, "kCFURLComponentPath");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentResourceSpecifier, "kCFURLComponentResourceSpecifier");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentUser, "kCFURLComponentUser");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentPassword, "kCFURLComponentPassword");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentUserInfo, "kCFURLComponentUserInfo");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentHost, "kCFURLComponentHost");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentPort, "kCFURLComponentPort");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentParameterString, "kCFURLComponentParameterString");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentQuery, "kCFURLComponentQuery");
	
	DisplayURLComponent(testURL, buffer, kCFURLComponentFragment, "kCFURLComponentFragment");

CFURLGetBytes:
malloc_buffer:
command_err:
CFStringCreateWithBytes_lastPathComponent:
CFStringCreateWithBytes_pathExtension:
CFStringCreateWithBytes_baseURLString:
	
	/* CFRelease anything left over here */
	CF_RELEASE_CLEAR(urlString);
	CF_RELEASE_CLEAR(baseURLString);
	CF_RELEASE_CLEAR(pathExtension);
	CF_RELEASE_CLEAR(lastPathComponent);
	CF_RELEASE_CLEAR(baseURL);
	CF_RELEASE_CLEAR(testURL);
	CF_RELEASE_CLEAR(tempURL);
	CF_RELEASE_CLEAR(tempStr);
    return ( err );
}
