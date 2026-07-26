shader_type canvas_item;

// CampusLifeSim "Neo Glass" surface.
// The rounded mask is resolution-independent and the screen is sampled through
// mipmaps, so one inexpensive blur lookup can be shared by large UI surfaces.

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform vec4 glass_tint : source_color = vec4(0.035, 0.085, 0.095, 0.78);
uniform vec4 edge_tint : source_color = vec4(0.39, 0.87, 0.72, 0.35);
uniform float blur_lod : hint_range(0.0, 5.0, 0.1) = 2.8;
uniform float saturation : hint_range(0.0, 1.4, 0.01) = 0.82;
uniform float brightness : hint_range(-0.2, 0.2, 0.005) = 0.015;
uniform float grain_strength : hint_range(0.0, 0.08, 0.001) = 0.012;
uniform float edge_strength : hint_range(0.0, 1.0, 0.01) = 0.32;
uniform float corner_radius_px : hint_range(0.0, 48.0, 1.0) = 18.0;
uniform float edge_softness_px : hint_range(0.5, 4.0, 0.1) = 1.2;


float rounded_box(vec2 point, vec2 half_size, float radius) {
	vec2 distance = abs(point) - half_size + radius;
	return min(max(distance.x, distance.y), 0.0) + length(max(distance, vec2(0.0))) - radius;
}


float noise(vec2 coordinate) {
	return fract(sin(dot(coordinate, vec2(12.9898, 78.233))) * 43758.5453);
}


void fragment() {
	float derivative_x = max(abs(dFdx(UV.x)), 0.0001);
	float derivative_y = max(abs(dFdy(UV.y)), 0.0001);
	vec2 pixel_size = clamp(vec2(1.0 / derivative_x, 1.0 / derivative_y), vec2(1.0), vec2(4096.0));
	vec2 half_size = pixel_size * 0.5;
	vec2 point = UV * pixel_size - half_size;
	float radius = min(corner_radius_px, min(half_size.x, half_size.y));
	float signed_distance = rounded_box(point, half_size, radius);
	float mask = 1.0 - smoothstep(-edge_softness_px, edge_softness_px, signed_distance);
	if (mask < 0.001) {
		discard;
	}

	vec3 backdrop = textureLod(screen_texture, SCREEN_UV, blur_lod).rgb;
	float luminance = dot(backdrop, vec3(0.2126, 0.7152, 0.0722));
	backdrop = mix(vec3(luminance), backdrop, saturation);
	vec3 glass = mix(backdrop, glass_tint.rgb, glass_tint.a);

	float edge_distance = max(-signed_distance, 0.0);
	float edge = 1.0 - smoothstep(0.0, 2.2, edge_distance);
	float top_light = pow(clamp(1.0 - UV.y, 0.0, 1.0), 4.0) * 0.055;
	float directional_edge = edge * mix(0.38, 1.0, clamp((1.0 - UV.y) * 0.72 + UV.x * 0.28, 0.0, 1.0));
	glass = mix(glass, edge_tint.rgb, directional_edge * edge_tint.a * edge_strength);
	glass += vec3(top_light);

	float grain = (noise(FRAGCOORD.xy) - 0.5) * grain_strength;
	glass += vec3(grain + brightness);
	COLOR = vec4(glass, mask);
}
