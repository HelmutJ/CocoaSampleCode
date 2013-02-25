uniform sampler2DRect tex;

void main()
{
	vec4 texel = texture2DRect(tex, gl_TexCoord[0].st);

    // Convert to grayscale using NTSC conversion weights
    float gray = dot(texel.rgb, vec3(0.299, 0.587, 0.114));

    // replicate grayscale to RGB components
    gl_FragColor = vec4(gray, gray, gray, 1.0);
}