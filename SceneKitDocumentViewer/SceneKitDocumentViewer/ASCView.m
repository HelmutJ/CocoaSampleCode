/*
     File: ASCView.m 
 Abstract: A subclass of SCNView on which the user can drop .dae files. It handles mouse events to pick 3D objects and highlight their materials. 
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "ASCView.h"

@interface ASCView ()

@property SCNMaterial *selectedMaterial;

@end


@implementation ASCView 

- (void)loadSceneAtURL:(NSURL *)url {
    // Clear any current selection.
    self.selectedMaterial = nil;
    
    // Load the specified scene. First create a dictionary containing the options we want.
    NSDictionary *options = @{
        // Create normals if absent.
        SCNSceneSourceCreateNormalsIfAbsentKey : @YES,
        // Optimize the rendering by flattening the scene graph when possible. Note that this would prevent you from animating objects independantly.
        SCNSceneSourceFlattenSceneKey : @YES
    };
    
    // Load and set the scene.
    NSError * __autoreleasing error;
    SCNScene *scene = [SCNScene sceneWithURL:url options:options error:&error];
    if (scene) {
        self.scene = scene;
    }
    else {
        NSLog(@"Problem loading scene from %@\n%@", url, [error localizedDescription]);
    }
}

#pragma mark - Init

- (void)commonInit {
    // Register for the URL pasteboard type.
    [self registerForDraggedTypes:@[NSURLPboardType]];
}

- (id)initWithFrame:(NSRect)frameRect {
    if ((self = [super initWithFrame:frameRect])) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if ((self = [super initWithCoder:aDecoder])) {
        [self commonInit];
    }
    return self;
}

#pragma mark - Drag and drop

/*
 Support drag and drop of new dae files.
 */

- (NSDragOperation)dragOperationForPasteboard:(NSPasteboard *)pasteboard {
    // Only support drags from .dae files.
    if ([[pasteboard types] containsObject:NSURLPboardType]) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pasteboard];
        if ([[fileURL pathExtension] isEqualToString:@"dae"]) {
            return NSDragOperationCopy;
        }
    }
    
    return NSDragOperationNone;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    return [self dragOperationForPasteboard:[sender draggingPasteboard]];
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
    return [self dragOperationForPasteboard:[sender draggingPasteboard]];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    NSPasteboard *pasteboard = [sender draggingPasteboard];
    
    if ([[pasteboard types] containsObject:NSURLPboardType]) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pasteboard];
        [self loadSceneAtURL:fileURL];
        return YES;
    }

    return NO;
}

#pragma mark - Mouse selection

- (void)selectNode:(SCNNode *)node geometryElementIndex:(NSUInteger)index {
    // Unhighlight the previous selection.
    [self.selectedMaterial.emission removeAllAnimations];
    
    // Clear the selection.
    self.selectedMaterial = nil;
    
    // Highight the selection, if there is one.
    if (node != nil) {
        // Convert the geometry element index to a material index.
        index = index % [node.geometry.materials count];
        
        // Make the material unique (i.e. unshared).
        SCNMaterial *unsharedMaterial = [[node.geometry.materials objectAtIndex:index] copy];
        [node.geometry replaceMaterialAtIndex:index withMaterial:unsharedMaterial];
        
        // Select the material.
        self.selectedMaterial = unsharedMaterial;
        
        // Animate the material.
        CABasicAnimation *highlightAnimation = [CABasicAnimation animationWithKeyPath:@"contents"];
        highlightAnimation.toValue = [NSColor blueColor];
        highlightAnimation.fromValue = [NSColor blackColor];
        highlightAnimation.repeatCount = MAXFLOAT;
        highlightAnimation.autoreverses = YES;
        highlightAnimation.duration = 0.5;
        highlightAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        
        [self.selectedMaterial.emission addAnimation:highlightAnimation forKey:@"highlight"];
    }
}

#pragma mark - Mouse events

- (void)mouseDown:(NSEvent *)event {
    // Convert the mouse location in screen coordinates to local coordinates, then perform a hit test with the local coordinates.
    NSPoint mouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    NSArray *hits = [self hitTest:mouseLocation options:nil];
    
    // If there was a hit, select the nearest object; otherwise unselect.
    if ([hits count] > 0) {
        SCNHitTestResult *hit = hits[0]; // Choose the nearest object hit.
        [self selectNode:hit.node geometryElementIndex:hit.geometryIndex];
    }
    else {
        [self selectNode:nil geometryElementIndex:NSNotFound];
    }
    
    [super mouseDown:event];
}

@end
