//-------------------------------------------------------------------------
//
//	File: Toyball.hm
//
//  Abstract: Toyball GLSL Exhibit
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by
//  Apple Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"], to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Inc.
//  may be used to endorse or promote products derived from the Apple
//  Software without specific prior written permission from Apple.  Except
//  as expressly stated in this notice, no other rights or licenses, express
//  or implied, are granted by Apple herein, including but not limited to
//  any patent rights that may be infringed by your derivative works or by
//  other works in which the Apple Software may be incorporated.
//  
//  The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
//  MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
//  THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
//  FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
//  OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//  
//  IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
//  OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
//  MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
//  AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
//  STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
// 
//  Copyright (c) 2004-2007 Apple Inc., All rights reserved.
//
//-------------------------------------------------------------------------

#import "Toyball.h"

@implementation Toyball

- (void) setupUniforms
{
	glUseProgramObjectARB(programObject);
	
	glUniform4fARB([self getUniformLocation:programObject uniformName:"LightDir"], 0.57735, 0.57735, 0.57735, 0.0);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"BallCenter"], 0.0, 0.0, 0.0, 1.0);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"HVector"], 0.32506, 0.32506, 0.88808, 0.0);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"SpecularColor"], 0.5, 0.5, 0.4, 60.0);

	glUniform4fARB([self getUniformLocation:programObject uniformName:"Red"],    0.6, 0.0, 0.0, 1.0);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"Yellow"], 0.6, 0.5, 0.0, 1.0);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"Blue"],   0.0, 0.3, 0.6, 1.0);

	glUniform4fARB([self getUniformLocation:programObject uniformName:"HalfSpace0"], 1.0, 0.0, 0.0, 0.2);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"HalfSpace1"], 0.309016994, 0.951056516, 0.0, 0.2);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"HalfSpace2"], -0.809016994, 0.587785252, 0.0, 0.2);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"HalfSpace3"], -0.809016994, -0.587785252, 0.0, 0.2);
	glUniform4fARB([self getUniformLocation:programObject uniformName:"HalfSpace4"], 0.309016994, -0.951056516, 0.0, 0.2);

	glUniform1fARB([self getUniformLocation:programObject uniformName:"InOrOutInit"], -3.0);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"StripeWidth"], 0.3);
	glUniform1fARB([self getUniformLocation:programObject uniformName:"FWidth"], 0.005);
} // setupUniforms

- (void) initLazy
{
	[super initLazy];
	
	// Setup GLSL

	// Get a model and set its quadric
	
	model = [[Models alloc] init];

	// Load vertex and fragment shaders
	
	[self loadShadersFromResource:@"Toyball" ];
		
	// Setup uniforms
	
	[self setupUniforms];
} // initLazy

- (void) dealloc
{
	[model dealloc];
	
	[super dealloc];
} // dealloc

- (NSString *) name
{
	return @"Toyball";
} // name

- (NSString *) descriptionFilename
{
	return [appBundle pathForResource: @"Toyball" ofType: @"rtf"];
} // descriptionFilename

- (void) renderFrame
{
	[super renderFrame];
	
	glUseProgramObjectARB(programObject);

	[model drawModel:kModelSolidSphere];
	
	glUseProgramObjectARB(NULL);
} // renderFrame

@end
