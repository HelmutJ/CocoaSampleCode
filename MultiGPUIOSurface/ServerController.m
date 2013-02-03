/*
    File: ServerController.m
Abstract: 
This class implements the controller object for the server application. It is 
responsible for setting up public Mach port for the server and listening for
client applications to start up.  It also sends frame display update requests
to all clients after every frame update.

It is also responsible for creating the initial set of IOSurfaces used to send
rendered frames to the client applications.

 Version: 1.1

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

#import "ServerController.h"
#import "MultiGPUMig.h"
#import "MultiGPUMigServer.h"
#import "ServerOpenGLView.h"

BOOL gIsMaster = YES;

@implementation ServerController

- (void)applicationWillFinishLaunching:(NSNotification *)note
{
	[[NSNotificationCenter defaultCenter] addObserver:self 
	    selector:@selector(portDied:) name:NSPortDidBecomeInvalidNotification object:nil];
	
	[_rendererPopup removeAllItems];
	[_rendererPopup addItemsWithTitles:[_view rendererNames]];
	
	[_view setRendererIndex:0];
	[_rendererPopup selectItemAtIndex:0];

	serverPort = [(NSMachPort *)([[NSMachBootstrapServer sharedInstance] servicePortWithName:@"com.apple.MultiGPUServer"]) retain];
	
	// Create a local dummy reply port to use with the mig reply stuff
	localPort = [[NSMachPort alloc] init];
	
	// Retrieve raw mach port names.
	serverPortName = [serverPort machPort];
	localPortName  = [localPort machPort];

	[serverPort setDelegate:self];
	[serverPort scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
			
	// Set up all of our iosurface buffers		
	int i;
	for(i = 0; i < NUM_IOSURFACE_BUFFERS; i++)
		 _ioSurfaceBuffers[i] = IOSurfaceCreate((CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithInt:512],  (id)kIOSurfaceWidth,
			[NSNumber numberWithInt:512], (id)kIOSurfaceHeight,
			[NSNumber numberWithInt:4],      (id)kIOSurfaceBytesPerElement,
			[NSNumber numberWithBool:YES],   (id)kIOSurfaceIsGlobal,
			nil]);		
}

- (void)applicationDidFinishLaunching:(NSNotification *)note
{
	// Fire up animation timer.
	_timer = [[NSTimer timerWithTimeInterval:1.0f/60.0f target:self selector:@selector(animate:) userInfo:nil repeats:YES] retain];
	[[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
}

- (void)portDied:(NSNotification *)notification
{
	NSPort *port = [notification object];
	if(port == serverPort)
	{
		[NSApp terminate:self];
	}
	else
	{		
		int i;
		for(i = 0; i < clientPortCount+1; i++)
		{
			if([clientPort[i] isEqual:port])
			{
				[clientPort[i] release];
				clientPort[i] = nil;
				clientPortNames[i] = 0;
			}
		}
	}
}

- (void)handleMachMessage:(void *)msg
{
	union __ReplyUnion___MGCMGSServer_subsystem reply;
	
	mach_msg_header_t *reply_header = (void *)&reply;
	kern_return_t kr;
	
	if(MGSServer_server(msg, reply_header) && reply_header->msgh_remote_port != MACH_PORT_NULL)
	{
		kr = mach_msg(reply_header, MACH_SEND_MSG, reply_header->msgh_size, 0, MACH_PORT_NULL, 
			     0, MACH_PORT_NULL);
        if(kr != 0)
			[NSApp terminate:nil];
	}
}

- (kern_return_t)checkInClient:(mach_port_t)client_port index:(int32_t *)client_index
{	
	clientPortCount++;			// clients always start at index 1
	clientPortNames[clientPortCount] = client_port;
	clientPort[clientPortCount] = [[NSMachPort alloc] initWithMachPort:client_port];
	
	*client_index = clientPortCount;
	return 0;
}

kern_return_t _MGSCheckinClient(mach_port_t server_port, mach_port_t client_port,
			       int32_t *client_index)
{
	return [[NSApp delegate] checkInClient:client_port index:client_index];
}

// For the server, this is a no-op
kern_return_t _MGSDisplayFrame(mach_port_t server_port, int32_t frame_index, uint32_t iosurface_id)
{
	return 0;
}

- (GLuint)currentTextureName
{
	return _textureNames[nextFrameIndex];
}

- (void)animate:(NSTimer *)timer
{
	if(!_textureNames[nextFrameIndex])
	{
		_textureNames[nextFrameIndex] = [_view setupIOSurfaceTexture:_ioSurfaceBuffers[nextFrameIndex]];
	}
	
	[_view setNeedsDisplay:YES];
	[_view display];
		
	int i;
	for(i = 0; i < clientPortCount+1; i++)
	{
		if(clientPortNames[i])
		{
			_MGCDisplayFrame(clientPortNames[i], 
					 nextFrameIndex, 
					 IOSurfaceGetID(_ioSurfaceBuffers[nextFrameIndex]));
		}
	}
	nextFrameIndex = (nextFrameIndex + 1) % NUM_IOSURFACE_BUFFERS;
}

- (IBAction)setRenderer:(id)sender
{
	[_view setRendererIndex:(rendererIndex = [sender indexOfSelectedItem])];
}

@end
