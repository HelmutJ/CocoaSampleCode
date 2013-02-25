// heatsig.fs
//
// map grayscale to heat signature
//

uniform sampler2DRect  tex;

void main(void)
{
	vec4 color = texture2DRect(tex, gl_TexCoord[0].st);
	
	// Convert to grayscale using NTSC conversion weights
	
    float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));

	// compute the heat signature value
	
	vec4 heatSig = vec4( 0.0, 0.0, 0.0, 0.0 );
	
	if ( gray < 0.25 )
	{
		// black to blue
		gray *= 4.0;

		heatSig.r = 0.0;
		heatSig.g = 0.0;
		heatSig.b = gray;
	}
	else if ( gray < 0.5 )
	{
		// blue to green
		gray -= 0.25;
		gray *= 4.0;

		heatSig.r = 0.0;
		heatSig.g = gray;
		heatSig.b = 1.0 - gray;
	}
	else if ( gray < 0.75 )
	{
		// green to yellow
		gray -= 0.5;
		gray *= 4.0;

		heatSig.r = gray;
		heatSig.g = 1.0;
		heatSig.b = 0.0;
	}
	else
	{
		// yellow to red
		gray -= 0.75;
		gray *= 4.0;

		heatSig.r = 1.0;
		heatSig.g = 1.0 - gray;
		heatSig.b = 0.0;
	}
	
	heatSig.a = 1.0;
	
	gl_FragColor = heatSig;
}
