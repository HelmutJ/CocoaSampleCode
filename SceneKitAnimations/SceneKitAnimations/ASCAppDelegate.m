/*
     File: ASCAppDelegate.m
 Abstract: This is the main controller for the application and handles the loading of a initial scene and its related animations. This class uses an IBOutlet to reference an SCNView instance in MainMenu.xib which was configured in Interface Builder to have an initial scene, a custom background color and the default lighting enabled. In addition four buttons have their actions set to play the animations that were loaded, configured and stored by the App Delegate.
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

#import "ASCAppDelegate.h"

@implementation ASCAppDelegate {
    NSMutableArray *_animations;
}

#pragma mark -

- (void)awakeFromNib {
    // Load the DAE file and the associated animations
    [self loadSceneAndAnimations];
    
    // Be idle by default
    [self playAnimation:ASCAnimationIdle];
    
    // Create a reflective floor and configure it
	SCNFloor *floor = [SCNFloor floor];
	floor.reflectionFalloffEnd = 100.0;                                                    // Set a falloff end value for the reflection
	floor.firstMaterial.diffuse.contents = [NSImage imageNamed:@"floor.jpg"];              // Set a diffuse texture, here a pavement image
	floor.firstMaterial.diffuse.contentsTransform = CATransform3DMakeScale(0.4, 0.4, 0.4); // Scale the diffuse texture
	floor.firstMaterial.diffuse.mipFilter = SCNLinearFiltering;                            // Turn on mipmapping for the diffuse texture for a better antialiasing

	// Create a node to attach the floor to, and add it to the scene
	SCNNode *floorNode = [SCNNode node];
	floorNode.geometry = floor;
	floorNode.name = @"floor";
    [_sceneView.scene.rootNode addChildNode:floorNode];
    
    // Prevent a layout issue
    [_sceneView removeFromSuperview];
    [_window.contentView addSubview:_sceneView positioned:NSWindowBelow relativeTo:nil];
}

#pragma mark - Playing animations

- (void)playAnimation:(ASCAnimation)animation {
    // Use the same animation key for all the animations except "idle".
    // When we will add an animation it will replace the animation currently
    // playing (if any) but the idle animation will remain active for ever.
    NSString *key = animation == ASCAnimationIdle ? @"idleAnimation" : @"otherAnimation";
    
    // Add the animation - it will start playing right away
    [_sceneView.scene.rootNode addAnimation:_animations[animation] forKey:key];
}

#pragma mark - Animation loading

- (void)loadSceneAndAnimations {
    _animations = [NSMutableArray array];
    
    // Load the character from one of our dae documents, for instance "idle.dae"
    NSURL    *idleURL   = [[NSBundle mainBundle] URLForResource:@"idle" withExtension:@"dae"];
    SCNScene *idleScene = [SCNScene sceneWithURL:idleURL options:nil error:nil];
    
    // Merge the loaded scene into our main scene in order to
    //   place the character in our own scene
    for (SCNNode *child in idleScene.rootNode.childNodes)
        [_sceneView.scene.rootNode addChildNode:child];
        
    // Load all the animations from their respective dae document
    // The animation identifier can be found in the Node Properties inspector of the Scene Kit editor integrated into Xcode
    [self loadAnimation:ASCAnimationAttack inSceneNamed:@"attack" withIdentifier:@"attackID"];
    [self loadAnimation:ASCAnimationDie inSceneNamed:@"die" withIdentifier:@"DeathID"];
    [self loadAnimation:ASCAnimationIdle inSceneNamed:@"idle" withIdentifier:@"idleAnimationID"];
    [self loadAnimation:ASCAnimationRun inSceneNamed:@"run" withIdentifier:@"RunID"];
    [self loadAnimation:ASCAnimationWalk inSceneNamed:@"walk" withIdentifier:@"WalkID"];
}

- (void)loadAnimation:(ASCAnimation)animation inSceneNamed:(NSString *)sceneName withIdentifier:(NSString *)animationIdentifier {
    NSURL          *sceneURL        = [[NSBundle mainBundle] URLForResource:sceneName withExtension:@"dae"];
    SCNSceneSource *sceneSource     = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    CAAnimation    *animationObject = [sceneSource entryWithIdentifier:animationIdentifier withClass:[CAAnimation class]];
	
    // Store the animation for later use
    [_animations addObject:animationObject];
    
    // Whether or not the animation should loop
    if (animation == ASCAnimationIdle || animation == ASCAnimationRun || animation == ASCAnimationWalk)
        animationObject.repeatCount = MAXFLOAT;
}

#pragma mark - Actions

- (IBAction)attack:(id)sender {
    [self playAnimation:ASCAnimationAttack];
}

- (IBAction)run:(id)sender {
    [self playAnimation:ASCAnimationRun];
}

- (IBAction)walk:(id)sender {
    [self playAnimation:ASCAnimationWalk];
}

- (IBAction)die:(id)sender {
    [self playAnimation:ASCAnimationDie];
}

#pragma mark - NSApplicationDelegate

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
