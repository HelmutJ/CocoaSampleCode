// fog.fs
//
// per-pixel fog

uniform sampler2DRect tex;
uniform float density;

void main(void)
{
    const vec4 fogColor = vec4(0.5, 0.8, 0.5, 1.0);

	vec4 texel = texture2DRect(tex, gl_TexCoord[0].st);

    // calculate 2nd order exponential fog factor
    // based on fragment's Z distance
	
    const float e = 2.71828;
	
    float fogFactor = (density * gl_FragCoord.z);
	
    fogFactor *= fogFactor;
    fogFactor  = clamp(pow(e, -fogFactor), 0.0, 1.0);

    // Blend fog color with incoming color
	
    gl_FragColor = mix(fogColor, texel, fogFactor);
}
