varying float LightIntensity;
uniform vec3  LightPosition;

void main()
{
    vec4 ECposition = gl_ModelViewMatrix * gl_Vertex;
    vec3 tnorm      = normalize(vec3 (gl_NormalMatrix * gl_Normal));
    LightIntensity  = dot(normalize(LightPosition - vec3 (ECposition)), tnorm) * 1.5;
    gl_Position = ftransform();
    gl_TexCoord[0]  = gl_MultiTexCoord0;
}
