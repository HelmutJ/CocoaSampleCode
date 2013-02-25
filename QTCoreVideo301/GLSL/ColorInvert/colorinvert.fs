// colorinvert.fs
//
// invert like a color negative

uniform sampler2DRect tex;

void main(void)
{
	vec4 fragColor = texture2DRect(tex, gl_TexCoord[0].st);
	
    // invert color components
	
    gl_FragColor.rgb = 1.0 - fragColor.rgb;
    gl_FragColor.a   = 1.0;
}
