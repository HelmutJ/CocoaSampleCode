#extension GL_EXT_texture_array : require
uniform sampler2DArray sampler;

varying vec3 normal;

void main (void) 
{
	vec3 b0 = normalize(normal);
	vec3 coord = gl_TexCoord[0].xyz;
	coord.z = floor(coord.z);
	vec4 a = texture2DArray(sampler, coord);
	coord.z += 1.0;
	vec4 b = texture2DArray(sampler, coord);
	gl_FragColor = mix(a, b, fract(gl_TexCoord[0].z));
}