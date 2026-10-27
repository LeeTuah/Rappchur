#version 330 compatibility

// recieving from gbuffers_terrain shader
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform sampler2D depthtex0;
uniform sampler2D shadowtex0;

uniform mat4 gbufferModelViewInverse;
uniform vec3 shadowLightPosition; // returns the position of the sun/moon

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

/*
const int colortex0Format = RGB16;
*/

void main() {
	color = texture(colortex0, texcoord);
	
	float depth = texture(depthtex0, texcoord).x;
	if (depth == 1.0) return;

	vec2 lightmap = texture(colortex1, texcoord).xy;
	vec3 encoded_normal = texture(colortex2, texcoord).xyz;
	vec3 normal = normalize((encoded_normal - 0.5) * 2.0);

	// float gray_scale = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	// color.rgb = vec3(0.8 * gray_scale);

	const vec3 ambient_const = vec3(0.1);
	const vec3 skylight_const = vec3(0.05, 0.15, 0.30);
	const vec3 blocklight_const = vec3(1.0, 0.5, 0.08);
	const vec3 sun_moon_light_const = vec3(1.0);

	vec3 sunlight_vector = normalize(shadowLightPosition);
	sunlight_vector = mat3(gbufferModelViewInverse) * sunlight_vector;

	vec3 ambient_light = ambient_const;
	vec3 skylight = lightmap.y * skylight_const;
	vec3 blocklight = lightmap.x * blocklight_const;
	vec3 sun_moon_light = sun_moon_light_const * lightmap.y * clamp(dot(sunlight_vector, normal), 0.0, 1.0);

	color.rgb *= (ambient_light + skylight + blocklight + sun_moon_light);
	color.rgb = texture(shadowtex0, texcoord).rgb;
	color.rgb = pow(color.rgb, vec3(2.2)); // gamma correction
}