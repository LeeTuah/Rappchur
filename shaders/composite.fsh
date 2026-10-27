#version 330 compatibility

#ifndef MC_VERSION
#extension GL_GOOGLE_include_directive : require
#endif
#include "/lib/distort.glsl"

// recieving from gbuffers_terrain shader
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;

uniform sampler2D depthtex0;
uniform sampler2D noisetex;

uniform sampler2D shadowtex0;
uniform sampler2D shadowtex1;
uniform sampler2D shadowcolor0;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

uniform vec3 shadowLightPosition; // returns the position of the sun/moon

uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

/*
const int colortex0Format = RGB16;
*/

// constants

# define SHADOW_RADIUS 1
# define SHADOW_RANGE 4

const vec3 ambient_const = vec3(0.1);
const vec3 skylight_const = vec3(0.05, 0.15, 0.30);
const vec3 blocklight_const = vec3(1.0, 0.5, 0.08);
const vec3 sun_light_const = vec3(1.0);
const vec3 moon_light_const = vec3(0.003);

vec3 project_and_divide(mat4 projection_matrix, vec3 position) {
	vec4 value = projection_matrix * vec4(position, 1.0);
	return value.xyz / value.w;
}

vec4 get_noise(vec2 coord) {
	ivec2 screen_coord = ivec2(coord * vec2(viewWidth, viewHeight));
	ivec2 noise_coord = screen_coord % 64;

	return texelFetch(noisetex, noise_coord, 0);
}

vec3 get_shadow(vec3 shadow_screen_pos) {
	float transparent_shadow = step(shadow_screen_pos.z, texture(shadowtex0, shadow_screen_pos.xy).x);
	if (transparent_shadow == 1.0) return vec3(1.0);

	float opaque_shadow = step(shadow_screen_pos.z, texture(shadowtex1, shadow_screen_pos.xy).x);
	if (opaque_shadow == 0.0) return vec3(0.0);

	vec4 shadow_color = texture(shadowcolor0, shadow_screen_pos.xy);
	return shadow_color.rgb * (1.0 - shadow_color.a);
}

vec3 get_soft_shadow(vec4 shadow_clip_pos) {
	vec3 shadow_total = vec3(0.0);
	const int samples = 4 * SHADOW_RANGE * SHADOW_RANGE; // (2 * SHADOW_RANGE)^2
	float noise = get_noise(texcoord).r;

	float angle = noise * radians(360.00);
	float cos_theta = cos(angle);
	float sin_theta = sin(angle);
	mat2 random_rotation = mat2(cos_theta, -sin_theta, sin_theta, cos_theta);

	for (int x = -SHADOW_RANGE; x < SHADOW_RANGE; x++) {
		for (int y = -SHADOW_RANGE; y < SHADOW_RANGE; y++) {
			vec2 offset = vec2(x, y) * SHADOW_RADIUS / float(SHADOW_RANGE);
			offset *= random_rotation; // rotated to remove the perfect grid pattern introduced
			offset /= shadowMapResolution;

			vec4 offset_shadow_clip_pos = shadow_clip_pos + vec4(offset, 0.0, 0.0);
			offset_shadow_clip_pos.z -= 0.001;
			offset_shadow_clip_pos.xyz = distort_shadow_clip_pos(offset_shadow_clip_pos.xyz);
			vec3 offset_shadow_ndc_pos = offset_shadow_clip_pos.xyz / offset_shadow_clip_pos.w;
			vec3 offset_shadow_screen_pos = offset_shadow_ndc_pos * 0.5 + 0.5;

			shadow_total += get_shadow(offset_shadow_screen_pos);
		}
	}

	return shadow_total / float(samples);
}

void main() {
	color = texture(colortex0, texcoord);
	
	float depth = texture(depthtex0, texcoord).x;
	if (depth == 1.0) return;

	vec2 lightmap = texture(colortex1, texcoord).xy;
	vec3 encoded_normal = texture(colortex2, texcoord).xyz;
	vec3 normal = normalize((encoded_normal - 0.5) * 2.0);

	// float gray_scale = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	// color.rgb = vec3(0.8 * gray_scale);

	vec3 ndc_pos = vec3(texcoord.xy, depth) * 2.0 - 1.0;
	vec3 view_pos = project_and_divide(gbufferProjectionInverse, ndc_pos);
	vec3 feet_player_pos = (gbufferModelViewInverse * vec4(view_pos, 1.0)).xyz;

	vec3 shadow_view_pos = (shadowModelView * vec4(feet_player_pos, 1.0)).xyz;
	vec4 shadow_clip_pos = shadowProjection * vec4(shadow_view_pos, 1.0);
	
	// moved to get_soft_shadow(), so not needed
	// shadow_clip_pos.z -= 0.001; // to prevent shadow acne
	// shadow_clip_pos.xyz = distort_shadow_clip_pos(shadow_clip_pos.xyz);
	// vec3 shadow_ndc_pos = shadow_clip_pos.xyz / shadow_clip_pos.w;
	// vec3 shadow_screen_pos = shadow_ndc_pos * 0.5 + 0.5;

	// checks whether the depth of the current texture (from the sun) is less than or equal to 
	// the shadow map texture provided by iris
	// if equal, shadow = 1 (same depth), else depth of current texture < shadowmap, shadow = 0
	vec3 shadow = get_soft_shadow(shadow_clip_pos);

	vec3 sunlight_vector = normalize(shadowLightPosition);
	sunlight_vector = mat3(gbufferModelViewInverse) * sunlight_vector;

	vec3 ambient_light = ambient_const;
	vec3 skylight = lightmap.y * skylight_const;
	vec3 blocklight = lightmap.x * blocklight_const;
	vec3 sun_moon_light = sun_light_const * shadow * clamp(dot(sunlight_vector, normal), 0.0, 1.0);

	color.rgb *= (ambient_light + skylight + blocklight + sun_moon_light);
	// color.rgb = texture(noisetex, texcoord).rgb;
	color.rgb = pow(color.rgb, vec3(2.2)); // gamma correction
}