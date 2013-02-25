//---------------------------------------------------------------------------
//
//	File: GLSLUnitsController.m
//
//  Abstract: A class to manage shader units for an application
// 			 
//  Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
//  Computer, Inc. ("Apple") in consideration of your agreement to the
//  following terms, and your use, installation, modification or
//  redistribution of this Apple software constitutes acceptance of these
//  terms.  If you do not agree with these terms, please do not use,
//  install, modify or redistribute this Apple software.
//  
//  In consideration of your agreement to abide by the following terms, and
//  subject to these terms, Apple grants you a personal, non-exclusive
//  license, under Apple's copyrights in this original Apple software (the
//  "Apple Software"), to use, reproduce, modify and redistribute the Apple
//  Software, with or without modifications, in source and/or binary forms;
//  provided that if you redistribute the Apple Software in its entirety and
//  without modifications, you must retain this notice and the following
//  text and disclaimers in all such redistributions of the Apple Software. 
//  Neither the name, trademarks, service marks or logos of Apple Computer,
//  Inc. may be used to endorse or promote products derived from the Apple
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
//  Copyright (c) 2008 Apple Inc., All rights reserved.
//
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#import "GLSLUnitsController.h"

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

#pragma mark

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------

@implementation GLSLUnitsController

//---------------------------------------------------------------------------

#pragma mark -- Initialize Instance Variables --

//---------------------------------------------------------------------------

- (void) initShaderUnits
{
	blurShader          = nil;
	brightenShader      = nil;
	colorInvertShader   = nil;
	dilationShader      = nil;
	edgeDetectionShader = nil;
	erosionShader       = nil;
	extractColorShader  = nil;
	fogShader           = nil;
	grayInvertShader    = nil;
	grayscaleShader     = nil;
	heatSigShader       = nil;
	saturationShader    = nil;
	sepiaShader         = nil;
	sharpenShader       = nil;
	skyShader           = nil;
	toonShader          = nil;
} // initShaderUnits

//---------------------------------------------------------------------------
//
// Initialize
//
//---------------------------------------------------------------------------

- (id) init
{
	self = [super init];
	
	if ( self )
	{
		[self initShaderUnits];
	} // if
	
	return self;
} // init

//---------------------------------------------------------------------------

#pragma mark -- Cleanup all the Resources --

//---------------------------------------------------------------------------

- (void) deleteShaderUnits
{
	[blurShader           release];
	[brightenShader       release];
	[colorInvertShader    release];
	[dilationShader       release];
	[edgeDetectionShader  release];
	[erosionShader        release];
	[extractColorShader   release];
	[fogShader            release];
	[grayInvertShader     release];
	[grayscaleShader      release];
	[heatSigShader        release];
	[saturationShader     release];
	[sepiaShader          release];
	[sharpenShader        release];
	[skyShader            release];
	[toonShader           release];
} // deleteShaderUnits

//---------------------------------------------------------------------------

- (void) dealloc 
{
	[self  deleteShaderUnits];
    [super dealloc];
} // dealloc

//---------------------------------------------------------------------------

#pragma mark -- Draw into a OpenGL view --

//---------------------------------------------------------------------------

- (void) excuteShaderUnit:(CVOpenGLTextureRef)theVideoFrame
					type:(const GLSLTypes)theShaderType
					flag:(const BOOL)theFlag
					value:(const GLfloat *)theFloatValue
{
	// Draw into the view
	
	switch( theShaderType )
	{
		case kShaderBlur:
			[blurShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;

		case kShaderBrighten:
			[brightenShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;
		
		case kShaderColorInvert:
			[colorInvertShader excuteWithCVTexture:theVideoFrame];
			break;
			
		case kShaderDilation:
			[dilationShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;
			
		case kShaderEdgeDection:
			[edgeDetectionShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;
			
		case kShaderErosion:
			[erosionShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;

		case kShaderExtractColor:
			[extractColorShader executeWithFloatUniforms:theVideoFrame value:theFloatValue];
			break;
			
		case kShaderFog:
			[fogShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;
		
		case kShaderGrayInvert:
			[grayInvertShader excuteWithCVTexture:theVideoFrame];
			break;
			
		case kShaderHeatSig:
			[heatSigShader excuteWithCVTexture:theVideoFrame];
			break;

		case kShaderSaturation:
			[saturationShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;

		case kShaderSepia:
			[sepiaShader excuteWithCVTexture:theVideoFrame];
			break;
			
		case kShaderSharpen:
			[sharpenShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;
		
		case kShaderSky:
			[skyShader executeWithFloatUniform:theVideoFrame value:theFloatValue];
			break;
		
		case kShaderToon:
			[toonShader executeWithFloatsAndBoolUniforms:theVideoFrame flag:theFlag value:theFloatValue];
			break;

		default:
			[grayscaleShader excuteWithCVTexture:theVideoFrame];
			break;
	} // switch
} // excuteShaderUnit

//---------------------------------------------------------------------------

#pragma mark -- Initialize OpenGL Shader Units --

//---------------------------------------------------------------------------
//
// Call after OpenGL view is initialized.
//
//---------------------------------------------------------------------------

- (void) getShaderUnitsWithSize:(const NSSize *)theSize
{
	// Delete the old shaderType units
	
	[self deleteShaderUnits];
	
	// Instantiate new shader units
	
	blurShader          = [[GLSLBlurUnit          alloc] initShaderWithSize:theSize];
	brightenShader      = [[GLSLBrightenUnit      alloc] initShaderWithSize:theSize];
	colorInvertShader   = [[GLSLColorInvertUnit   alloc] initShaderWithSize:theSize];
	dilationShader      = [[GLSLDilationUnit      alloc] initShaderWithSize:theSize];
	edgeDetectionShader = [[GLSLEdgeDetectionUnit alloc] initShaderWithSize:theSize];
	erosionShader       = [[GLSLErosionUnit       alloc] initShaderWithSize:theSize];
	extractColorShader  = [[GLSLExtractColorUnit  alloc] initShaderWithSize:theSize];
	fogShader           = [[GLSLFogUnit           alloc] initShaderWithSize:theSize];
	grayInvertShader    = [[GLSLGrayInvertUnit    alloc] initShaderWithSize:theSize];
	grayscaleShader     = [[GLSLGrayscaleUnit     alloc] initShaderWithSize:theSize];
	heatSigShader       = [[GLSLHeatSignatureUnit alloc] initShaderWithSize:theSize];
	saturationShader    = [[GLSLSaturationUnit    alloc] initShaderWithSize:theSize];
	sepiaShader         = [[GLSLSepiaUnit         alloc] initShaderWithSize:theSize];
	sharpenShader       = [[GLSLSharpenUnit       alloc] initShaderWithSize:theSize];
	skyShader           = [[GLSLSkyUnit           alloc] initShaderWithSize:theSize];
	toonShader          = [[GLSLToonUnit          alloc] initShaderWithSize:theSize];
} // getShaderUnits

//---------------------------------------------------------------------------

@end

//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
