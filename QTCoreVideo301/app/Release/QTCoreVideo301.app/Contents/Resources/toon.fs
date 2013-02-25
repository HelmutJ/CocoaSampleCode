uniform sampler2DRect tex;
uniform bool          style;
uniform float         alpha;
uniform float         offset;

void main( void )
{
	int i;
	
	// fragment offsets
	
	vec2 fragOffset[8];
	
	fragOffset[0] = vec2( -offset, -offset );
	fragOffset[1] = vec2( -offset,     0.0 );
	fragOffset[2] = vec2( -offset,  offset );
	fragOffset[3] = vec2(  offset, -offset );
	fragOffset[4] = vec2(  offset,     0.0 );
	fragOffset[5] = vec2(  offset,  offset );
	fragOffset[6] = vec2(     0.0, -offset );
	fragOffset[7] = vec2(     0.0,  offset );

	// calculate texture coordinates offset
	
	vec2 texCoord[9];
	
	texCoord[0] = gl_TexCoord[0].st;
	texCoord[1] = texCoord[0] + fragOffset[0];
	texCoord[2] = texCoord[0] + fragOffset[1];
	texCoord[3] = texCoord[0] + fragOffset[2];
	texCoord[4] = texCoord[0] + fragOffset[3];
	texCoord[5] = texCoord[0] + fragOffset[4];
	texCoord[6] = texCoord[0] + fragOffset[5];
	texCoord[7] = texCoord[0] + fragOffset[6];
	texCoord[8] = texCoord[0] + fragOffset[7];

	// get the samples
	
	vec4 sample[9];

	sample[0] = texture2DRect(tex, texCoord[0]);
	sample[1] = texture2DRect(tex, texCoord[1]);
	sample[2] = texture2DRect(tex, texCoord[2]);
	sample[3] = texture2DRect(tex, texCoord[3]);
	sample[4] = texture2DRect(tex, texCoord[4]);
	sample[5] = texture2DRect(tex, texCoord[5]);
	sample[6] = texture2DRect(tex, texCoord[6]);
	sample[7] = texture2DRect(tex, texCoord[7]);
	sample[8] = texture2DRect(tex, texCoord[8]);

	// edge detection:
	//
	// (1) edge[0], the x-coordinate of the edge
	// (2) edge[1], the y-coordinate of edge 
	// (3) edge[2], representing the sum, x-edge + y-edge
	
	vec4 edge[3];
	
	edge[0] = sample[2] * 2.0 - sample[5] * 2.0;
	edge[1] = sample[7] * 2.0 - sample[8] * 2.0;

	edge[0] = edge[0] + sample[1] + sample[3] - sample[4] - sample[6];
	edge[1] = edge[1] + sample[1] - sample[3] + sample[4] - sample[6];

	edge[0] *= edge[0];
	edge[1] *= edge[1];

	edge[2] = edge[0] + edge[1];

	edge[2].x = max(edge[2].x, edge[2].y);
	edge[2].x = max(edge[2].x, edge[2].z);

	// write result from the edge detection into a gradient 2-vector
	
	float f = pow( edge[2].x, 0.5 );
	
	vec2 gradient = vec2( f );
	
	// calculate the (r,g,b) sum

	f = sample[0].r + sample[0].g + sample[0].b;

	// initialize the hue 3-vector
		
	vec3 hue;
	
	if ( style )
	{
		// normalize the color hue

		hue = vec3( f, 1.0 / f, 0.0 );

		// multiply pixel color with the inverse (r,g,b) sum
		
		sample[0] *= hue.g;
	}
	else
	{
		hue = vec3( f );
	}
	
	// calculate the pixel intensity

	// define darktones to be (r,g,b) sum greater than 0.2
	// and store the value in the blue-channel
	
	if(hue.r >= 0.2)
	{
		hue.b = 1.0;
	}
	else
	{
		hue.b = 0.0;
	}

	// normalize darktones
	
	hue.b *= 0.5;

	// define midtones to be (r,g,b) sum greater than 0.8
	// and store the value in the green-channel
	
	if(hue.r >= 0.8)
	{
		hue.g = 1.0;
	}
	else
	{
		hue.g = 0.0;
	}

	// normalize midtones
	//
	// define brighttones to be the (r,g,b) sum greater than 1.5
	// and store the value in the red-channel
	
	if(hue.r >= 1.5)
	{
		hue.r = 1.0;
	}
	else
	{
		hue.r = 0.0;
	}

	// normalize brighttones
	
	hue.r *= 2.5;

	// sum darktones + midtones + brighttones to calculate 
	// the final pixel intensity
	
	hue.r += hue.g + hue.b;
	
	// multiply pixel color with the toon intensity
	
	sample[0] *= hue.r;

	// generate the edge mask

	// set to 1 all regions not belonging to an edge
	//
	// use 0.8 as threshold for edge detection
	
	if(gradient.x < 0.8)
	{
		gradient.x = 1.0;
	}
	else
	{
		gradient.x = 0.0;
	}

	// blend white into edge artifacts in bright areas
	//
	// find pixels with intensity greater than 2.5
	
	if(hue.r >= 2.5)
	{
		gradient.y = 1.0;
	}
	else
	{
		gradient.y = 0.0;
	}

	// set the edge mask to 1 in these areas
	
	f = max(gradient.x, gradient.y);
	
	// multiply cleaned up edge mask with final color image
	
	sample[0] *= f;

	// now compute the saturated color values
	
	const vec3 lumCoeff = vec3( 0.2125, 0.7154, 0.0721 ); 
	
	vec3 intensity = vec3( dot( sample[0].rgb, lumCoeff ) );
	vec3 scolor    = mix( intensity, sample[0].rgb, alpha );

	// transfer image to output
	
	gl_FragColor = vec4( scolor, 1.0 );
}