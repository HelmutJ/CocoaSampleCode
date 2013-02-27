uniform sampler1D palette;
uniform sampler2D pattern;
uniform float offset;
varying float LightIntensity; 

void main()
{
	vec4 color;
	color = texture2D(pattern, gl_TexCoord[0].st);
	color = texture1D(palette, (color.r+offset));
	color.a = 1.0;
	color = color * LightIntensity;
	color = clamp(color, 0.0, 1.0);
	gl_FragColor = color;
}
