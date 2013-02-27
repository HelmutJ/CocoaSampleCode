//
// Copyright (c) 2002-2006 3Dlabs Inc. Ltd.
//
// See 3Dlabs-License.txt for license information
//

uniform vec3 ambient[4];
uniform vec3 diffuse[4];
uniform vec3 specular[4];
uniform vec3 hhat[4];
uniform vec3 vp[4];
uniform vec3 sceneAmbient;

void main(void)
{
	vec3 mEm = vec3(gl_FrontMaterial.emission);
	vec3 mAmb = vec3(gl_FrontMaterial.ambient);
	vec3 mDif = vec3(gl_FrontMaterial.diffuse);
	vec3 mSpec = vec3(gl_FrontMaterial.specular);
	float mShine = gl_FrontMaterial.shininess;

	vec3 color = mEm + sceneAmbient * mAmb;
	vec3 normal = gl_Normal;

	for (int i = 0; i < 4; ++i) {
		color += ambient[i] * mAmb;

		float df = max(0.0, dot(vp[i], normal));
		color += diffuse[i] * mDif * df;

		float sf = df <= 0.0 ? 0.0 : max(0.0, dot(hhat[i], normal));
		sf = pow(sf, mShine);
		color += specular[i] * mSpec * sf;
	}

	gl_FrontColor = vec4(color, 1.0);
	gl_Position = ftransform();
}