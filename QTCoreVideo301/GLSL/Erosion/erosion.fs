// erosion.fs
//
// minimum of 3x3 kernel

uniform sampler2DRect tex;

uniform float offset;

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

	vec4 minValue = vec4( 1.0 );
	
	for ( i = 0; i < 9; i++ )
	{
		minValue  = min( sample[i], minValue );
	}

	gl_FragColor = minValue;
}
