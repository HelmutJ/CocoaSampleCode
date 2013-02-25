// grayinvert.fs
//
// invert like a B&W negative

uniform sampler2DRect tex;

void main(void)
{
	vec4 texel = texture2DRect(tex, gl_TexCoord[0].st);

    // Convert to grayscale
    float gray = dot(texel.rgb, vec3(0.299, 0.587, 0.114));

    // invert
    gray = 1.0 - gray;

    // replicate grayscale to RGB components
    gl_FragColor = vec4(gray, gray, gray, 1.0);
}
