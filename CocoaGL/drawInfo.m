//
// File:		drawInfo.m
//
// Abstract:	Creates and maintains the texture with the strings describing
//				the capabilities of the graphics card.
//
// Version:		1.1 - updated list of extensions and minor mostly cosmetic fixes.
//				1.0 - Original release.
//				
//
// Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//				in consideration of your agreement to the following terms, and your use,
//				installation, modification or redistribution of this Apple software
//				constitutes acceptance of these terms.  If you do not agree with these
//				terms, please do not use, install, modify or redistribute this Apple
//				software.
//
//				In consideration of your agreement to abide by the following terms, and
//				subject to these terms, Apple grants you a personal, non - exclusive
//				license, under Apple's copyrights in this original Apple software ( the
//				"Apple Software" ), to use, reproduce, modify and redistribute the Apple
//				Software, with or without modifications, in source and / or binary forms;
//				provided that if you redistribute the Apple Software in its entirety and
//				without modifications, you must retain this notice and the following text
//				and disclaimers in all such redistributions of the Apple Software. Neither
//				the name, trademarks, service marks or logos of Apple Inc. may be used to
//				endorse or promote products derived from the Apple Software without specific
//				prior written permission from Apple.  Except as expressly stated in this
//				notice, no other rights or licenses, express or implied, are granted by
//				Apple herein, including but not limited to any patent rights that may be
//				infringed by your derivative works or by other works in which the Apple
//				Software may be incorporated.
//
//				The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//				WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//				WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//				PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//				ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//				IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//				CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//				SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//				INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//				AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//				UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//				OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2003-2007 Apple Inc. All Rights Reserved.
//

#import "GLCheck.h"
#import "GLString.h"
#import "drawInfo.h"

NSMutableArray *capsTextures;

void initCapsTexture (GLCaps * displayCaps, CGDisplayCount numDisplays)
{
	short theIndex;
	[capsTextures release];
	capsTextures = NULL;
	capsTextures = [NSMutableArray arrayWithCapacity: numDisplays];
	[capsTextures retain];
	
	// draw info
    NSMutableDictionary *bold12Attribs = [NSMutableDictionary dictionary];
    [bold12Attribs setObject: [NSFont fontWithName: @"Helvetica-Bold" size: 12.0f] forKey: NSFontAttributeName];
    [bold12Attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
 
    NSMutableDictionary *bold9Attribs = [NSMutableDictionary dictionary];
    [bold9Attribs setObject: [NSFont fontWithName: @"Helvetica-Bold" size: 9.0f] forKey: NSFontAttributeName];
    [bold9Attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];
 
	NSMutableDictionary *normal9Attribs = [NSMutableDictionary dictionary];
    [normal9Attribs setObject: [NSFont fontWithName: @"Helvetica" size: 9.0f] forKey: NSFontAttributeName];
    [normal9Attribs setObject: [NSColor whiteColor] forKey: NSForegroundColorAttributeName];

	for (theIndex = 0; theIndex < numDisplays; theIndex++) {
		NSMutableAttributedString * outString, * appendString;
		GLString *capsTexture;
		
		// draw caps string
		outString = [[[NSMutableAttributedString alloc] initWithString:@"GL Capabilities:" attributes:bold12Attribs] autorelease];
		
		appendString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n  Max VRAM- %ld MB (%ld MB free)", displayCaps[theIndex].deviceVRAM / 1024 / 1024, displayCaps[theIndex].deviceTextureRAM / 1024 / 1024] attributes:normal9Attribs];
		[outString appendAttributedString:appendString];
		[appendString release];
	
		appendString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"\n  Max Texture Size- 1D/2D: %ld, 3D: %ld, Cube: %ld, Rect: %ld (%ld texture units)", displayCaps[theIndex].maxTextureSize, displayCaps[theIndex].max3DTextureSize, displayCaps[theIndex].maxCubeMapTextureSize, displayCaps[theIndex].maxRectTextureSize, displayCaps[theIndex].textureUnits] attributes:normal9Attribs];
		[outString appendAttributedString:appendString];
		[appendString release];

		appendString = [[NSMutableAttributedString alloc] initWithString:@"\n Features:" attributes:bold9Attribs];
		[outString appendAttributedString:appendString];
		[appendString release];

		if (displayCaps[theIndex].fAuxDeptStencil) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Aux depth and stencil (GL_APPLE_aux_depth_stencil)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fClientStorage) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Client Storage (GL_APPLE_client_storage)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fElementArray) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Element Array (GL_APPLE_element_array)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFence) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Fence (GL_APPLE_fence)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFloatPixels) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Floating Point Pixels (GL_APPLE_float_pixels)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFlushBufferRange) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Selective VBO flushing (GL_APPLE_flush_buffer_range)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFlushRenderer) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Flush Renderer (GL_APPLE_flush_render)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fObjectPurgeable) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Object Purgeability (GL_APPLE_object_purgeable)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPackedPixels) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Packed Pixels (GL_APPLE_packed_pixels or OpenGL 1.2+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPixelBuffer) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Pixel Buffers (GL_APPLE_pixel_buffer)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fSpecularVector) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Specular Vector (GL_APPLE_specular_vector)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTextureRange) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Range (AGP Texturing) (GL_APPLE_texture_range)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTransformHint) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Transform Hint (GL_APPLE_transform_hint)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fVAO) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Vertex Array Object (GL_APPLE_vertex_array_object)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fVAR) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Vertex Array Range (GL_APPLE_vertex_array_range)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fVPEvals) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Vertex Program Evaluators (GL_APPLE_vertex_program_evaluators)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fYCbCr) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  YCbCr Textures (GL_APPLE_ycbcr_422)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fDepthTex) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Depth Texture (GL_ARB_depth_texture or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fDrawBuffers) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Multiple Render Targets (GL_ARB_draw_buffers or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFragmentProg) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Fragment Program (GL_ARB_fragment_program)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFragmentProgShadow) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Fragment Program Shadows (GL_ARB_fragment_program_shadow)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFragmentShader) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Fragment Shaders (GL_ARB_fragment_shader or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fHalfFloatPixel) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Half Float Pixels (GL_ARB_half_float_pixel)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fImaging) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Imaging Subset (GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fMultisample) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Multisample (Anti-aliasing) (GL_ARB_multisample or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fMultitexture) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Multitexture (GL_ARB_multitexture or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fOcclusionQuery) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Occlusion Queries (GL_ARB_occlusion_query or OpenGL 1.5+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPBO) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Pixel Buffer Objects (GL_ARB_pixel_buffer_object or OpenGL 2.1+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPointParam) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Point Parameters (GL_ARB_point_parameters or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPointSprite) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Point Sprites (GL_ARB_point_sprite or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fShaderObjects) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Shader Objects (GL_ARB_shader_objects or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fShaderTextureLOD) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Shader Texture LODs (GL_ARB_shader_texture_lod)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fShadingLanguage100) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Shading Language 1.0 (GL_ARB_shading_language_100 or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fShadow) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Shadow Support (GL_ARB_shadow or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fShadowAmbient) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Shadow Ambient (GL_ARB_shadow_ambient)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexBorderClamp) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Border Clamp (GL_ARB_texture_border_clamp or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexCompress) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Compression (GL_ARB_texture_compression or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexCubeMap) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Env Cube Map (GL_ARB_texture_cube_map or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexEnvAdd) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Env Add (GL_ARB_texture_env_add, GL_EXT_texture_env_add or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexEnvCombine) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Env Combine (GL_ARB_texture_env_combine or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexEnvCrossbar) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Env Crossbar (GL_ARB_texture_env_crossbar or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexEnvDot3) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Env Dot3 (GL_ARB_texture_env_dot3 or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexFloat) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Floating Point Textures (GL_ARB_texture_float)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexMirrorRepeat) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Mirrored Repeat (GL_ARB_texture_mirrored_repeat or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexNPOT) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Non Power of Two Textures (GL_ARB_texture_non_power_of_two or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexRectARB) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Rectangle (GL_ARB_texture_rectangle)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTransposeMatrix) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Transpose Matrix (GL_ARB_transpose_matrix or OpenGL 1.3+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fVertexBlend) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Vertex Blend (GL_ARB_vertex_blend)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fVBO) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Vertex Buffer Objects (GL_ARB_vertex_buffer_object or OpenGL 1.5+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fVertexProg) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Vertex Program (GL_ARB_vertex_program)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fVertexShader) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Vertex Shaders (GL_ARB_vertex_shader or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fWindowPos) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Window Position (GL_ARB_window_pos or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fArrayRevComps4Byte) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Reverse 4 Byte Array Components (GL_ATI_array_rev_comps_in_4_bytes)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fATIBlendEqSep) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Separate Blend Equations (GL_ATI_blend_equation_separate)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBlendWeightMinMax) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Blend Weighted Min/Max (GL_ATI_blend_weighted_minmax)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPNtriangles) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  PN Triangles (GL_ATI_pn_triangles or GL_ATIX_pn_triangles)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPointCull) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Point Culling (GL_ATI_point_cull_mode)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fSepStencil) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Separate Stencil (GL_ATI_separate_stencil)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTextFragShader) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Text Fragment Shader (GL_ATI_text_fragment_shader)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexComp3dc) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  ATI 3dc Compressed Textures (GL_ATI_texture_compression_3dc)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fCombine3) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Env Combine 3 (GL_ATI_texture_env_combine3)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexATIfloat) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  ATI Floating Point Textures (GL_ATI_texture_float)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexMirrorOnce) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Mirror Once (GL_ATI_texture_mirror_once)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fABGR) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  ABGR Texture Support (GL_EXT_abgr)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBGRA) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  BGRA Texture Support (GL_EXT_bgra or OpenGL 1.2+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBlendColor) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Blend Color (GL_EXT_blend_color or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBlendEqSep) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Separate Blending Equations for RGB and Alpha (GL_EXT_blend_equation_separate or OpenGL 2.0+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBlendFuncSep) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Separate Blend Function (GL_EXT_blend_func_separate or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBlendMinMax) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Blend Min/Max (GL_EXT_blend_minmax or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBlendSub) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Blend Subtract (GL_EXT_blend_subtract or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fClipVolHint) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Clip Volume Hint (GL_EXT_clip_volume_hint)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fColorSubtable) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Color Subtable ( GL_EXT_color_subtable or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fCVA) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Compiled Vertex Array (GL_EXT_compiled_vertex_array)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fDepthBounds) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Depth Boundary Test (GL_EXT_depth_bounds_test)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fConvolution) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Convolution ( GL_EXT_convolution or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fDrawRangeElements) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Draw Range Elements (GL_EXT_draw_range_elements)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFogCoord) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Fog Coordinate (GL_EXT_fog_coord)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFBOblit) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  FBO Blit (GL_EXT_framebuffer_blit)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFBO) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Framebuffer Objects or FBOs (GL_EXT_framebuffer_object)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fGeometryShader4) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  4th Gen Geometry Shader (GL_EXT_geometry_shader4)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fGPUProgParams) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  GPU Program Parameters (GL_EXT_gpu_program_parameters)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fGPUShader4) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  4th Gen GPU Shaders (GL_EXT_gpu_shader4)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fHistogram) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Histogram ( GL_EXT_histogram or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fDepthStencil) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Packed Depth and Stencil (GL_EXT_packed_depth_stencil)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fMultiDrawArrays) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Multi-Draw Arrays (GL_EXT_multi_draw_arrays or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fPaletteTex) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Paletted Textures (GL_EXT_paletted_texture)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fRescaleNorm) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Rescale Normal (GL_EXT_rescale_normal or OpenGL 1.2+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fSecColor) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Secondary Color (GL_EXT_secondary_color or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fSepSpecColor) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Separate Specular Color (GL_EXT_separate_specular_color or OpenGL 1.2+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fShadowFunc) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Shadow Function (GL_EXT_shadow_funcs)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fShareTexPalette) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Shared Texture Palette (GL_EXT_shared_texture_palette)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fStencil2Side) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  2-Sided Stencil (GL_EXT_stencil_two_side)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fStencilWrap) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Stencil Wrap (GL_EXT_stencil_wrap or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexCompDXT1) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  DXT Compressed Textures (GL_EXT_texture_compression_dxt1)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTex3D) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  3D Texturing (GL_EXT_texture3D or OpenGL 1.2+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexCompressS3TC) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Compression S3TC (GL_EXT_texture_compression_s3tc)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexFilterAniso) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Anisotropic Texture Filtering (GL_EXT_texture_filter_anisotropic)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexLODBias) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Level Of Detail Bias (GL_EXT_texture_lod_bias or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexMirrorClamp) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture mirror clamping (GL_EXT_texture_mirror_clamp)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexRect) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Rectangle (GL_EXT_texture_rectangle)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexSRGB) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  sRGB Textures (GL_EXT_texture_sRGB or OpenGL 2.1+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTransformFeedback) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Transform Feedback (GL_EXT_transform_feedback)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fConvBorderModes) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Convolution Border Modes (GL_HP_convolution_border_modes or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fRasterPosClip) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Raster Position Clipping (GL_IBM_rasterpos_clip)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fBlendSquare) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Blend Square (GL_NV_blend_square or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fDepthClamp) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Depth Clamp (GL_NV_depth_clamp)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fFogDist) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Eye Radial Fog Distance (GL_NV_fog_distance)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fLightMaxExp) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Light Max Exponent (GL_NV_light_max_exponent)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fMultisampleFilterHint) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Multi-Sample Filter Hint (GL_NV_multisample_filter_hint)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fNVPointSprite) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  NV Point Sprites (GL_NV_point_sprite)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fRegCombiners) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Register Combiners (GL_NV_register_combiners)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fRegCombiners2) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Register Combiners 2 (GL_NV_register_combiners2)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexGenReflect) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  TexGen Reflection (GL_NV_texgen_reflection)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexEnvCombine4) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Env Combine 4 (GL_NV_texture_env_combine4)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexShader) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Shader (GL_NV_texture_shader)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexShader2) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Shader 2 (GL_NV_texture_shader2)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexShader3) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Shader 3 (GL_NV_texture_shader3)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fGenMipmap) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  MipMap Generation (GL_SGIS_generate_mipmap or OpenGL 1.4+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexEdgeClamp) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Edge Clamp (GL_SGIS_texture_edge_clamp or OpenGL 1.2+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fTexLOD) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Texture Level Of Detail (GL_SGIS_texture_lod or OpenGL 1.2+)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fColorMatrix) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Color Matrix ( GL_SGI_color_matrix or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		if (displayCaps[theIndex].fColorTable) {
			appendString = [[NSMutableAttributedString alloc] initWithString:@"\n  Color Table ( GL_SGI_color_table or GL_ARB_imaging)" attributes:normal9Attribs];
			[outString appendAttributedString:appendString];
			[appendString release];
		}
		
		capsTexture = [[GLString alloc] initWithAttributedString:outString withTextColor:[NSColor colorWithDeviceRed:1.0f green:1.0f blue:1.0f alpha:1.0f] withBoxColor:[NSColor colorWithDeviceRed:0.4f green:0.4f blue:0.0f alpha:0.4f] withBorderColor:[NSColor colorWithDeviceRed:0.8f green:0.8f blue:0.0f alpha:0.8f]];
		[capsTextures addObject:capsTexture];
		[capsTexture release];
	}
}

// get NSString with caps for this renderer
void drawCaps (GLCaps * displayCaps, CGDisplayCount numDisplays, long renderer, GLfloat width) // view width for drawing location
{ // we are already in an orthographic per pixel projection
	short i;
	// match display in caps list
	for (i = 0; i < numDisplays; i++) {
		if (renderer == displayCaps[i].rendererID) {
			GLString *capsTexture = [capsTextures objectAtIndex:i];
			[capsTexture drawAtPoint:NSMakePoint (width - 10.0f - [capsTexture frameSize].width, 10.0f)];
			break;
		}
	}
}
	/*
		return outString;		
	*/
