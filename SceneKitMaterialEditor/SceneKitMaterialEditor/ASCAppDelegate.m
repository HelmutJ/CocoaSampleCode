/*
     File: ASCAppDelegate.m 
 Abstract: This is the main controller for the application and handles the setup of the view and the creation of a scene. It declares properties for Cocoa Bindings extensively used in MainMenu.xib to display rich information about a node's geometry and its materials. An instance of this class is created in MainMenu.xib and uses an outlet for the view (connected in the xib). 
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
  
 Copyright (C) 2012 Apple Inc. All Rights Reserved. 
  
 */

#import "ASCAppDelegate.h"
#import "ASCValueTransformers.h"

@implementation ASCAppDelegate

#pragma mark - Material presets

- (SCNMaterial *)chromeMaterial {
    SCNMaterial *material = [SCNMaterial material];
    
    material.diffuse.contents = [NSColor blackColor];
    
    // We build a cubemap using an array of 6 images
    NSArray *mapArray = @[ [NSImage imageNamed:@"right.jpg"],
                           [NSImage imageNamed:@"left.jpg"],
                           [NSImage imageNamed:@"top.jpg"],
                           [NSImage imageNamed:@"bottom.jpg"],
                           [NSImage imageNamed:@"back.jpg"],
                           [NSImage imageNamed:@"front.jpg"] ];
    
    material.reflective.contents = mapArray;
    material.normal.contents     = [NSImage imageNamed:@"chrome-normal"];
    material.specular.contents   = [NSColor whiteColor];
    
    material.shininess = 100.0;
    material.locksAmbientWithDiffuse = YES;
    
    return material;
}

- (SCNMaterial *)earthMaterial {
    SCNMaterial *material = [SCNMaterial material];
    
    material.diffuse.contents    = [NSImage imageNamed:@"earth-diffuse"];
    material.normal.contents     = [NSImage imageNamed:@"earth-normal"];	  
    material.reflective.contents = [NSImage imageNamed:@"earth-reflective"];
    material.specular.contents   = [NSImage imageNamed:@"earth-specular"];
    
    material.locksAmbientWithDiffuse = YES;
    
    return material;
}

- (SCNMaterial *)screeMaterial {
    SCNMaterial *material = [SCNMaterial material];
    
    material.diffuse.contents  = [NSImage imageNamed:@"scree-diffuse"];
    material.multiply.contents = [NSImage imageNamed:@"scree-multiply"];
    material.normal.contents   = [NSImage imageNamed:@"scree-normal"];
    material.specular.contents = [NSColor colorWithDeviceWhite:0.3 alpha:1];
    
    material.shininess = 0.2;
    material.locksAmbientWithDiffuse = YES;
    
    return material;
}

- (SCNMaterial *)stoneMaterial {
    SCNMaterial *material = [SCNMaterial material];
    
    material.diffuse.contents  = [NSImage imageNamed:@"stone-diffuse"];
    material.normal.contents   = [NSImage imageNamed:@"stone-normal"];
    material.specular.contents = [NSColor colorWithDeviceWhite:0.3 alpha:1];
    
    material.locksAmbientWithDiffuse = YES;
    
    return material;
}

- (SCNMaterial *)woodMaterial {
    SCNMaterial *material = [SCNMaterial material];
    
    material.diffuse.contents  = [NSImage imageNamed:@"wood-diffuse"];
    material.normal.contents   = [NSImage imageNamed:@"wood-bump"];
    material.specular.contents = [NSImage imageNamed:@"wood-specular"];
    
    material.locksAmbientWithDiffuse = YES;
    
    return material;
}


#pragma mark - Material

- (void)selectMaterialPresetAtIndex:(NSUInteger)index {
    static NSArray *materials = nil;
    if (materials == nil) {
        materials = @[ [self chromeMaterial],
                       [SCNMaterial material],
                       [self earthMaterial],
                       [self screeMaterial],
                       [self stoneMaterial],
                       [self woodMaterial] ];
    }
    
    SCNMaterial *material = [materials[index] copy];

    // Configure all the material properties
    void(^configureMaterialProperty)(SCNMaterialProperty *materialProperty) = ^(SCNMaterialProperty *materialProperty) {
        // Setup a trilinear filtering
        //   this is to reduce the aliasing when minimizing / maximizing the images
        materialProperty.minificationFilter  = SCNLinearFiltering;
        materialProperty.magnificationFilter = SCNLinearFiltering;
        materialProperty.mipFilter           = SCNLinearFiltering;
        
        // Repeat the texture if necessary
        materialProperty.wrapS = SCNRepeat;
        materialProperty.wrapT = SCNRepeat;
    };
    
	configureMaterialProperty(material.ambient);
	configureMaterialProperty(material.diffuse);
	configureMaterialProperty(material.specular);
	configureMaterialProperty(material.emission);
	configureMaterialProperty(material.transparent);
	configureMaterialProperty(material.reflective);
	configureMaterialProperty(material.multiply);
	configureMaterialProperty(material.normal);
    
    // Make the material visible from the two sides - front and back
    material.doubleSided = YES;
    
    // Set the material and update the geometry accordingly
    self.material = material;
    _modelNode.geometry.materials = @[_material];
}

- (IBAction)selectMaterialPreset:(id)sender {
    [self selectMaterialPresetAtIndex:[sender indexOfSelectedItem]];
}

#pragma mark - Model geometry

- (void)setModelIndex:(NSUInteger)index {
	static NSArray *models = nil;
    if (models == nil) {
        models = @[ [SCNSphere sphereWithRadius:8.0],
                    [SCNCylinder cylinderWithRadius:8.0 height:8.0],
                    [SCNBox boxWithWidth:10 height:10 length:10 chamferRadius:0],
                    [SCNPlane planeWithWidth:15 height:15],
                    [SCNTorus torusWithRingRadius:8 pipeRadius:3] ];
    }
    
    _modelIndex = index;
	
    // Set the right geometry with the right material
    _modelNode.geometry = models[_modelIndex];
    _modelNode.geometry.materials = @[_material];
}

#pragma mark -

- (void)awakeFromNib {
	// Create a scene
	SCNScene *scene = [SCNScene scene];
	
	// Add a camera to the scene
	SCNNode *cameraNode = [SCNNode node];
	cameraNode.camera = [SCNCamera camera];	
	cameraNode.position = SCNVector3Make(0, 0, 30);
    [scene.rootNode addChildNode:cameraNode];
	
	// Add a diffuse light to the scene
	self.diffuseLightNode = [SCNNode node];
	_diffuseLightNode.light = [SCNLight light];
	_diffuseLightNode.light.type = SCNLightTypeOmni;
	_diffuseLightNode.position = SCNVector3Make(-30, 30, 50);
	[scene.rootNode addChildNode:_diffuseLightNode];
    
	// Add an ambient light to the scene
	self.ambientLightNode = [SCNNode node];
	_ambientLightNode.light = [SCNLight light];
	_ambientLightNode.light.type = SCNLightTypeAmbient;
	_ambientLightNode.light.color = [NSColor colorWithDeviceWhite:0.1 alpha:1.0];
    [scene.rootNode addChildNode:_ambientLightNode];
    
    // Create a plane in the background
    //   this will allow to test and play with the transparency settings
    SCNPlane *plane = [SCNPlane planeWithWidth:30 height:30];
    plane.firstMaterial.diffuse.contents = [NSImage imageNamed:@"checkboard"]; // Set a checkerboard in the background
    plane.firstMaterial.lightingModelName = SCNLightingModelConstant;          // Use the constant lighting model: we don't want the lighting to be applied to our background
    
    SCNNode *planeNode = [SCNNode node];
    planeNode.geometry = plane;
    planeNode.position = SCNVector3Make(0, 0, -10);
    planeNode.renderingOrder = -1; // render the background first to allow testing the "writeToDepthBuffer" property
    [scene.rootNode addChildNode:planeNode];
    
	// Create a node to attach the geometry later on
	self.modelNode = [SCNNode node];
	[scene.rootNode addChildNode:_modelNode];

    // Select a default model and material
    [self selectMaterialPresetAtIndex:2];
    self.modelIndex = 0;
    
	// Configure the view
	_view.scene = scene;
    _view.selectionDelegate = self;
	_view.backgroundColor = [NSColor clearColor];
}

#pragma mark - ASCViewDelegate

- (SCNNode *)selectedObjectForView:(ASCView *)view {
    return _modelNode;
}

#pragma mark - NSApplicationDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
