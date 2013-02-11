//
// File:       grass_kernels.cl
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
GetGridPosition(
    float4 position, 
    float4 origin, 
    float4 cell_size)
{
    float4 grid_position;
    grid_position.x = floor((position.x - origin.x) / cell_size.x);
    grid_position.y = floor((position.y - origin.y) / cell_size.y);
    grid_position.z = floor((position.z - origin.z) / cell_size.z);
    grid_position.w = 0;
    return grid_position;
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

float4
GetPageCoordinates(float2 position)
{
	float2 p = position;
	float2 pf = floor(p);
	int2 ip = (int2){(int)pf.x, (int)pf.y };
	float2 fp = p - pf;
	return (float4){(float)ip.x, (float)ip.y, fp.x, fp.y };
}

float2
Bezier2d(
    float p, float b, float2 ba, float2 bb, float2 bc, float2 bd)
{
    float p2 = p * p;
    float p3 = p2 * p;

    float b2 = b * b;
    float b3 = b2 * b;

    float2 bezier;
    bezier  = ba * (b3);
    bezier += bb * (p * b2);
    bezier += bc * (p2 * b);
    bezier += bd * (p3);
    return bezier;
}


float4
ComputeBladeVertex(
    float2 bezier, float vz, float4 pos, float4 dir)
{
    float4 vertex = pos + dir * bezier.x;
    vertex.y = bezier.y;
    vertex.w = 1.0f;
    return (vertex);
}

float4
ComputeBladeColor(
    float4 base, float4 value, float4 mult, float4 offset,
    float2 luminance_alpha)
{
    float4 c = value * mult + offset + base;
    c *= luminance_alpha.x;
    c.w = 1.0f; // luminance_alpha.y;
    return c;
}

float
ComputeNoiseSample(
    float2 uv,
    float4 noise_bias_scale,
    float noise_amplitude)
{
    float2 noise_bias = noise_bias_scale.xy;
    float2 noise_scale = noise_bias_scale.zw;

    float2 p = (uv * noise_scale) + noise_bias;
    float noise_sample = GradientNoise2dfs(p) * noise_amplitude;
    return noise_sample;
}

float
ComputeFlowNoiseSample(
    float2 uv,
    float time_delta,
    float4 field_range,
    float4 noise_bias_scale,
    float noise_amplitude)
{
    float2 noise_bias = noise_bias_scale.xy;
    float2 noise_scale = noise_bias_scale.zw;

    float2 time_bias = (float2){ time_delta, time_delta };
    float2 field_bias = field_range.xy + time_bias;
    float2 field_size = field_range.zw;

    float2 p = (uv + field_bias) * 0.010f; // * noise_scale;
    float flow_sample = RotatedGradientNoise2dfs(p, time_delta) * noise_amplitude;
    return flow_sample;
}

float4
ComputeBladePosition(
    float2 uv,
    float falloff,
    float camera_fov_angle,
    float4 camera_position,
    float4 camera_view,
    float4 camera_left,
    float4 camera_up,
    float4 field_range,
    float2 clip_range,
    float noise_sample)
{
    float2 bp = (float2){ uv.x + noise_sample, uv.y + noise_sample };
    float4 base_position = (float4){ bp.x, 0.0f, bp.y, 1.0f };
    return base_position;
}

float
ComputeBladeLength(
    float noise_sample,
    float2 blade_length_range)
{
    float min_length = blade_length_range.x;
    float max_length = blade_length_range.y;
    float blade_length = mix1d(min_length, max_length, (noise_sample));
    return blade_length;
}

float
ComputeBladeThickness(
    float noise_sample,
    float2 blade_thickness_range,
    float eye_distance)
{
    float min_thickness = blade_thickness_range.x;
    float max_thickness = blade_thickness_range.y;
    float blade_thickness = mix1d(min_thickness, max_thickness, (noise_sample)); 
    return blade_thickness;
}


float2
ComputeBladeAngleTilt(
    float2 uv,
    float time_delta,
    float blade_angle,
    float blade_length,
    float4 flow_scale_speed_amount,
    float falloff)
{
    float2 vp = (float2){ uv.x, uv.y + time_delta };

    float flow_amount = flow_scale_speed_amount.w;

    float blade_tilt = blade_angle * blade_length  * flow_amount * (1.0f / 5.0f);

    return (float2){ blade_angle, blade_tilt };
}

float4
ComputeBladeOrientation(
    float4 camera_position,
    float4 blade_position,
    float eye_distance)
{
    float4 view_delta = (camera_position - blade_position) * (1.0f / eye_distance);
    float4 blade_up = (float4){ 0.0f, 1.0f, 0.0f, 1.0f };
    float4 blade_orientation = normalize(cross(view_delta,  blade_up));
    return blade_orientation;
}

float
ComputeEyeDistance(
    float4 eye_position,
    float4 blade_position)
{
    float4 view_delta = (eye_position - blade_position);
    float distance = half_sqrt(dot(view_delta, view_delta));
    return distance;
}


float
ComputeFalloff(
    float eye_distance,
    float max_distance,
    float falloff_distance)
{
    max_distance *= falloff_distance;
    float falloff = clamp(max_distance - eye_distance, 0.0f, max_distance) * (1.0f / max_distance);
    float f3 = falloff * falloff * falloff;
    return f3 * f3;
}

uint
CreateBezierCurve(
    uint vertex_index,
    float curve_detail,
    float2 uv,
    float4 blade_position,
    float4 blade_orientation,
    float blade_length,
    float2 blade_length_range,
    float blade_thickness,
    float2 blade_thickness_range,
    float2 blade_angle_tilt,
    float2 blade_luminance_alpha,
    uint4 blade_curve_segment_counts,
    __global float4 *output_vertices,
    __global float4 *output_colors)
{
    uint blade_count = blade_curve_segment_counts.x;
    float max_elements = blade_curve_segment_counts.y;
    float max_segments = blade_curve_segment_counts.z;
    uint max_vertex_count = (max_elements * max_segments * blade_count);

    float goffset = blade_angle_tilt.y / 100.0f;

    const float4 gbase = (float4){ (10.0f / 256.0f), (20.0f / 256.0f), 0.0f, 0.0f };
    const float4 gvalue = (float4){ (110.0f / 256.0f), (120.0f / 256.0f), (50.0f / 256.0f), 0.0f };

    float curve_segments = mix(2.0f, max_segments, curve_detail);
    float curve_delta = (1.0f / curve_segments);

    float thickness_delta = blade_thickness / (float)blade_length;
    float thickness_scale = blade_length / curve_segments;

    float k = 0.0f;
    uint element_count = 0;
    uint segment_count = 0;
    uint element_vertices = 0;

    float bxt = blade_angle_tilt.y;
    float bx = 0.0f;

    for (float p = 0.0f; p <= 1.0f && vertex_index < (max_vertex_count - 2); p += curve_delta)
    {
        float ck = k;
        float bpz = 1.0f;
        float gt = (ck < (blade_thickness * 0.5f) ) ? (blade_thickness - ck) : ck;

        float2 ba = 1.0f * (float2){ bxt, blade_position.y + blade_length };
        float2 bb = 3.0f * (float2){ bx + (ck * 0.040f), blade_position.y + blade_length * 0.75f };
        float2 bc = 3.0f * (float2){ bx + (ck * 0.045f), blade_position.y + blade_length * 0.25f };
        float2 bd = 1.0f * (float2){ bx + (ck * 0.030f), blade_position.y };

        float cp = p;
        float cb = 1.0f - cp;
        float gradient = cb;
        float2 bezier = Bezier2d(cp, cb, ba, bb, bc, bd);
        float4 vertex = ComputeBladeVertex(bezier, bpz, blade_position, blade_orientation);
        float4 color = ComputeBladeColor(gbase, gvalue, gt * gradient, goffset * cb, blade_luminance_alpha);

        output_vertices[vertex_index] = vertex;
        output_colors[vertex_index++] = color;

        cp = p + curve_delta;
        cb = 1.0f - cp;
        gradient = cb;
        bezier = Bezier2d(cp, cb, ba, bb, bc, bd);
        vertex = ComputeBladeVertex(bezier, bpz, blade_position, blade_orientation);
        color = ComputeBladeColor(gbase, gvalue, gt * gradient, goffset * cb, blade_luminance_alpha);

        output_vertices[vertex_index] = vertex;
        output_colors[vertex_index++] = color;

        element_vertices += 2;
    }

    return element_vertices;
}


uint
CreateBezierPatch(
    uint vertex_index,
    float curve_detail,
    float2 uv,
    float4 blade_position,
    float4 blade_orientation,
    float blade_length,
    float2 blade_length_range,
    float blade_thickness,
    float2 blade_thickness_range,
    float2 blade_angle_tilt,
    float2 blade_luminance_alpha,
    uint4 blade_curve_segment_counts,
    __global float4 *output_vertices,
    __global float4 *output_colors)
{
    uint blade_count = blade_curve_segment_counts.x;
    float max_elements = blade_curve_segment_counts.y;
    float max_segments = blade_curve_segment_counts.z;
    uint max_vertex_count = (max_elements * max_segments * blade_count);

    float goffset = blade_angle_tilt.y / 100.0f;

    const float4 gbase = (float4){ (10.0f / 256.0f), (20.0f / 256.0f), 0.0f, 0.0f };
    const float4 gvalue = (float4){ (110.0f / 256.0f), (120.0f / 256.0f), (50.0f / 256.0f), 0.0f };

    float curve_segments = mix(2.0f, max_segments, curve_detail);
    float curve_delta = (1.0f / curve_segments);

    float thickness_delta = blade_thickness / (float)blade_length;
    float thickness_scale = 1.0f; 

    float k = 0.0f;
    uint element_count = 0;
    uint segment_count = 0;
    uint element_vertices = 0;

    float bxt = blade_angle_tilt.y;
    float bx = 0.0f;

    for (float p = 0.0f; p <= 1.0f && vertex_index < (max_vertex_count - 4); p += curve_delta)
    {
        float ck = k;
        float bpz = 1.0f;
        float gt = (ck < (blade_thickness * 0.5f) ) ? (blade_thickness - ck) : ck;

        float2 ba = 1.0f * (float2){ bxt, blade_position.y + blade_length };
        float2 bb = 3.0f * (float2){ bx + (ck * 0.040f), blade_position.y + blade_length * 0.75f };
        float2 bc = 3.0f * (float2){ bx + (ck * 0.045f), blade_position.y + blade_length * 0.25f };
        float2 bd = 1.0f * (float2){ bx + (ck * 0.030f), blade_position.y };

        float cp = p;
        float cb = 1.0f - cp;
        float gradient = cb * thickness_scale;
        float2 bezier = Bezier2d(cp, cb, ba, bb, bc, bd);
        float4 vertex = ComputeBladeVertex(bezier, bpz, blade_position, blade_orientation);
        float4 color = ComputeBladeColor(gbase, gvalue, gt * gradient, goffset * cb, blade_luminance_alpha);

        output_vertices[vertex_index] = vertex;
        output_colors[vertex_index++] = color;

        cp = p + curve_delta;
        cb = 1.0f - cp;
        gradient = cb * thickness_scale;
        bezier = Bezier2d(cp, cb, ba, bb, bc, bd);
        vertex = ComputeBladeVertex(bezier, bpz, blade_position, blade_orientation);
        color = ComputeBladeColor(gbase, gvalue, gt * gradient, goffset * cb, blade_luminance_alpha);

        output_vertices[vertex_index] = vertex;
        output_colors[vertex_index++] = color;

        ck = (k + thickness_delta);
        gt = (ck < (blade_thickness * 0.5f) ) ? (blade_thickness - ck) : ck;

        ba = 1.0f * (float2){ bxt, blade_position.y + blade_length };
        bb = 3.0f * (float2){ bx + (ck * 0.040f), blade_position.y + blade_length * 0.75f };
        bc = 3.0f * (float2){ bx + (ck * 0.045f), blade_position.y + blade_length * 0.25f };
        bd = 1.0f * (float2){ bx + (ck * 0.030f), blade_position.y };

        cp = p + curve_delta;
        cb = 1.0f - cp;
        gradient = cb * thickness_scale;
        bezier = Bezier2d(cp, cb, ba, bb, bc, bd);
        vertex = ComputeBladeVertex(bezier, bpz, blade_position, blade_orientation);
        color = ComputeBladeColor(gbase, gvalue, gt * gradient, goffset * cb, blade_luminance_alpha);

        output_vertices[vertex_index] = vertex;
        output_colors[vertex_index++] = color;

        cp = p;
        cb = 1.0f - cp;
        gradient = cb * thickness_scale;
        bezier = Bezier2d(cp, cb, ba, bb, bc, bd);
        vertex = ComputeBladeVertex(bezier, bpz, blade_position, blade_orientation);
        color = ComputeBladeColor(gbase, gvalue, gt * gradient, goffset * cb, blade_luminance_alpha);

        output_vertices[vertex_index] = vertex;
        output_colors[vertex_index++] = color;
        element_vertices += 4;
    }

    return element_vertices;
}

//////////////////////////////////////////////////////////////////////////////

float4
ComputeRadialGridPosition(
    float2 uv,
    float2 vt,
    float2 ve,
    float2 clip_range,
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

    cr -= cr - floor(cr);
    
    float s = (cr > 0.0f) ? (1.0f) : (-1.0f);

    float a0 = clip_range.x;
    float a1 = clip_range.y - clip_range.x;
    
    float x2 = vt.x * vt.x;
    float fr = a0 + a1 * x2;
    float fx = fr * native_cos(cr + angle);
    float fy = fr * native_sin(cr + angle);
    
    float4 view = (float4){ 0.0f, 0.0f, (2.0f * uv.y - 1.0f) * ve.y + fy, 1.0f };
    float4 left = (float4){ ( 2.0f * uv.x - 1.0f) * ve.x + fx, 0.0f, 0.0f, 1.0f };

    camera_position.y = 0.0f;
    camera_position -= (camera_position - floor(camera_position * 0.1f));
    camera_view -= (camera_view - floor(camera_view));

    float4 position = camera_position + view + left;
    position.y = 0.0f;
    position.w = 1.0f;
    return position;
}

__kernel void
ComputeGrassOnTerrainKernel(
    int2 grid_resolution,
    float jitter_amount,
    float time_delta,
    float falloff_distance,
    float camera_fov,
    float4 camera_position,
    float4 camera_rotation,
    float4 camera_view,
    float4 camera_left,
    float4 camera_up,
    float2 clip_range,
    float2 blade_length_range,
    float2 blade_thickness_range,
    float2 blade_luminance_alpha,
    float4 flow_scale_speed_amount,
    float4 noise_bias_scale,
    float noise_amplitude,
    uint4 blade_curve_segment_counts,
    __global float4 *output_vertices,
    __global float4 *output_colors)
{
    int tx = get_global_id(0);
    int ty = get_global_id(1);
    int sx = get_global_size(0);
    int sy = get_global_size(1);
    int index = ty * sx + tx;

    uint blade_count = blade_curve_segment_counts.x;
    float max_elements = blade_curve_segment_counts.y;
    float max_segments = blade_curve_segment_counts.z;
    if (index >= blade_count)
        return;

    float ir = (float) index / (float) blade_count;
    uint vertex_index = index * max_elements * max_segments;
    uint max_element_vertices = max_elements * max_segments;
    float4 empty = (float4){-999999.0f, -999999.0f, -999999.0f, 0.0f };

    int2 di = (int2){ tx, ty };
    float2 vt = GetGridCoordinates(index, grid_resolution);
    float2 vs = (float2){ 1.0f / (float)(grid_resolution.x), 1.0f / (float)(grid_resolution.y) };
    float2 ve = (float2){ (float)grid_resolution.x, (float)grid_resolution.y };
    float2 uv = vt * vs;
    
    float4 look_at = camera_position + camera_view;
    float4 near_pos = camera_position + camera_view * clip_range.x;
    float4 far_pos = camera_position + camera_view * clip_range.y;
 
    float2 jitter_amplitude = (float2){ jitter_amount, jitter_amount };
    float4 jitter_bias_scale = (float4){ 0.0f, 0.0f, 10.0f, 10.0f };
    float clip_distance = length(clip_range);

    float frequency = 0.0025f;
    float amplitude = 70.00f;
    float phase = 1.0f;

    float4 position = ComputeRadialGridPosition(uv, vt, ve, clip_range, camera_position, camera_rotation, camera_view, camera_left, camera_fov);
    float4 bias = (float4){ phase, 0.0f, phase, 0.0f };
    float4 sample = position + bias;
    float4 noise = RotatedSimplexNoise2dfs(sample.xz * frequency, 35.0f);
	float displacement = noise.x;
	
    float4 normal = (float4){ 0.0f, 1.0f, 0.0f, 1.0f };
    float4 blade_position = sample + (amplitude * displacement * normal);
    blade_position.w = 1.0f;
    
    float4 left = (float4){ 1.0f, 0.0f, 0.0f, 1.0f };
    float4 up = (float4){ 0.0f, 1.0f, 0.0f, 1.0f };
    float4 view = (float4){ 0.0f, 0.0f, 1.0f, 1.0f };
    
    float4 rdnoise = RotatedSimplexNoise2dfs(sample.xz, uv.x * uv.y) * jitter_amount;
    blade_position = blade_position + rdnoise.y * left + rdnoise.z * view - fabs(rdnoise.x) * up;

    float2 np = blade_position.xz;  
    float4 field_range = noise_bias_scale;
    field_range.xy = noise_bias_scale.xy;

    float2 field_bias = field_range.xy;
    float2 field_size = field_range.zw;
    float field_length = length(field_size);

    float dist_falloff = uv.x;
    float noise_sample = ComputeNoiseSample(np, noise_bias_scale, noise_amplitude);
    float eye_distance = ComputeEyeDistance(camera_position, blade_position);
    float4 view_dir = normalize(camera_position - blade_position);

    float4 flow_bias_scale = noise_bias_scale;
    flow_bias_scale.zw = flow_scale_speed_amount.xy;
    float flow_speed = flow_scale_speed_amount.z;
    float blade_angle = ComputeNoiseSample(np, noise_bias_scale, 0.1f);
    blade_angle += ComputeFlowNoiseSample(np, time_delta * flow_speed, field_range, flow_bias_scale, noise_amplitude);

    eye_distance = ComputeEyeDistance(camera_position, blade_position);
    float falloff = ComputeFalloff(eye_distance, field_length, falloff_distance);
    float blade_detail = smooth(falloff);

    float blade_length = ComputeBladeLength(noise_sample, blade_length_range);
    float blade_thickness = ComputeBladeThickness(noise_sample, blade_thickness_range, eye_distance);
    float2 blade_angle_tilt = ComputeBladeAngleTilt(uv, time_delta, blade_angle, blade_length, flow_scale_speed_amount, falloff);
    float4 blade_orientation = ComputeBladeOrientation(camera_position, blade_position, eye_distance);

    uint element_vertices = CreateBezierPatch(vertex_index,
                                              blade_detail, uv,
                                              blade_position,
                                              blade_orientation,
                                              blade_length,
                                              blade_length_range,
                                              blade_thickness,
                                              blade_thickness_range,
                                              blade_angle_tilt,
                                              blade_luminance_alpha,
                                              blade_curve_segment_counts,
                                              output_vertices,
                                              output_colors);
/*
    for (uint i = vertex_index + element_vertices; i < vertex_index + max_element_vertices; i++)
    {
        output_vertices[i] = empty;
        output_colors[i] = empty;
    }
*/
}
