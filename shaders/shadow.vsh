#version 330 compatibility

#ifndef MC_VERSION
#extension GL_GOOGLE_include_directive : require
#endif
#include "/lib/distort.glsl"

out vec2 texcoord;
out vec4 glcolor;

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
	gl_Position = ftransform();
	gl_Position.xyz = distort_shadow_clip_pos(gl_Position.xyz);
	
}