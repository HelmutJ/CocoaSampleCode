/*
 ExtendedCoreImage.m
 ExtendedCoreImage

 Copyright (c) 2005, Apple Computer, Inc., all rights reserved.
*/

#import "ExtendedCoreImage.h"
#import <QuartzCore/CIImagePrivate.h>

@implementation CIImage (WWDCAutomatorDemo)

- (NSURL *)fileURL
{
	id userInfo = [self userInfo];
	if ([userInfo isKindOfClass:[NSURL class]])
	{
		return (NSURL *)userInfo;
	}
	
	return nil;
}

- (void)setFileURL:(NSURL *)url
{
	[self setUserInfo:url];
}

@end
