/*

File: UIController.h

Abstract: Main user interface control class

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

  Copyright (c) 2004-2006 Apple Computer, Inc., All rights reserved.

*/

/* Required Includes */
#import <Cocoa/Cocoa.h>
#import "OpenGLView.h"

#import "BlobbyCloud.h"
#import "BrickShader.h"
#import "Bubbles.h"
#import "Bumpmap.h"
#import "Cloud1.h"
#import "Cloud2.h"
#import "Earth.h"
#import "EmulateFFFS.h"
#import "EmulateFFVS.h"
#import "EnvMap.h"
#import "Eroded.h"
#import "Fire.h"
#import "Fur.h"
#import "Glass.h"
#import "GlyphBomb.h"
#import "Gooch.h"
#import "Granite.h"
#import "HeatHaze.h"
#import "Inferno.h"
#import "Julia.h"
#import "Lattice.h"
#import "Mandelbrot.h"
#import "Marble.h"
#import "ParticleFountain.h"
#import "ParticleSimple.h"
#import "ParticleWave.h"
#import "Plasma.h"
#import "Polkadot3D.h"
#import "Skinning.h"
#import "SphereMorph.h"
#import "StarBomb.h"
#import "TextureBomb.h"
#import "Toon.h"
#import "TorusMorph.h"
#import "Toyball.h"
#import "VertexNoise.h"
#import "Wobble.h"
#import "Wood1.h"
#import "Wood2.h"
#import "WoodShader.h"

#import "RayTracer.h"
#import "Life.h"

/*#import "Mandelbrot.h"
#import "BrickShader.h"
#import "WoodShader.h"
#import "Marble.h"*/

/* Exhibit base class */
@interface UIController : NSObject {
	IBOutlet OpenGLView  *openglview;
	IBOutlet NSTableView *table_view;
	IBOutlet NSTextView  *text_view;
	
	NSArray *exhibits;
}

- (id) init;
- (void) dealloc;

/* Following methods are for compliency with the NSTableDataSource protocol */
- (int) numberOfRowsInTableView: (NSTableView *) aTableView;
- (id) tableView: (NSTableView *) aTableView
       objectValueForTableColumn: (NSTableColumn *) aTableColumn                                                                 
       row: (int) rowIndex;
- (void) tableViewSelectionDidChange: (NSNotification *) aNotification;
 			
@end
