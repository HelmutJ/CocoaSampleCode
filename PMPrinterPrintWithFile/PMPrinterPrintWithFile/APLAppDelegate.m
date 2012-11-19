/*
     File: APLAppDelegate.m
 Abstract: Application delegate object that implements all the required printing functionality.
  Version: 2.0
 
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
 
 Copyright (C) 2012 Apple Inc. All Rights Reserved.
 
 */

#import "APLAppDelegate.h"
#import <ApplicationServices/ApplicationServices.h>


@interface APLAppDelegate ()

@property (strong) IBOutlet NSWindow *window;

@property (weak) IBOutlet NSMatrix *radioMatrix;
@property (nonatomic) NSPrintInfo *printInfo;

@end


@implementation APLAppDelegate


- (NSPrintInfo *)printInfo {
    
    if (_printInfo == nil) {
        _printInfo = [[NSPrintInfo alloc] init];
    }
    return _printInfo;
}


- (IBAction)print:(id)sender {
    
    
    NSPrintPanel *printPanel = [NSPrintPanel printPanel];
    /*
     Add the Show Paper Size option to default options for the print dialog.
     */
    NSPrintPanelOptions options = [printPanel options] | NSPrintPanelShowsPaperSize;
    [printPanel setOptions:options];
    
    [printPanel beginSheetWithPrintInfo:self.printInfo modalForWindow:self.window delegate:self didEndSelector:@selector(printPanelDidEnd:returnCode:contextInfo:) contextInfo:NULL];
}


- (void)printPanelDidEnd:(NSPrintPanel *)printPanel returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo {
    
    if (returnCode != NSOKButton) {
        return;
    }
    
    /*
     Set the file and corresponding MIME type based on radio selection.
     
     This sample supports PostScript and JPEG files; these are just two of a number of MIME types, for example:
     
     –application/postscript // We insert the PS for the PMPrintSettings into the PostScript stream.
     –application/vnd.cups-postscript // Raw postscript/finished postscript.  We don't insert anything
     –application/pdf // PDF document
     –image/gif, image/jpeg, image/tiff // Images
     –text/plain, text/rtf, text/html // Text
     –application/vnd.cups-raw //Raw printer commands and escape codes, mainly for the printer venders
     –and more...
     */
    
    CFURLRef fileURL = NULL;
    CFStringRef mimeType = NULL;
    NSBundle *mainBundle = [NSBundle mainBundle];
    
    // Obtain the print settings from the printInfo.
    PMPrintSettings printSettings = [self.printInfo PMPrintSettings];

    if ([self.radioMatrix selectedRow] == 0) {
        // Selected the PostScript file.
        fileURL = (__bridge CFURLRef)[mainBundle URLForResource:@"testps" withExtension:@"ps"];
        mimeType = CFSTR("application/postscript");
    }
    else {
        /*
         Selected the JPEG file.
         For image files, tell the printing system to fit the image to the page.
         */
        PMPrintSettingsSetValue(printSettings, kPMFitToPageKey, CFSTR("true"), false);
        fileURL = (__bridge CFURLRef)[mainBundle URLForResource:@"testImage" withExtension:@"jpg"];
        mimeType = CFSTR("image/jpeg");
    }
    
    
    // Obtain the print session from the printInfo.
    PMPrintSession printSession = [self.printInfo PMPrintSession];
    PMDestinationType printDestination = 0;
    OSStatus status = noErr;

    // Verify that the destination is the printer.
    status = PMSessionGetDestinationType(printSession, printSettings, &printDestination);
    
    if ((status != noErr) || (printDestination != kPMDestinationPrinter)) {
        
        NSLog(@"Either got an error from PMSessionGetDestinationType or the print destination wasn't kPMDestinationPrinter");
        return;
    }
    
    // The destination printer is needed by PMPrinterPrintWithFile and related functions.
    PMPrinter currentPrinter = NULL;
    status = PMSessionGetCurrentPrinter(printSession, &currentPrinter);
    
    if (status != noErr) {
        
        NSLog(@"Got an error from PMSessionGetCurrentPrinter (%d)", status);
        return;
    }
    
    /*
     One reason PMPrinterPrintWithFile may fail is if the specified printer can not handle the file's mime type. Use PMPrinterGetMimeTypes() to check whether a mime type is supported.
     */
    CFArrayRef mimeTypes;
    status = PMPrinterGetMimeTypes(currentPrinter, printSettings, &mimeTypes);
    
    if (status == noErr && mimeTypes != NULL) {
        
        CFIndex arrayCount = CFArrayGetCount(mimeTypes);
        if (CFArrayContainsValue(mimeTypes, CFRangeMake(0, arrayCount), mimeType)) {
            
            // Obtain the page format from the printInfo.
            PMPageFormat pageFormat =  [self.printInfo PMPageFormat];

            status = PMPrinterPrintWithFile(currentPrinter, printSettings, pageFormat, mimeType, fileURL);
            if (status != noErr) {
                NSLog(@"PMPrinterPrintWithFile returned error %d", status);
            }
        }
        else {
            
            NSLog(@"MIME type %@ isn't supported by the printer", (__bridge NSString *)mimeType);
        }
    }
}


@end
