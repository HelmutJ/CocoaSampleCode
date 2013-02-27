This sample demonstrates a few uses of render-to-texture via FBO:
* Cache rendering results (impostors)
* Dynamic cubic environment map
* Fullscreen shader effects

This sample runs through a series of modes, advancing with the space bar:
1: Render a traditional bunny model. Nothing complicated yet...
2: Render the model a second time into a texture via FBO, and show it on a quad.
3: Reveal that the quad is a cube-- we can use the texture however we like.
4: Remove the cube faces-- each additional bunny only costs us one quad.
5: Draw a cloud of cubes-- we can draw hundreds of impostor bunnies very cheaply.
6: Show cubemap faces-- each face is attached to an FBO in turn.
7: Apply the cubic envmap to the main bunny-- FBO makes this fast and easy.
8: Fullscreen effects-- render everything to another FBO, apply depth-of-field with GLSL.
9: Depth-of-field interaction-- press [ and ] to change the focal point.

The sample starts in mode 2, as described above.

FBO replaces previous render-to-texture methods such as offscreen windows and PBuffers.
It is cross-platform and does not require copying texture data or switching contexts.

Please read the FBO specification for full details:
http://www.opengl.org/registry/specs/EXT/framebuffer_object.txt
