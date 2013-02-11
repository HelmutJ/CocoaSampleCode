//
// File:       terrain_kernels.cl
//
// Abstract:   This example shows how OpenCL can be used to create a procedural field of 
//             grass on a generated terrain model which is then rendered with OpenGL.  
//             Because OpenGL buffers are shared with OpenCL, the data can remain on the 
//             graphics card, thus eliminating the API overhead of creating and submitting 
//             the vertices from the host.
//
//             All geometry is generated on the compute device, and outputted into
//             a shared OpenGL buffer.  The terrain gets generated only within the 
//             visible arc covering the camera's view frustum to avoid the need for 
//             culling.  A page of grass is computed on the surface of the terrain as
//             bezier patches, and flow noise is applied to the angle of the blades
//             to simulate wind.  Multiple instances of grass are rendered at jittered
//             offsets to add more grass coverage without having to compute new pages.
//             Finally, a physically based sky shader (via OpenGL) is applied to 
//             the background to provide an environment for the grass.
//
// Version:    <1.0>
//
// Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc. ("Apple")
//             in consideration of your agreement to the following terms, and your use,
//             installation, modification or redistribution of this Apple software
//             constitutes acceptance of these terms.  If you do not agree with these
//             terms, please do not use, install, modify or redistribute this Apple
//             software.
//
//             In consideration of your agreement to abide by the following terms, and
//             subject to these terms, Apple grants you a personal, non - exclusive
//             license, under Apple's copyrights in this original Apple software ( the
//             "Apple Software" ), to use, reproduce, modify and redistribute the Apple
//             Software, with or without modifications, in source and / or binary forms;
//             provided that if you redistribute the Apple Software in its entirety and
//             without modifications, you must retain this notice and the following text
//             and disclaimers in all such redistributions of the Apple Software. Neither
//             the name, trademarks, service marks or logos of Apple Inc. may be used to
//             endorse or promote products derived from the Apple Software without specific
//             prior written permission from Apple.  Except as expressly stated in this
//             notice, no other rights or licenses, express or implied, are granted by
//             Apple herein, including but not limited to any patent rights that may be
//             infringed by your derivative works or by other works in which the Apple
//             Software may be incorporated.
//
//             The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
//             WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
//             WARRANTIES OF NON - INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A
//             PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION
//             ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
//
//             IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
//             CONSEQUENTIAL DAMAGES ( INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//             SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//             INTERRUPTION ) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION
//             AND / OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER
//             UNDER THEORY OF CONTRACT, TORT ( INCLUDING NEGLIGENCE ), STRICT LIABILITY OR
//             OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// Copyright ( C ) 2008 Apple Inc. All Rights Reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////

#ifndef M_PI
#define M_PI        3.14159265358979323846264338327950288   /* pi */
#endif
#define DEG_TO_RAD             ((float)(M_PI / 180.0))
#define RADIANS(x)             (radians((x))) 

#define ONE_F1                 (1.0f)
#define ZERO_F1                (0.0f)

static const float4 ZERO_F4 = (float4){ 0.0f, 0.0f, 0.0f, 0.0f };
static const float4 ONE_F4  = (float4){ 1.0f, 1.0f, 1.0f, 1.0f };

////////////////////////////////////////////////////////////////////////////////////////////////////

__constant int P_MASK = 255;
__constant int P_SIZE = 256;
__constant int P[512] = {151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
  151,160,137,91,90,15,
  131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
  190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
  88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
  77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
  102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
  135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
  5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
  223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
  129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
  251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
  49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
  138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,  
  };

////////////////////////////////////////////////////////////////////////////////////////////////////

__constant int G_MASK = 15;
__constant int G_SIZE = 16;
__constant int G_VECSIZE = 4;
__constant float G[16*4] = {
	  +ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	  -ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	  +ONE_F1,  -ONE_F1, +ZERO_F1, +ZERO_F1, 
	  -ONE_F1,  -ONE_F1, +ZERO_F1, +ZERO_F1,
	  +ONE_F1, +ZERO_F1,  +ONE_F1, +ZERO_F1, 
	  -ONE_F1, +ZERO_F1,  +ONE_F1, +ZERO_F1, 
	  +ONE_F1, +ZERO_F1,  -ONE_F1, +ZERO_F1, 
	  -ONE_F1, +ZERO_F1,  -ONE_F1, +ZERO_F1,
	 +ZERO_F1,  +ONE_F1,  +ONE_F1, +ZERO_F1, 
	 +ZERO_F1,  -ONE_F1,  +ONE_F1, +ZERO_F1, 
	 +ZERO_F1,  +ONE_F1,  -ONE_F1, +ZERO_F1, 
	 +ZERO_F1,  -ONE_F1,  -ONE_F1, +ZERO_F1,
	  +ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	  -ONE_F1,  +ONE_F1, +ZERO_F1, +ZERO_F1, 
	 +ZERO_F1,  -ONE_F1,  +ONE_F1, +ZERO_F1, 
	 +ZERO_F1,  -ONE_F1,  -ONE_F1, +ZERO_F1
};  
  
////////////////////////////////////////////////////////////////////////////////////////////////////

int mod(int x, int a)
{
	int n = (x / a);
	int v = v - n * a;
	if ( v < 0 )
		v += a;
	return v;	
}

float smooth(float t)
{
	return t*t*t*(t*(t*6.0f-15.0f)+10.0f); 
}

float4 normalized(float4 v)
{
	float d = sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
    d = d > 0.0f ? d : 1.0f;
	
	float4 result = (float4){ v.x, v.y, v.z, 0.0f };
	result /= d;
	result.w = 1.0f;
    return result;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
 
float mix1d(float a, float b, float t)
{
	float ba = b - a;
	float tba = t * ba;
	float atba = a + tba;
	return atba;	
}

float2 mix2d(float2 a, float2 b, float t)
{
	float2 ba = b - a;
	float2 tba = t * ba;
	float2 atba = a + tba;
	return atba;	
}

float4 mix3d(float4 a, float4 b, float t)
{
	float4 ba = b - a;
	float4 tba = t * ba;
	float4 atba = a + tba;
	return atba;	
}

////////////////////////////////////////////////////////////////////////////////////////////////////

int lattice1d(int i)
{
	return P[i];
}

int lattice2d(int2 i)
{
	return P[i.x + P[i.y]];
}

int lattice3d(int4 i)
{
	return P[i.x + P[i.y + P[i.z]]];
}

////////////////////////////////////////////////////////////////////////////////////////////////////

float gradient1d(int i, float v)
{
	int index = (lattice1d(i) & G_MASK) * G_VECSIZE;
	float g = G[index + 0];
	return (v * g);
}

float gradient2d(int2 i, float2 v)
{
	int index = (lattice2d(i) & G_MASK) * G_VECSIZE;
	float2 g = (float2){ G[index + 0], G[index + 1] };
	return dot(v, g);
}

float gradient3d(int4 i, float4 v)
{
	int index = (lattice3d(i) & G_MASK) * G_VECSIZE;
	float4 g = (float4){ G[index + 0], G[index + 1], G[index + 2], 1.0f };
	return dot(v, g);
}

float2 rotated_gradient2d(int2 i, float2 v, float2 r)
{
	int index = (lattice2d(i) & G_MASK) * G_VECSIZE;
	float2 g = (float2){ G[index + 0], G[index + 1] };
    g.x = r.x * g.x - r.y * g.y;
    g.y = r.y * g.x + r.x * g.y;
	return g;
}

float dot_rotated_gradient2d(int2 i, float2 v, float2 r)
{
    int index = (lattice2d(i) & G_MASK) * G_VECSIZE;
    float2 g = (float2){ G[index + 0], G[index + 1] };
    g.x = r.x * g.x - r.y * g.y;
    g.y = r.y * g.x + r.x * g.y;
    return dot(v, g);
}

////////////////////////////////////////////////////////////////////////////////////////////////////


// Unsigned cell noise 1d  (+0.0f -> +1.0f)
float CellNoise1dfu(float position)
{
	float p = position;
	float pf = floor(p);
	int ip = (int)pf;
	float fp = p - pf;        
    ip &= P_MASK;

    return (lattice1d(ip) * (1.0f / (P_SIZE - 1)));
}

// Signed cell noise 1d (-1.0 -> +1.0f)
float CellNoise1dfs(float position)
{
    return 2.0f * CellNoise1dfu(position) - 1.0f;
}

// Unsigned cell noise 2d  (+0.0f -> +1.0f)
float CellNoise2dfu(float2 position)
{
	float2 p = position;
	float2 pf = floor(p);
	int2 ip = (int2){ (int)pf.x, (int)pf.y };
	float2 fp = p - pf;        
    ip &= P_MASK;
	
    return (lattice2d(ip) * (1.0f / (P_SIZE - 1)));
}

// Signed cell noise 2d (-1.0 -> +1.0f)
float CellNoise2dfs(float2 position)
{
    return 2.0f * CellNoise2dfu(position) - 1.0f;
}

// Unsigned cell noise 3d (+0.0f -> +1.0f)
float CellNoise3dfu(float4 position)
{
	float4 p = position;
	float4 pf = floor(p);
	int4 ip = (int4){(int)pf.x, (int)pf.y, (int)pf.z, 0 };
	float4 fp = p - pf;        
    ip &= P_MASK;
    
    return (lattice3d(ip) * (1.0f / (P_SIZE - 1)));
}

// Signed cell noise 2d (-1.0 -> +1.0f)
float CellNoise3dfs(float4 position)
{
    return 2.0f * CellNoise3dfu(position) - 1.0f;
}

////////////////////////////////////////////////////////////////////////////////////////////////////

// Signed gradient noise 1d (-1.0 -> +1.0f)
float GradientNoise1dfs(float position)
{
	float p = position;
	float pf = floor(p);
	int ip = (int)pf;
	float fp = p - pf;        
    ip &= P_MASK;
	
	float n0 = gradient1d(ip + 0, fp - 0.0f);
	float n1 = gradient1d(ip + 1, fp - 1.0f);

	float n = mix1d(n0, n1, smooth(fp));
	return n * (1.0f / 0.7f);
}

// Unsigned Gradient Noise 1d
float GradientNoise1dfu(float position)
{
    return (0.5f - 0.5f * GradientNoise1dfs(position));
}

// Signed gradient noise 2d (-1.0 -> +1.0f)
float GradientNoise2dfs(float2 position)
{
	float2 p = position;
	float2 pf = floor(p);
	int2 ip = (int2){ (int)pf.x, (int)pf.y };
	float2 fp = p - pf;        
    ip &= P_MASK;
	
	const int2 I00 = (int2){ 0, 0 };
	const int2 I01 = (int2){ 0, 1 };
	const int2 I10 = (int2){ 1, 0 };
	const int2 I11 = (int2){ 1, 1 };
	
	const float2 F00 = (float2){ 0.0f, 0.0f };
	const float2 F01 = (float2){ 0.0f, 1.0f };
	const float2 F10 = (float2){ 1.0f, 0.0f };
	const float2 F11 = (float2){ 1.0f, 1.0f };

	float n00 = gradient2d(ip + I00, fp - F00);
	float n10 = gradient2d(ip + I10, fp - F10);
	float n01 = gradient2d(ip + I01, fp - F01);
	float n11 = gradient2d(ip + I11, fp - F11);

	const float2 n0001 = (float2){ n00, n01 };
	const float2 n1011 = (float2){ n10, n11 };

	float2 n2 = mix2d(n0001, n1011, smooth(fp.x));
	float n = mix1d(n2.x, n2.y, smooth(fp.y));
	return n * (1.0f / 0.7f);
}

// Unsigned Gradient Noise 2d
float GradientNoise2dfu(float2 position)
{
    return (0.5f - 0.5f * GradientNoise2dfs(position));
}

// Signed gradient noise 3d (-1.0 -> +1.0f)
float GradientNoise3dfs(float4 position)
{
	float4 p = position;
	float4 pf = floor(p);
	int4 ip = (int4){(int)pf.x, (int)pf.y, (int)pf.z, 0 };
	float4 fp = p - pf;        
    ip &= P_MASK;

    int4 I000 = (int4){0, 0, 0, 0};
    int4 I001 = (int4){0, 0, 1, 0};  
    int4 I010 = (int4){0, 1, 0, 0};
    int4 I011 = (int4){0, 1, 1, 0};
    int4 I100 = (int4){1, 0, 0, 0};
    int4 I101 = (int4){1, 0, 1, 0};
    int4 I110 = (int4){1, 1, 0, 0};
    int4 I111 = (int4){1, 1, 1, 0};
	
    float4 F000 = (float4){ 0.0f, 0.0f, 0.0f, 0.0f };
    float4 F001 = (float4){ 0.0f, 0.0f, 1.0f, 0.0f };
    float4 F010 = (float4){ 0.0f, 1.0f, 0.0f, 0.0f };
    float4 F011 = (float4){ 0.0f, 1.0f, 1.0f, 0.0f };
    float4 F100 = (float4){ 1.0f, 0.0f, 0.0f, 0.0f };
    float4 F101 = (float4){ 1.0f, 0.0f, 1.0f, 0.0f };
    float4 F110 = (float4){ 1.0f, 1.0f, 0.0f, 0.0f };
    float4 F111 = (float4){ 1.0f, 1.0f, 1.0f, 0.0f };
	
	float n000 = gradient3d(ip + I000, fp - F000);
	float n001 = gradient3d(ip + I001, fp - F001);
	
	float n010 = gradient3d(ip + I010, fp - F010);
	float n011 = gradient3d(ip + I011, fp - F011);
	
	float n100 = gradient3d(ip + I100, fp - F100);
	float n101 = gradient3d(ip + I101, fp - F101);

	float n110 = gradient3d(ip + I110, fp - F110);
	float n111 = gradient3d(ip + I111, fp - F111);

	float4 n40 = (float4){ n000, n001, n010, n011 };
	float4 n41 = (float4){ n100, n101, n110, n111 };

	float4 n4 = mix3d(n40, n41, smooth(fp.x));
	float2 n2 = mix2d(n4.xy, n4.zw, smooth(fp.y));
	float n = mix1d(n2.x, n2.y, smooth(fp.z));
	return n * (1.0f / 0.7f);
}

// Unsigned Gradient Noise 3d
float GradientNoise3dfu(float4 position)
{
    return (0.5f - 0.5f * GradientNoise3dfs(position));
}

////////////////////////////////////////////////////////////////////////////////////////////////////

float RotatedGradientNoise2dfs(float2 position, float angle)
{
    float2 p = position;
    float2 pf = floor(p);
    int2 ip = (int2){ (int)pf.x, (int)pf.y };
    float2 fp = p - pf;
    ip &= P_MASK;

    float r = radians(angle);
    float2 rg = (float2){ native_sin(r), native_cos(r) };

    const int2 I00 = (int2){ 0, 0 };
    const int2 I01 = (int2){ 0, 1 };
    const int2 I10 = (int2){ 1, 0 };
    const int2 I11 = (int2){ 1, 1 };

    const float2 F00 = (float2){ 0.0f, 0.0f };
    const float2 F01 = (float2){ 0.0f, 1.0f };
    const float2 F10 = (float2){ 1.0f, 0.0f };
    const float2 F11 = (float2){ 1.0f, 1.0f };

    float n00 = dot_rotated_gradient2d(ip + I00, fp - F00, rg);
    float n10 = dot_rotated_gradient2d(ip + I10, fp - F10, rg);
    float n01 = dot_rotated_gradient2d(ip + I01, fp - F01, rg);
    float n11 = dot_rotated_gradient2d(ip + I11, fp - F11, rg);

    const float2 n0001 = (float2){ n00, n01 };
    const float2 n1011 = (float2){ n10, n11 };

    float2 n2 = mix2d(n0001, n1011, smooth(fp.x));
    float n = mix1d(n2.x, n2.y, smooth(fp.y));
    return n * (1.0f / 0.7f);
}

float4 
RotatedSimplexNoise2dfs( 
    float2 position, float angle )
{
	float2 p = position;
    float r = radians(angle);
    float2 rg = (float2){ native_sin(r), native_cos(r) };
    
    const float F2 = 0.366025403f; // 0.5*(sqrt(3.0)-1.0)
    const float G2 = 0.211324865f; // (3.0-Math.sqrt(3.0))/6.0
    const float G22 = 2.0f * G2;
    
    const float2 FF = (float2){ F2, F2 };
    const float2 GG = (float2){ G2, G2 };
    const float2 GG2 = (float2){ G22, G22 };
    
   	const float2 F00 = (float2){ 0.0f, 0.0f };
   	const float2 F01 = (float2){ 0.0f, 1.0f };
   	const float2 F10 = (float2){ 1.0f, 0.0f };
   	const float2 F11 = (float2){ 1.0f, 1.0f };

	const int2 I00 = (int2){ 0, 0 };
	const int2 I01 = (int2){ 0, 1 };
	const int2 I10 = (int2){ 1, 0 };
	const int2 I11 = (int2){ 1, 1 };

    float s = ( p.x + p.y ) * F2;
    float2 ps = (float2){ p.x + s, p.y + s };
	float2 pf = floor(ps);
	int2 ip = (int2){ (int)pf.x, (int)pf.y };
    ip &= (int2){ P_MASK, P_MASK };
	
    float t = ( pf.x + pf.y ) * G2;
    float2 tt = (float2){ t, t };
    float2 tf = pf - tt;
	float2 fp = p - tf;        
    
	float2 p0 = fp;
	int2 i1 = (p0.x > p0.y) ? (I10) : (I01);
	float2 f1 = (p0.x > p0.y) ? (F10) : (F01);
    
	float2 p1 = p0 - f1 + GG; 
	float2 p2 = p0 - F11 + GG2;

    float t0 = 0.5f - p0.x * p0.x - p0.y * p0.y;
    float t1 = 0.5f - p1.x * p1.x - p1.y * p1.y;
    float t2 = 0.5f - p2.x * p2.x - p2.y * p2.y;

    float2 g0 = F00;
    float2 g1 = F00;
    float2 g2 = F00;
    
    float n0 = 0.0f;
    float n1 = 0.0f;
    float n2 = 0.0f;
    
    float t20 = 0.0f;
    float t40 = 0.0f;
    float t21 = 0.0f;
    float t41 = 0.0f;
    float t22 = 0.0f;
    float t42 = 0.0f;

    if(t0 >= 0.0f)
    {   
        g0 = rotated_gradient2d(ip + I00, p0, rg);
        t20 = t0 * t0;
        t40 = t20 * t20;
        n0 = t40 * dot(p0, g0); 
    }

    if(t1 >= 0.0f)
    {
        g1 = rotated_gradient2d(ip + i1, p1, rg);
        t21 = t1 * t1;
        t41 = t21 * t21;
        n1 = t41 * dot(p1, g1); 
    }

    if(t2 >= 0.0f)
    {
        g2 = rotated_gradient2d(ip + I11, p2, rg);
        t22 = t2 * t2;
        t42 = t22 * t22;
        n2 = t42 * dot(p2, g2); 
    }

    float noise = 40.0f * ( n0 + n1 + n2 );
    
    float2 dn = p0 * t20 * t0 * dot(p0, g0);
    dn += p1 * t21 * t1 * dot(p1, g1);   
    dn += p2 * t22 * t2 * dot(p2, g2);
    dn *= -8.0f;
    dn += t40 * g0 + t41 * g1 + t42 * g2;
    dn *= 40.0f;

    return (float4){ noise, dn.x, dn.y, 1.0f };
}

////////////////////////////////////////////////////////////////////////////////////////////////////

float4
ComputeRadialGridPosition(
    float2 uv,
    float2 vt,
    float2 ve,
    float4 camera_position,
    float4 camera_rotation,
    float4 camera_view,
    float4 camera_left,
    float camera_fov)
{
    float4 normal = (float4){ 0.0f, 1.0f, 0.0f, 1.0f };
    float ndl = fmax(0.1f, (dot(normal, camera_view)));
    float extend = 20.0f / ndl;
    float ninety = RADIANS(90.0f);
    float cr = RADIANS(camera_rotation.x) + RADIANS(camera_fov - extend * 0.5f);
    float angle = RADIANS(camera_fov + extend) * uv.y;

    angle = (angle >= RADIANS(180.0f)) ? (angle - RADIANS(180.0f)) : angle;
    cr += (angle >= RADIANS(180.0f)) ? RADIANS(-camera_rotation.x) : 0.0f;

    float s = (cr > 0.0f) ? (1.0f) : (-1.0f);

    float a0 = 0.1f;
    float a1 = 0.05f / ve.x * ve.y;
    
    float x2 = vt.x * vt.x;
    float fr = a0 + a1 * x2;
    float fx = fr * native_cos(cr + angle);
    float fy = fr * native_sin(cr + angle);
    
    float4 view = (float4){ 0.0f, 0.0f,   fy, 1.0f };
    float4 left = (float4){  -fx, 0.0f, 0.0f, 1.0f };
    
    float4 position = camera_position - camera_view * extend * 0.25f + view + left;

    position.y = 0.0f;
    position.w = 1.0f;
    return position;
}


float2
GetGridCoordinates(int index, int2 size)
{
    float2 coord;
    coord.x = index % size.x;
    index /= size.x;
    coord.y = index % size.y;
    return coord;
}

__kernel void 
ComputeTerrainKernel(
    int2 grid_resolution,
    float4 camera_position, 
    float4 camera_rotation,
	float4 camera_view, 
	float4 camera_left, 
	float camera_fov,
    uint vertex_count,
	__global float4 *vertices,
	__global float4 *normals, 
	__global float2 *texcoords) 
{
    int tx = get_global_id(0);
    int ty = get_global_id(1);
    int sx = get_global_size(0);
    int sy = get_global_size(1);
    int index = ty * sx + tx;
    if(index > vertex_count)
        return;

    float frequency = 0.0025f;
    float amplitude = 70.00f;
    float phase = 1.0f;
    float lacunarity = 2.0345f;
    float increment = 1.0f;
    float octaves = 1.0f;
    float roughness = 1.00f;
    
    float ir = (float)index / (float)(vertex_count);
    int2 di = (int2){ tx, ty };
    float2 vt = GetGridCoordinates(index, grid_resolution);
    float2 vs = (float2){ 1.0f / (float)(grid_resolution.x), 1.0f / (float)(grid_resolution.y) };
    float2 ve = (float2){ (float)grid_resolution.x, (float)grid_resolution.y };
    float2 uv = vt * vs;

    float4 position = ComputeRadialGridPosition(uv, vt, ve, camera_position, camera_rotation, camera_view, camera_left, camera_fov);
    float4 bias = (float4){ phase, 0.0f, phase, 0.0f };
    float4 sample = position + bias;
    float4 noise = RotatedSimplexNoise2dfs(sample.xz * frequency, 35.0f);
	float displacement = noise.x;
		
    float4 normal = (float4){ 0.0f, 1.0f, 0.0f, 1.0f };
    float4 vertex = sample + (amplitude * displacement * normal);
    vertex.w = 1.0f;

    normal = (float4){ noise.y, 1.0f, noise.z, 1.0f };
    normal = normalize(normal);

    vertices[index] = vertex;
    normals[index] = normal;
    texcoords[index] = uv;
}

