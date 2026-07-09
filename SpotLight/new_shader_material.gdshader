shader_type canvas_item;

uniform vec2 hole1 = vec2(-1000.0, -1000.0);
uniform float radius1 = 70.0;
uniform vec2 hole2 = vec2(-1000.0, -1000.0);
uniform float radius2 = 70.0;
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 0.75);
uniform float softness = 10.0;

// FIX: FRAGCOORD is in physical/window pixels, which drift out of sync
// with global_position (logical pixels) whenever the project uses any
// stretch scale factor. SCREEN_UV is always 0-1, so multiplying it by
// viewport_size (set from script) keeps the hole locked to the tile.
uniform vec2 viewport_size = vec2(1080.0, 1920.0);

// Square (box) "distance" instead of circular distance.
// Uses Chebyshev distance: max(|dx|, |dy|) — this makes the mask boundary
// a square instead of a circle. "radius" now behaves as half the
// square's side length.
float box_dist(vec2 p, vec2 center) {
	vec2 d = abs(p - center);
	return max(d.x, d.y);
}

void fragment() {
	vec2 p = SCREEN_UV * viewport_size;

	float d1 = box_dist(p, hole1);
	float d2 = box_dist(p, hole2);

	float m1 = smoothstep(radius1 - softness, radius1 + softness, d1);
	float m2 = smoothstep(radius2 - softness, radius2 + softness, d2);

	float mask = min(m1, m2);

	COLOR = vec4(overlay_color.rgb, overlay_color.a * mask);
}
