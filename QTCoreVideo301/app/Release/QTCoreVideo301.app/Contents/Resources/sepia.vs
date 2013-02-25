// All the vertex shader does is copy the multi-texture coordinate over for the 
// fragment shader to use. The attribute array gl_MultiTexCoord0 is not available 
// in the fragment shader so we need to populate the gl_TexCoord[0] value with it. 
// Then the vertex position gets transformed according to the current model view 
// matrix.

void main()
{		
	gl_TexCoord[0] = gl_MultiTexCoord0;
	gl_Position = ftransform();
} 
