shader_type canvas_item;

uniform vec2 hole_position = vec2(500.0, 500.0);
uniform float hole_radius = 70.0;
uniform float edge_softness = 8.0;
uniform vec4 overlay_color : source_color = vec4(0.0, 0.0, 0.0, 0.65);

void fragment()
{
    float dist = distance(SCREEN_UV * VIEWPORT_SIZE, hole_position);

    float alpha = smoothstep(
        hole_radius,
        hole_radius + edge_softness,
        dist
    );

    COLOR = vec4(overlay_color.rgb, overlay_color.a * alpha);
}