#extension GL_EXT_texture_array : require
uniform sampler2DArray sampler;
uniform float slice;

void main()
{
	vec3 coord = gl_TexCoord[0].xyz;
	coord.z = slice;
	gl_FragColor = texture2DArray(sampler, coord);
}