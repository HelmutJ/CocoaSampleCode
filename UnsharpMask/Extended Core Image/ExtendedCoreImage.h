/*
 ExtendedCoreImage.h
 ExtendedCoreImage

 Copyright (c) 2005, Apple Computer, Inc., all rights reserved.
*/

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface CIImage (WWDCAutomatorDemo)

- (NSURL *)fileURL;
- (void)setFileURL:(NSURL *)url;

@end
