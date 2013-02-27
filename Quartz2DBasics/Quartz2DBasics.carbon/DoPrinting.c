/*
 
 File: DoPrinting.c
 
 Abstract: Printing code for Carbon project.
 
 Version: <1.0>
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Computer, Inc. ("Apple") in consideration of your agreement to the
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
 Neither the name, trademarks, service marks or logos of Apple Computer,
 Inc. may be used to endorse or promote products derived from the Apple
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
 
 Copyright © 2006 Apple Computer, Inc., All Rights Reserved
 
*/ 



#include "DoPrinting.h"
#include "AppDrawing.h"
#include "UIHandling.h"

// This code only prints one page.
#define NUMDOCPAGES		1

static OSStatus MyDoPrintLoop(PMPrintSession printSession, PMPageFormat pageFormat, 
				    PMPrintSettings printSettings, OSType command);

// -----------------------------------------------------------------------
PMPageFormat CreateDefaultPageFormat(void)
{
    OSStatus err = noErr, tempErr;
    PMPageFormat pageFormat = NULL;
    PMPrintSession printSession;
    err = PMCreateSession(&printSession);
    if(!err){
	err = PMCreatePageFormat(&pageFormat);
	if(err == noErr)
	    err = PMSessionDefaultPageFormat(printSession, pageFormat);

	tempErr = PMRelease(printSession);
	if(!err)err = tempErr;
    }
    if(err){
	fprintf(stderr, "Got an error = %d creating the default page format\n", err);
    }
    return pageFormat;
}

// -----------------------------------------------------------------
OSStatus DoPageSetup(PMPageFormat pageFormat)
{
    OSStatus		err = noErr;
    PMPrintSession printSession;
    err = PMCreateSession(&printSession);
    if(!err){
	Boolean accepted;
	if(!err) // Validate the page format we're going to pass to the dialog code.
	    err = PMSessionValidatePageFormat(printSession, pageFormat, kPMDontWantBoolean);

	if(!err){
	    err = PMSessionPageSetupDialog(printSession, pageFormat, &accepted);
	}
	   
	(void)PMRelease(printSession);
    }
    
    if(err && err != kPMCancel)
	fprintf(stderr, "Got an error %d in Page Setup\n", err);

    return err;
} // DoPageSetup



// -------------------------------------------------------------------------------
OSStatus DoPrint(PMPageFormat pageFormat, OSType drawingCommand)
{
    OSStatus err = noErr;
    UInt32 minPage = 1, maxPage = NUMDOCPAGES;	// One page document printing.
    PMPrintSession printSession;
	
    err = PMCreateSession(&printSession);
    if(err == noErr){
	err = PMSessionValidatePageFormat(printSession, pageFormat, kPMDontWantBoolean);
        if (err == noErr)
        {
	    PMPrintSettings printSettings = NULL;
            err = PMCreatePrintSettings(&printSettings);
            if(err == noErr)
                err = PMSessionDefaultPrintSettings(printSession, printSettings);

            if (err == noErr)
		err = PMSetPageRange(printSettings, minPage, maxPage);

            if (err == noErr)
            {
                Boolean accepted;
		err = PMSessionPrintDialog(printSession, printSettings, pageFormat, &accepted);

		if(!err && accepted){
		    err = MyDoPrintLoop(printSession, pageFormat, printSettings, drawingCommand);
		}
            }
	    if(printSettings)
		(void)PMRelease(printSettings);
        }

        (void)PMRelease(printSession); 
    }
    
    if(err && err != kPMCancel)
	fprintf(stderr, "Got an error %d in DoPrint!\n", err);
    
    return err;
}

// --------------------------------------------------------------------------------------
static OSStatus MyDoPrintLoop(PMPrintSession printSession, PMPageFormat pageFormat, 
				    PMPrintSettings printSettings, OSType drawingType)
{
    OSStatus err = noErr;
    OSStatus tempErr = noErr;
    UInt32 firstPage, lastPage, totalDocPages = NUMDOCPAGES;	// Only print 1 page.
    
    if(!err)
	err = PMGetFirstPage(printSettings, &firstPage);
	
    if (!err)
        err = PMGetLastPage(printSettings, &lastPage);

    if(!err && lastPage > totalDocPages){
        // Don't draw more than the number of pages in our document.
        lastPage = totalDocPages;
    }

	// Tell the printing system the number of pages we are going to print.
    if (!err)		
        err = PMSetLastPage(printSettings, lastPage, false);

    if (!err)
    {
        err = PMSessionBeginCGDocument(printSession, printSettings, pageFormat);
        if (!err){
	    UInt32 pageNumber = firstPage;
	    // Need to check errors from our print loop and errors from the session each
	    // time around our print loop before calling our BeginPageProc.
            while(pageNumber <= lastPage && err == noErr && PMSessionError(printSession) == noErr)
            {
                err = PMSessionBeginPage(printSession, pageFormat, NULL);
                if (!err){
                    CGContextRef printingContext = NULL;
					// Get the printing CGContext to draw to.
                    err = PMSessionGetCGGraphicsContext(printSession, &printingContext);
                    if(!err){
			myDispatchDrawing(printingContext, drawingType);
                    }
                    // We must call EndPage if BeginPage returned noErr.
		    tempErr = PMSessionEndPage(printSession);
                        
		    if(!err)err = tempErr;
                }
		pageNumber++;
            }	// End of while loop.
            
            // We must call EndDocument if BeginDocument returned noErr.
	    tempErr = PMSessionEndDocument(printSession);

	    if(!err)err = tempErr;

	    if(!err)
		err = PMSessionError(printSession);
        }
    }
    return err;
}


