/*
 
     File: ImageDocument.m 
 Abstract:  
 ImageDocument is an NSDocument subclass. Displays a snapshot image of the screen in 
 the document window. Implements 'Save', 'Save As...' menu items and contains code to
 save the document image contents to a file on disk in any of the supported image
 formats (jpeg, tiff, png).
  
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

#import "ImageDocument.h"

NSString * const ImageDocName = @"ImageDocument";

@implementation ImageDocument


#pragma mark NSDocument overrides

- (id)initWithType:(NSString *)typeName error:(NSError **)outError
{
    self = [super init];
    if (self) 
    {
        image = nil;
        /* Mark document contents as initially overwritten, so if the document is closed the user
          will be prompted to save. */
        [self updateChangeCount:NSSaveOperation];
    }
    
    return self;
}

/* Returns the name of the nib file that stores the window associated with the receiver. */
- (NSString *)windowNibName
{
    return ImageDocName;
}

/* Writes the contents of the document to a file or file package located by a URL, formatted to a specified type. */
- (BOOL)writeToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName error:(NSError **)outError
{
    BOOL status = NO;
    CGImageDestinationRef dest = nil;
    
    /* Create a new CFStringRef containing a uniform type identifier (UTI) that is the equivalent
     of the passed file extension. */
    CFStringRef utiRef = UTTypeCreatePreferredIdentifierForTag(
                                                               kUTTagClassFilenameExtension,
                                                               (CFStringRef) typeName,
                                                               kUTTypeData
                                                               );
    if (utiRef==nil) 
    {
        goto bail;
    }

    /* Create an image destination writing to absoluteURL. */
    dest = CGImageDestinationCreateWithURL((CFURLRef)absoluteURL, utiRef, 1, nil);
    CFRelease(utiRef);
    
    if (dest==nil)
    {
        goto bail;        
    }

    /* The image snapshot associated with the document. */
    CGImageRef docImage = [self currentCGImage];
    if (docImage==nil)
    {
        goto bail;        
    }

    /* Set the image in the image destination to be our document image snapshot. */
    CGImageDestinationAddImage(dest, docImage, NULL);

    /* Writes image data to the URL associated with the image destination. */
    status = CGImageDestinationFinalize(dest);
    
bail:
    if (dest) 
    {
        CFRelease(dest);
    }
    return status;
}

- (BOOL)saveToURL:(NSURL *)absoluteURL ofType:(NSString *)typeName forSaveOperation:(NSSaveOperationType)saveOperation error:(NSError **)outError
{
    NSString *docTypeName = [absoluteURL pathExtension];
    /* Was an extension specified? */
    if ([docTypeName isEqualToString:@""]) 
    {
        /* No extension, so use jpeg. */
        docTypeName = @"jpg";
        return ([self writeToURL:[absoluteURL URLByAppendingPathExtension:docTypeName] ofType:docTypeName error:outError]);
    }

    return ([self writeToURL:absoluteURL ofType:docTypeName error:outError]);
}


/* Present the save panel to allow the user to save the document window contents to
 an image file on disk. */
-(void)doSaveDocument:(NSSaveOperationType)saveOperation
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    /* The supported file types for the save operation. */
    NSArray *fileTypes = [self writableTypesForSaveOperation:saveOperation];
    [savePanel setAllowedFileTypes:fileTypes]; 
    [savePanel setExtensionHidden:NO];
    /* Default save file name. */
    [savePanel setNameFieldStringValue:@"Snapshot.jpg"];

    /* Run the save dialog. */
    [savePanel beginSheetModalForWindow:[self windowForSheet] completionHandler:^(NSInteger result) 
    {
        /* User pressed OK button? */
        if (NSFileHandlingPanelOKButton == result)
        {
            NSURL *URL = [savePanel URL];
            NSString *pathExtension = [URL pathExtension];
            /* Use .jpg file extension if none was specified. */
            if (YES==[pathExtension isEqualToString:@""]) 
            {
                pathExtension = @"jpg";
                URL = [URL URLByAppendingPathExtension:pathExtension];
            }
            
            NSError *err = nil;
            /* Write the image file to disk. */
            BOOL success = [self writeToURL:URL ofType:pathExtension error:&err];    
            /* Error? */
            if (!success)
            {
                NSLog(@"%@",[err localizedDescription]);                
            }
            else  
            {
                NSArray *winControllers = [self windowControllers];
                    /* Set window title to saved filename. */
                [[[winControllers objectAtIndex:0] window] setTitle:[savePanel nameFieldStringValue]];
                
                [self updateChangeCount:NSChangeCleared];                
            }
        }
    }];
}

/* Called when the File->Save menu item is selected for the document. */
- (IBAction)saveDocument:(id)sender
{    
    [self doSaveDocument:NSSaveOperation];
}

/* Called when the File->Save As menu item is selected for the document. */
- (IBAction)saveDocumentAs:(id)sender
{
    [self doSaveDocument:NSSaveAsOperation];
}

/* 
 Validates the specified user interface items. 
 (NOTE: The File Owner's delegate must be set in IB in order for this method to be called)
 */
- (BOOL)validateUserInterfaceItem:(id <NSValidatedUserInterfaceItem>)item
{
    SEL action = [item action];

    if (action == @selector(saveDocument:) && !([self isDocumentEdited]))
    {
        return NO;
    }
    else
    {
        return YES;
    }

    if (action == @selector(saveDocumentAs:) || action == @selector(pageSetup:))
    {
        return YES;
    }

    return [super validateUserInterfaceItem:item];
}

#pragma mark Document Display

/* The image associated with and displayed in the document. */
- (CGImageRef)currentCGImage
{
    return image;
}

/* Setter for document image.*/
-(void)setCGImage:(CGImageRef)anImage
{
    if (image)
    {
        CFRelease(image);
    }
    
    /* Save new image. */
    image = (CGImageRef)CFRetain(anImage);
    
    /* Resize the image view. */
    CGSize imageSize = CGSizeMake (
                                   CGImageGetWidth(anImage),
                                   CGImageGetHeight(anImage)
                                   );
    NSSize newSize = NSSizeFromCGSize(imageSize);
    [imageView setFrameSize:newSize];
    
    /* Mark image view as needing display. */
    [imageView setNeedsDisplay:YES];
}

/* Getter for image size. */
- (CGSize)imageSize
{
    if (image) 
    {
        return CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
    }
    
    return CGSizeMake(0, 0);
}

@end
