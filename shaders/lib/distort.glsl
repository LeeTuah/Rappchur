const int shadowMapResolution = 2048; // [256 512 1024 2048 4096 8192]
const float shadowDistanceRenderMul = 1.0;

const bool shadowtex0Nearest = true;
const bool shadowtex1Nearest = true;
const bool shadowcolor0Nearest = true;

vec3 distort_shadow_clip_pos(vec3 shadow_clip_pos) {
	float distortion_factor = length(shadow_clip_pos.xy);
	distortion_factor += 0.1;

	shadow_clip_pos.xy /= distortion_factor;
	shadow_clip_pos.z *= 0.5;
	
	return shadow_clip_pos;
}