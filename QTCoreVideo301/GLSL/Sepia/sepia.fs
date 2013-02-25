// sepia.frag
//
// convert RGB to sepia tone

uniform sampler2DRect tex;

void main(void)
{
	vec4 texel = texture2DRect(tex, gl_TexCoord[0].st);

    // Convert to grayscale using NTSC conversion weights
    float gray = dot(texel.rgb, vec3(0.299, 0.587, 0.114));

    // convert grayscale to sepia
    gl_FragColor = vec4(gray * vec3(1.2, 1.0, 0.8), 1.0);
}
