uniform vec3 lightPosition;
uniform float furHeight;
uniform float ambient;

varying float light;

void main(void)
{
	vec3 normal = gl_Normal;
	vec3 vertex = gl_Vertex.xyz + normal * furHeight;

	normal = normalize(gl_NormalMatrix * normal);
	vec3 position = vec3(gl_ModelViewMatrix * vec4(vertex,1.0));
	vec3 lightToVertex = normalize(lightPosition - position);
	float diffuse = dot(lightToVertex, normal);

	light = ambient + diffuse;
	gl_TexCoord[0] = gl_TextureMatrix[0] * gl_MultiTexCoord0;
	gl_Position = gl_ModelViewProjectionMatrix * vec4(vertex,1.0);
}
