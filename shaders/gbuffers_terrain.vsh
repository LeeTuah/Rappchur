#version 330 compatibility

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;

out vec3 normal;

uniform mat4 gbufferModelViewInverse;

void main() {
	gl_Position = ftransform();
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	
	glcolor = gl_Color;
	// glcolor = vec4(1.0, 0.41, 0.71, 1.0);

	lmcoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmcoord = lmcoord / ((30.0 / 32.0) - (1.0 / 32.0)); // between the range of [0.03, 0.97]

	normal = gl_NormalMatrix * gl_Normal;
	normal = mat3(gbufferModelViewInverse) * normal;
}