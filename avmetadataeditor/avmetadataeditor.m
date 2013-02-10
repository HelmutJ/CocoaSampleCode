/*
     File: avmetadataeditor.m
 Abstract: 
 
 File:		avmetadataeditor.m
 
 Description: Command-line tool for editing metadata
 
 
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
 
 Copyright (C) 2011 Apple Inc. All Rights Reserved.
 
 */

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <dispatch/dispatch.h>

#import <getopt.h>

static void PrintUsage()
{
	printf("\n\nUsage:");
	printf("\navmetadataeditor [-w] [-a] [ <options> ] src dst");
	printf("\navmetadataeditor [-p] [-o] [ <options> ] src");
	printf("\nsrc is a path to a local file.");
	printf("\ndst is a path to a destination file.");
	
	printf("\nOptions:\n");
	printf("\n  -w, --write-metadata=PLISTFILE");
	printf("\n\t\t  Use a PLISTFILE as metadata for the destination file");
	printf("\n  -a, --append-metadata=PLISTFILE");
	printf("\n\t\t  Use a PLISTFILE as metadata to merge with the source metadata for the destination file");
	printf("\n  -p, --print-metadata=PLISTFILE");
	printf("\n\t\t  Write in a PLISTFILE the metadata from the source file");
	printf("\n  -f, --file-type=UTI");
	printf("\n\t\t  Use UTI as output file type");
	printf("\n  -o, --output-metadata");
	printf("\n\t\t  Output the metadata from the source file");
	printf("\n  -d, --description-metadata");
	printf("\n\t\t  Output the metadata description from the source file");	
	printf("\n  -q, --quicktime-metadata");
	printf("\n\t\t  Quicktime metadata format");
	printf("\n  -u, --quicktime-user-metadata");
	printf("\n\t\t  Quicktime user metadata format");
	printf("\n  -i, --iTunes-metadata");
	printf("\n\t\t  iTunes metadata format");		
	printf("\n  -h, --help");
	printf("\n\t\t  Print this message and exit\n");
	exit(1);
}

static NSString * stringForOSType(OSType theOSType);
static NSString * stringForDataDescription(NSData *data);
static void printMetadata(AVURLAsset *asset, BOOL doDescriptionOut);
static void printMetadataItems(NSArray *items, NSString *metadataFormat, BOOL doDescriptionOut);
static void printMetadataItemsToURL(NSArray *items, NSString *metadataFormat, NSURL *printURL);
static NSArray * metadataFromAssetDictionary(NSArray *sourceMetadata, NSDictionary *metadataDict, BOOL editingMode, NSString *metadataFormat, NSString *metadataKeySpace);
static BOOL processing(NSURL *sourceURL, NSURL *destURL, NSString *outputFileType, NSURL *printURL, NSDictionary *writeMetadata, NSDictionary *appendMetadata, BOOL doPrintOut, BOOL doDescriptionOut, NSString *metadataFormat, NSString *metadataKeySpace);


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	static struct option longopts[] = {
		{"write-metadata", required_argument, NULL, 'w'},
		{"append-metadata", required_argument, NULL, 'a'},
		{"print-metadata", required_argument, NULL, 'p'},
		{"file-type", required_argument, NULL, 'f'},
		{"output-metadata", no_argument, NULL, 'o'},
		{"description-metadata", no_argument, NULL, 'd'},
		{"quicktime-metadata", no_argument, NULL, 'q'},
		{"quicktime-user-metadata", no_argument, NULL, 'u'},
		{"itunes-metadata", no_argument, NULL, 'i'},		
		{"help", no_argument, NULL, 'h'},
		{0, 0, 0, 0}
	};
	const char *shortopts = "w:a:p:f:odquih";	
	
	int c = -1;
	
	NSURL *sourceURL = nil;
	NSURL *destURL = nil;
	NSURL *printURL = nil;
	NSString *outputFileType = AVFileTypeQuickTimeMovie;
	
	NSDictionary *writeMetadata = nil;
	NSDictionary *appendMetadata = nil;
	NSString *metadataFormat = nil;
	NSString *metadataKeySpace = nil;
	
	BOOL doPrintOut = NO;
	BOOL doDescriptionOut = NO;
	BOOL needDest = NO;
	
	while ((c = getopt_long(argc, (char * const *)argv, shortopts, longopts, NULL)) != -1) {
		switch (c)
		{
			case 'w':
			{			
				needDest = YES;
				writeMetadata = [NSDictionary dictionaryWithContentsOfFile:[fm stringWithFileSystemRepresentation:optarg length:strlen(optarg)]];
				if (!writeMetadata) {
					printf("\nError: '%s' does not point to a valid property list file", optarg);
					PrintUsage();
				}
				break;
			}
			case 'a':
			{			
				needDest = YES;
				appendMetadata = [NSDictionary dictionaryWithContentsOfFile:[fm stringWithFileSystemRepresentation:optarg length:strlen(optarg)]];
				if (!appendMetadata) {
					printf("\nError: '%s' does not point to a valid property list file", optarg);
					PrintUsage();
				}
				break;
			}				
			case 'p':
			{				
				printURL = [NSURL fileURLWithPath:[fm stringWithFileSystemRepresentation:optarg length:strlen(optarg)] isDirectory:NO];
				break;
			}
			case 'o':
			{
				doPrintOut = YES;
				break;
			}
			case 'd':
			{
				doDescriptionOut = YES;
				break;	
			}
			case 'q':
			{
				/*
				 QuickTime metadata format and keyspace
				 */					
				metadataFormat = AVMetadataFormatQuickTimeMetadata;
				metadataKeySpace = AVMetadataKeySpaceQuickTimeMetadata;
				break;	
			}
			case 'u':
			{
				/*
				 QuickTime user metadata (udta) format and keyspace
				 */					
				metadataFormat = AVMetadataFormatQuickTimeUserData;
				metadataKeySpace = AVMetadataKeySpaceQuickTimeUserData;
				break;	
			}
			case 'i':
			{
				/*
				 iTunes format and keyspace
				 */					
				metadataFormat = AVMetadataFormatiTunesMetadata;
				metadataKeySpace = AVMetadataKeySpaceiTunes;
				break;
			}
			case 'f':
			{
				/*
				 Output file format use during export, could be the following:
				 com.apple.quicktime-movie
				 public.mpeg-4
				 com.apple.m4v-video
				 com.apple.m4a-audio
				 public.3gpp				 
				 */					
				outputFileType = [NSString stringWithCString:optarg encoding:NSMacOSRomanStringEncoding];
				if (!outputFileType)
				{
					printf("Error: '%s' is not a valid UTI\n", optarg);
					PrintUsage();
				}
				break;
			}				
			case 'h':
			default:	
				PrintUsage();
				break;
		}
	}
	
	if (argc <= 2) {
		printf("\nMissing arguments");
		PrintUsage();
	}	
	
	int nextArgIndex = optind;
	if (nextArgIndex >= argc) {
		printf("\nMissing source");
		PrintUsage();
	}
	NSString *str = [fm stringWithFileSystemRepresentation:argv[nextArgIndex] length:strlen(argv[nextArgIndex])];
	sourceURL = [NSURL URLWithString:str];
	if (![sourceURL scheme]) {
		// No URL scheme, assuming file path
		sourceURL = [NSURL fileURLWithPath:str isDirectory:NO];
	}				
	if (nil == sourceURL) {
		printf("\nInvalid source");
		PrintUsage();
	}
	++nextArgIndex;
	
	if (needDest) {
		if (nextArgIndex >= argc) {
			printf("\nMissing destination");
			PrintUsage();
		}
		destURL = [NSURL fileURLWithPath:[fm stringWithFileSystemRepresentation:argv[nextArgIndex] length:strlen(argv[nextArgIndex])] isDirectory:NO];
		if (nil == destURL) {
			printf("\nInvalid destination");
			PrintUsage();
		}
	}
	
	BOOL result = processing(sourceURL, destURL, outputFileType, printURL, writeMetadata, appendMetadata, doPrintOut, doDescriptionOut, metadataFormat, metadataKeySpace);
	
	[pool drain];
	
    return (!result);
}
/*
 Get a string from a 4cc				 
 */	
NSString * stringForOSType(OSType theOSType)
{
	size_t len = sizeof(OSType);
	long addr = (unsigned long)&theOSType;
	char cstring[5];
	
	len = (theOSType >> 24) == 0 ? len - 1 : len;
	len = (theOSType >> 16) == 0 ? len - 1 : len;
	len = (theOSType >>  8) == 0 ? len - 1 : len;
	len = (theOSType >>  0) == 0 ? len - 1 : len;
	
	addr += (4 - len);
	
	theOSType = EndianU32_NtoB(theOSType);		// strings are big endian	
	
	strncpy(cstring, (char *)addr, len);
	cstring[len] = 0;
	
	return [NSString stringWithCString:(char *)cstring encoding:NSMacOSRomanStringEncoding];
}

/*
 Get a string from a NSData value formatted as follow: [ data length = ??, bytes = 0x?? ... ?? ]
 */
static NSString * stringForDataDescription(NSData *data)
{
	NSMutableString *str = [NSMutableString stringWithCapacity:64];
	NSUInteger length = [data length];
	const unsigned char *bytes = (const unsigned char *)[data bytes];
	int i;
	
	[str appendFormat:@"[ data length = %u, bytes = 0x", (unsigned int)length];
	
	// Dump 24 bytes of data in hex
	if (length <= 24) {
		for (i = 0; i < length; i++)
			[str appendFormat:@"%02x", bytes[i]];
	} else {
		for (i = 0; i < 16; i++)
			[str appendFormat:@"%02x", bytes[i]];
		[str appendFormat:@" ... "];
		for (i = length - 8; i < length; i++)
			[str appendFormat:@"%02x", bytes[i]];
	}
	[str appendFormat:@" ]"];
	
	return str;
}

static void printMetadata(AVURLAsset *asset, BOOL doDescriptionOut)
{
	/*
	 Print the common metadata				 
	 */	
	NSArray *commonMetadata = [asset commonMetadata];
	if ([commonMetadata count] > 0) {
		printf("\n\n\nCommon metadata:\n");
		printMetadataItems(commonMetadata, nil, doDescriptionOut);			
	}
	/*
	 Print all the metadata	formats			 
	 */		
	for (NSString *format in [asset availableMetadataFormats]) {
		NSArray *items = [asset metadataForFormat:format];
		if ([items count] > 0) {
			printf("\n\n\nMetadata format: %s\n", [format UTF8String]);
			printMetadataItems(items, format, doDescriptionOut);
		}
	}
	
	printf("\n\n");
}

static void printMetadataItems(NSArray *items, NSString *metadataFormat, BOOL doDescriptionOut)
{
	for (AVMetadataItem *item in items) {
		if (doDescriptionOut) {
			printf("\n%s", [[item description] UTF8String]);
		}
		if (nil != metadataFormat) {
			NSString *keyAsString = nil;
			if ([[item key] isKindOfClass:[NSString class]]) {
				keyAsString  = (NSString *)[item key];
			}
			else if ([[item key] isKindOfClass:[NSNumber class]]) {
				NSNumber *keyAsNumber = (NSNumber *)[item key];
				keyAsString = stringForOSType([keyAsNumber unsignedIntValue]);
			}
			else if ([[item key] isKindOfClass:[NSObject class]]) {
				keyAsString = [(NSObject *)[item key] description];
			}	
			id value = [item value];
			if ([value isKindOfClass:[NSData class]]) {
				printf("\n%s: %s", [keyAsString UTF8String], [stringForDataDescription(value) UTF8String]);
			}
			else {
				printf("\n%s: %s", [keyAsString UTF8String], [[item stringValue] UTF8String]);
			}
		}
		else {
			printf("\n%s: %s", [[item commonKey] UTF8String], [[item stringValue] UTF8String]);
		}
	}	
}

static void printMetadataItemsToURL(NSArray *items, NSString *metadataFormat, NSURL *printURL)
{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];		
	if ([items count]) {
		for (AVMetadataItem *item in items) {
			if (nil != metadataFormat) {
				NSString *keyAsString = nil;
				if ([[item key] isKindOfClass:[NSString class]]) {
					keyAsString  = (NSString *)[item key];
				}
				else if ([[item key] isKindOfClass:[NSNumber class]]) {
					NSNumber *keyAsNumber = (NSNumber *)[item key];
					keyAsString = stringForOSType([keyAsNumber unsignedIntValue]);
				}
				else if ([[item key] isKindOfClass:[NSObject class]]) {
					keyAsString = [(NSObject *)[item key] description];
				}					
				[dict setObject:[item value] forKey:keyAsString];
			}
			else {
				[dict setObject:[item value] forKey:[item commonKey]];				
			}
		}		
	}		
	[dict writeToURL:printURL atomically:YES];
}

static NSArray * metadataFromAssetDictionary(NSArray *sourceMetadata, NSDictionary *metadataDict, BOOL editingMode, NSString *metadataFormat, NSString *metadataKeySpace)
{
	NSMutableDictionary *mutableMetadataDict = [NSMutableDictionary dictionaryWithDictionary:metadataDict];
	NSMutableArray *newMetadata = [NSMutableArray array];
	if (editingMode) {

		if ([sourceMetadata count]) {
			/*
			 Find the keys that exist in the dictionary and the metadata				 
			 */	
			for (AVMetadataItem *item in sourceMetadata) {
				
				AVMutableMetadataItem *newItem = [item mutableCopy];
				if (nil != metadataFormat) {
					id key = newItem.key;
					NSString *keyAsString = nil;
					if ([key isKindOfClass:[NSString class]]) {
						keyAsString  = (NSString *)key;
					}
					else if ([key isKindOfClass:[NSNumber class]]) {
						NSNumber *keyAsNumber = (NSNumber *)key;
						keyAsString = stringForOSType([keyAsNumber unsignedIntValue]);
					}
					else if ([key isKindOfClass:[NSObject class]]) {
						keyAsString = [(NSObject *)key description];
					}	
					/*
					 If the key is present in the dictionary, change the value to the one from the dictionary				 
					 */	
					if ([mutableMetadataDict valueForKey:keyAsString]) {
						[newItem setValue:[mutableMetadataDict valueForKey:keyAsString]];
						[mutableMetadataDict removeObjectForKey:keyAsString];
					}
				}
				else {
					/*
					 If the key is present in the dictionary, change the value to the one from the dictionary				 
					 */						
					id commonKey = newItem.commonKey;
					if ([mutableMetadataDict valueForKey:commonKey]) {
						[newItem setValue:[mutableMetadataDict valueForKey:commonKey]];
						[mutableMetadataDict removeObjectForKey:commonKey];
					}					
				}
				if (newItem.value) {
					[newMetadata addObject:newItem];
				}
				[newItem release];
			}		
		}	
	}
	
	for (id key in [mutableMetadataDict keyEnumerator]) {		
		id value = [mutableMetadataDict objectForKey:key];		
		if (value) {
			AVMutableMetadataItem *newItem = [AVMutableMetadataItem metadataItem];
			[newItem setKey:key];
			if (nil != metadataKeySpace) {
				[newItem setKeySpace:metadataKeySpace];
			}
			else {
				[newItem setKeySpace:AVMetadataKeySpaceCommon];				
			}
			[newItem setLocale:[NSLocale currentLocale]];
			[newItem setValue:value];
			[newItem setExtraAttributes:nil];
			[newMetadata addObject:newItem];
		}
	}		
	return newMetadata;
}

static BOOL processing(NSURL *sourceURL, NSURL *destURL, NSString *outputFileType, NSURL *printURL, NSDictionary *writeMetadata, NSDictionary *appendMetadata, BOOL doPrintOut, BOOL doDescriptionOut, NSString *metadataFormat, NSString *metadataKeySpace)
{
	AVURLAsset *asset = [AVURLAsset URLAssetWithURL:sourceURL options:nil];
	if (!asset) {
		printf("\nInvalid source, asset creation failure");
		return NO;
	}
	/*
	 Print to the standard output the metadata from the source URL				 
	 */		
	if (doPrintOut || doDescriptionOut) {
		printMetadata(asset, doDescriptionOut);
	}
	
	NSArray *sourceMetadata = nil;
	if (nil != metadataFormat) {
		sourceMetadata = [asset metadataForFormat:metadataFormat];
	}
	else {
		sourceMetadata = [asset commonMetadata];		
	}
	/*
	 Save to a plist the metadata from the source URL			 
	 */		
	if (printURL) {
		printMetadataItemsToURL(sourceMetadata, metadataFormat, printURL);
	}
	if (!destURL)
		return YES;
	
	if (![asset isExportable])
		return NO;
	if (nil == writeMetadata && nil == appendMetadata)
		return NO;

	/*
	 Create an export session to export the new metadata 			 
	 */		
	AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:asset presetName:AVAssetExportPresetPassthrough];
	if (![[session supportedFileTypes] containsObject:outputFileType])
		return NO;
	
	[session setOutputFileType:outputFileType];
	[session setOutputURL:destURL];	
	
	if (writeMetadata) {
		[session setMetadata:metadataFromAssetDictionary(sourceMetadata, writeMetadata, NO, metadataFormat, metadataKeySpace)];
	}
	else {
		[session setMetadata:metadataFromAssetDictionary(sourceMetadata, appendMetadata, YES, metadataFormat, metadataKeySpace)];
	}	
	
	dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
	
	__block NSString *stringError = nil;
	__block BOOL succeeded = NO;
	[session exportAsynchronouslyWithCompletionHandler:^{ 
		
		if (AVAssetExportSessionStatusCompleted == session.status) {
			succeeded = YES;
		}
		else {
			succeeded = NO;
			if (session.error)
				stringError = [[session.error localizedDescription] retain];
			else
				stringError = @"unknown";
		}
		dispatch_semaphore_signal(semaphore);
	}];
	
	printf("\n0--------------------100%%\n");
	float progress = 0.; 
	long resSemaphore = 0;
	/*
	 Monitor the progress			 
	 */	
	do { 	
		resSemaphore = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, NSEC_PER_SEC));		
		float curProgress = session.progress;
		while (curProgress > progress) {
			fprintf(stderr, "*"); // Force to be flush without end of line
			progress += 0.05;
		}
	} while( resSemaphore );
	
	if (succeeded) {
		printf("\nSuccess\n");
	}
	else {
		printf("\nError: %s", [stringError UTF8String]); 
		printf("\nFailure\n");
		[stringError release];
	}
	dispatch_release(semaphore);	
	return succeeded;
}

