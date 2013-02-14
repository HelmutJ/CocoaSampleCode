/*
 
 File: MyOpenGLView.m
 
 Abstract: An NSOpenGLView subclass that demonstrates fundamental techniques 
 to obtain optimal textuture upload performance.
 
 Version: 1.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by
 Apple Inc. ("Apple") in consideration of your agreement to the
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
 Neither the name, trademarks, service marks or logos of Apple Inc.
 may be used to endorse or promote products derived from the Apple
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
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "MyOpenGLView.h"
#import <OpenGL/glu.h>

@interface MyOpenGLView (PrivateMethods)

- (void) initGL;
- (BOOL) initImageData;
- (void) loadTexturesWithClientStorage;
- (void) drawView;

@end

@implementation MyOpenGLView

- (CVReturn) getFrameForTime:(const CVTimeStamp*)outputTime
{
	// There is no autorelease pool when this method is called because it will be called from a background thread
	// It's important to create one or you will leak objects
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self drawView];
	
	[pool release];
    return kCVReturnSuccess;
}

// This is the renderer output callback function
static CVReturn MyDisplayLinkCallback(CVDisplayLinkRef displayLink, const CVTimeStamp* now, const CVTimeStamp* outputTime, CVOptionFlags flagsIn, CVOptionFlags* flagsOut, void* displayLinkContext)
{
    CVReturn result = [(MyOpenGLView*)displayLinkContext getFrameForTime:outputTime];
    return result;
}

- (id) initWithFrame:(NSRect)frameRect
{
    NSOpenGLPixelFormatAttribute attrs[] =
    {
		NSOpenGLPFAAccelerated,
		NSOpenGLPFANoRecovery,
		NSOpenGLPFADoubleBuffer,
		NSOpenGLPFADepthSize, 24,
		0
    };
	
    NSOpenGLPixelFormat *pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
	
    if (!pf)
		NSLog(@"No OpenGL pixel format");
	
    if (self = [super initWithFrame:frameRect pixelFormat:[pf autorelease]])
	{
		[self initGL];
		
		// Create a display link capable of being used with all active displays
		CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
		
		// Set the renderer output callback function
		CVDisplayLinkSetOutputCallback(displayLink, &MyDisplayLinkCallback, self);
		
		// Set the display link for the current renderer
		CGLContextObj cglContext = [[self openGLContext] CGLContextObj];
		CGLPixelFormatObj cglPixelFormat = [[self pixelFormat] CGLPixelFormatObj];
		CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(displayLink, cglContext, cglPixelFormat);
		
		// Activate the display link
		CVDisplayLinkStart(displayLink);
		
		data = nil;
	}
	
	return self;
}
	
- (void) initGL
{
	[[self openGLContext] makeCurrentContext];
	
	// Synchronize buffer swaps with vertical refresh rate
	GLint swapInt = 1;
	[[self openGLContext] setValues:&swapInt forParameter:NSOpenGLCPSwapInterval]; 
	
	// Create OpenGL textures
	if ([self initImageData])
		[self loadTexturesWithClientStorage];
	
	glEnable(GL_DEPTH_TEST);
	glEnableClientState(GL_VERTEX_ARRAY);
	glEnableClientState(GL_TEXTURE_COORD_ARRAY);
}

- (void) loadTexturesWithClientStorage
{
	int	i;
	
	glGenTextures(TEXTURE_COUNT, texIds);
	
	// Enable the rectangle texture extenstion
	glEnable(GL_TEXTURE_RECTANGLE_EXT);
	
	// Eliminate a data copy by the OpenGL driver using the Apple texture range extension along with the rectangle texture extension
	// This specifies an area of memory to be mapped for all the textures. It is useful for tiled or multiple textures in contiguous memory.
	glTextureRangeAPPLE(GL_TEXTURE_RECTANGLE_EXT, TEXTURE_WIDTH * TEXTURE_HEIGHT * 4 * TEXTURE_COUNT, data);

	for (i = 0; i < TEXTURE_COUNT; i++)
	{
		// Bind the rectange texture
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[i]);
		
		// Set a CACHED or SHARED storage hint for requesting VRAM or AGP texturing respectively
		// GL_STORAGE_PRIVATE_APPLE is the default and specifies normal texturing path
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_STORAGE_HINT_APPLE , GL_STORAGE_CACHED_APPLE);
		
		// Eliminate a data copy by the OpenGL framework using the Apple client storage extension
		glPixelStorei(GL_UNPACK_CLIENT_STORAGE_APPLE, GL_TRUE);
		
		// Rectangle textures has its limitations compared to using POT textures, for example,
		// Rectangle textures can't use mipmap filtering
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
		
		// Rectangle textures can't use the GL_REPEAT warp mode
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_RECTANGLE_EXT, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
			
		glPixelStorei(GL_UNPACK_ROW_LENGTH, 0);
			
		// OpenGL likes the GL_BGRA + GL_UNSIGNED_INT_8_8_8_8_REV combination
		glTexImage2D(GL_TEXTURE_RECTANGLE_EXT, 0, GL_RGBA, TEXTURE_WIDTH, TEXTURE_HEIGHT, 0, 
					 GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, &data[TEXTURE_WIDTH * TEXTURE_HEIGHT * 4 * i]);
	}
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
}

- (BOOL) getImageData:(GLubyte*)imageData fromPath:(NSString*)path
{
	NSUInteger				width, height;
	NSURL					*url = nil;
	CGImageSourceRef		src;
	CGImageRef				image;
	CGContextRef			context = nil;
	CGColorSpaceRef			colorSpace;
	
	url = [NSURL fileURLWithPath: path];
	src = CGImageSourceCreateWithURL((CFURLRef)url, NULL);
	
	if (!src) {
		NSLog(@"No image");
		return NO;
	}
	
	image = CGImageSourceCreateImageAtIndex(src, 0, NULL);
	CFRelease(src);
	
	width = CGImageGetWidth(image);
	height = CGImageGetHeight(image);
	
	colorSpace = CGColorSpaceCreateDeviceRGB();
	context = CGBitmapContextCreate(imageData, width, height, 8, 4 * width, colorSpace, kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host);
	CGColorSpaceRelease(colorSpace);
	
	// Core Graphics referential is upside-down compared to OpenGL referential
	// Flip the Core Graphics context here
	// An alternative is to use flipped OpenGL texture coordinates when drawing textures
	CGContextTranslateCTM(context, 0.0, height);
	CGContextScaleCTM(context, 1.0, -1.0);
	
	// Set the blend mode to copy before drawing since the previous contents of memory aren't used. This avoids unnecessary blending.
	CGContextSetBlendMode(context, kCGBlendModeCopy);
	
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), image);
	
	CGContextRelease(context);
	CGImageRelease(image);
	
	return YES;
}

- (BOOL) initImageData
{
	int i;
	
	// This holds the data of all textures
	data = (GLubyte*) calloc(TEXTURE_WIDTH * TEXTURE_HEIGHT * 4 * TEXTURE_COUNT, sizeof(GLubyte));
	
	for (i = 0; i < TEXTURE_COUNT; i++)
	{
		NSString *path = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%d", i] ofType:@"jpg"];
		
		if (!path) {
			NSLog(@"No valid path");
			return NO;
		}
		
		// Point to the current texture
		GLubyte *imageData = &data[TEXTURE_WIDTH * TEXTURE_HEIGHT * 4 * i];
		
		if (![self getImageData:imageData fromPath:path])
			return NO;
	}
	
	return YES;
}

- (void) reshape
{
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	NSRect rect = [self bounds];
	glViewport(0, 0, rect.size.width, rect.size.height);
	
	glMatrixMode(GL_PROJECTION);
    glLoadIdentity();
    glOrtho(-1.0f, 1.0f, -1.0f, 1.0f, -10.0f, 10.0f);
	glMatrixMode(GL_MODELVIEW);
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) drawView
{
	// Cube data
	const GLfloat vertices[6][12] = {
		{-1, 1,-1,  -1, 1, 1,  -1,-1, 1,  -1,-1,-1 }, //-x
		{ 1,-1,-1,   1,-1, 1,   1, 1, 1,   1, 1,-1 }, //+x
		{-1,-1,-1,  -1,-1, 1,   1,-1, 1,   1,-1,-1 }, //-y
		{ 1, 1,-1,   1, 1, 1,  -1, 1, 1,  -1, 1,-1 }, //+y
		{ 1,-1,-1,   1, 1,-1,  -1, 1,-1,  -1,-1,-1 }, //-z
		{-1,-1, 1,  -1, 1, 1,   1, 1, 1,   1,-1, 1 }, //+z
	};
	
	// Rectangle textures require non-normalized texture coordinates
	const GLfloat texcoords[] = {
		0,				0,
		0,				TEXTURE_HEIGHT,
		TEXTURE_WIDTH,	TEXTURE_HEIGHT,
		TEXTURE_WIDTH,	0,
	};
	
	int f, t;
	
	// We draw on a secondary thread through the display link
	// When resizing the view, -reshape is called automatically on the main thread
	// Add a mutex around to avoid the threads accessing the context simultaneously	when resizing
	CGLLockContext([[self openGLContext] CGLContextObj]);
	
	[[self openGLContext] makeCurrentContext];
	
	glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
	glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glPushMatrix();
	glScalef(0.5f, 0.5f, 0.5f);
	glRotatef(rot, 1, 1, 0);
	glRotatef(rot, 0, 1, 0);
	rot += 0.8;
	
	glTexCoordPointer(2, GL_FLOAT, 0, texcoords);
	for (f = 0; f < 6; f++)
	{
		t = f % TEXTURE_COUNT;
		glBindTexture(GL_TEXTURE_RECTANGLE_EXT, texIds[t]);
		
		glVertexPointer(3, GL_FLOAT, 0, vertices[f]);
		glDrawArrays(GL_QUADS, 0, 4);
	}
	glPopMatrix();
	
	glBindTexture(GL_TEXTURE_RECTANGLE_EXT, 0);
	
	[[self openGLContext] flushBuffer];
	
	CGLUnlockContext([[self openGLContext] CGLContextObj]);
}

- (void) dealloc
{
	glDeleteTextures(TEXTURE_COUNT, texIds);
	
	if (usePBO)
		glDeleteBuffers(TEXTURE_COUNT, pboIds);
	
	// When using client storage, we should keep the data around until the textures are deleted
	if (data) {
		free(data);
		data = nil;
	}
	
	// Release the display link
    CVDisplayLinkRelease(displayLink);

	[super dealloc];
}

@end
