uniform sampler2D noiseTexture;
uniform sampler2D colorTexture;
uniform float spacing;
uniform float transparency;

varying float light;

void main (void)
{
	float furValue = texture2D(noiseTexture, gl_TexCoord[0].xy*vec2(spacing,spacing)).x;
	gl_FragColor = vec4(vec3(light) * texture2D(colorTexture, gl_TexCoord[0].xy).rgb, transparency * furValue);
}
