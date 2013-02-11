uniform mat4 cameraMatrix;
uniform mat4 textureMatrix;

varying vec3 normal;

void main()
{
	normal = vec3(cameraMatrix * vec4(gl_Normal, 0.0));
	gl_Position = gl_ProjectionMatrix * cameraMatrix * gl_Vertex;
	gl_TexCoord[0] = textureMatrix * gl_MultiTexCoord0;
}