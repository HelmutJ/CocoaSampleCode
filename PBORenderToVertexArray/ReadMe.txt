This sample demonstrates render-to-vertex-array using FBO, PBO, and VBO.

A VBO is allocated with storage and indices for an N x N mesh.
Then content is drawn into an N x N texture attached to an FBO.
The pixel data is copied from the FBO into the VBO, by binding a PBO to the VBO id and calling glReadPixels.
Now the pixel RGBA colors can be used as vertex XYZW data.

Several simple examples of content are included to show how pixel data can be used as vertex data:
* Sum of sines: [ and ] control sine height, { and } control sine frequency. Drag centers with the mouse.
* Coincentric rings: toggle with 'r'. The depth coordinate of 3D geometry can be extruded in the mesh.
* OpenGL logo: ; and ' control height. The texture is extruded in the mesh.
* Twirl: , and . twirl the red and green channels, and the mesh X and Y geometry.
Any 2D image processing technique can be applied to the texture, and the vertices will move accordingly.

This sample uses several OpenGL extensions in conjunction. Please read the specifications for full details:
http://www.opengl.org/registry/specs/EXT/framebuffer_object.txt
http://www.opengl.org/registry/specs/ARB/pixel_buffer_object.txt
http://www.opengl.org/registry/specs/ARB/vertex_buffer_object.txt

Additionally, if APPLE_float_pixels is available, the texture attached to the FBO uses float data.
Renderers that support FBO, PBO, and VBO but do not support APPLE_float_pixels can still run this
sample, but the texture will only have 8-bit integer precision, leading to some visual artifacts.
