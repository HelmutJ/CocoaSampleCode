/*
	    File: AppController.m
	Abstract: View and Controller classes.
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

#import "AppController.h"
#import "FastImagePlugIn.h"
#import "ArgumentKeys.h"

static GLsizei					_textureWidth,
								_textureHeight;
static CGColorSpaceRef			_textureColorSpace;
static CGImageRef				_textureImage;
static void*					_textureBuffer;
static CGContextRef				_textureContext;

@implementation AppView

- (BOOL) renderAtTime:(NSTimeInterval)time arguments:(NSDictionary*)arguments
{
	CGLContextObj				cgl_ctx = [[self openGLContext] CGLContextObj];
	CGRect						bounds = CGRectMake(0, 0, CGImageGetWidth(_textureImage), CGImageGetHeight(_textureImage));
	NSMutableDictionary*		newArguments;
	GLuint						name;
	
	/* Draw a new image in the CGContext */
	CGContextClearRect(_textureContext, bounds);
	CGContextSaveGState(_textureContext);
	CGContextTranslateCTM(_textureContext, bounds.size.width / 2.0, bounds.size.height / 2.0);
	CGContextRotateCTM(_textureContext, time * 180.0 / 180.0 * M_PI);
	CGContextTranslateCTM(_textureContext, -bounds.size.width / 2.0, -bounds.size.height / 2.0);
	CGContextDrawImage(_textureContext, bounds, _textureImage);
	CGContextRestoreGState(_textureContext);
	
	/* Create an OpenGL texture and upload the CGContext content into it */
	glGenTextures(1, &name);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, name);
	glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA8, _textureWidth, _textureHeight, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, _textureBuffer);
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	if(glGetError()) {
		glDeleteTextures(1, &name);
		return NO;
	}
	
	/* Override the arguments passed to the patches so that the unique FastImagePlugIn instance can retrieve the texture, take ownership of it and outputs it as an optimal image for Quartz Composer */
	newArguments = [NSMutableDictionary dictionaryWithDictionary:arguments];
	[newArguments setObject:[NSNumber numberWithUnsignedInt:name] forKey:kArgumentKey_TextureName];
	[newArguments setObject:[NSNumber numberWithUnsignedInt:_textureWidth] forKey:kArgumentKey_TextureWidth];
	[newArguments setObject:[NSNumber numberWithUnsignedInt:_textureHeight] forKey:kArgumentKey_TextureHeight];
#if __BIG_ENDIAN__
	[newArguments setObject:QCPlugInPixelFormatARGB8 forKey:kArgumentKey_TextureFormat];
#else
	[newArguments setObject:QCPlugInPixelFormatBGRA8 forKey:kArgumentKey_TextureFormat];
#endif
	[newArguments setObject:(id)_textureColorSpace forKey:kArgumentKey_TextureColorSpace];
	
	/* Call super to perform rendering */
	return [super renderAtTime:time arguments:newArguments];
}

@end

@implementation AppController

+ (void) initialize
{
	/* Since we have the FastImagePlugIn built-in, register it with Quartz Composer unless we happen to have it installed for development reasons */
	if(![[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Graphics/Quartz Composer Plug-Ins/FastImage.plugin"] && ![[NSFileManager defaultManager] fileExistsAtPath:[@"~/Library/Graphics/Quartz Composer Plug-Ins/FastImage.plugin" stringByExpandingTildeInPath]])
	[QCPlugIn registerPlugInClass:[FastImagePlugIn class]];
	else
	NSLog(@"\"FastImage\" is already installed in the system as a stand-alone plug-in");
}

- (void) applicationWillFinishLaunching:(NSNotification*)notification
{
	NSString*					path;
	CGImageSourceRef			source;
	
	/* Create CGImage from image file */
	path = [[NSBundle mainBundle] pathForResource:@"Image" ofType:@"png"];
	if(path == nil)
	return;
	source = CGImageSourceCreateWithURL((CFURLRef)[NSURL fileURLWithPath:path], NULL);
	if(source == NULL)
	return;
	_textureImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
	CFRelease(source);
	if(_textureImage == NULL)
	return;
	
	/* Create CGContext */
	_textureColorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
	_textureWidth = CGImageGetWidth(_textureImage);
	_textureHeight = CGImageGetHeight(_textureImage);
	_textureBuffer = malloc(_textureHeight * _textureWidth * 4);
	if(_textureBuffer == NULL)
	return;
	_textureContext = CGBitmapContextCreate(_textureBuffer, CGImageGetWidth(_textureImage), CGImageGetHeight(_textureImage), 8, _textureWidth * 4, _textureColorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
	if(_textureContext == NULL)
	return;
	
	/* Load composition on QCView and starts rendering - NOTE: The loaded composition must have a FastImagePlugIn patch or the OpenGL textures will leak */
	[qcView loadCompositionFromFile:[[NSBundle mainBundle] pathForResource:@"Composition" ofType:@"qtz"]];
	[qcView startRendering];
}

- (void) windowWillClose:(NSNotification*)notification
{
	[NSApp terminate:nil];
}

@end
