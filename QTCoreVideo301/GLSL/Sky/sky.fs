uniform sampler2DRect tex;

uniform float blueFactor;

void main()
{
	vec4 fragColor = texture2DRect(tex, gl_TexCoord[0].st);
	vec4 color     = vec4(gl_FrontMaterial.diffuse.rgb * fragColor.rgb, 1);
		
	gl_FragColor = color * blueFactor;	
}
