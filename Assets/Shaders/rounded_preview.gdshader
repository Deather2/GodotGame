shader_type canvas_item;

uniform vec2 rect_size = vec2(100.0, 60.0);
uniform float radius_px = 14.0;
uniform float edge_softness = 1.0;

void fragment() {
	vec4 base = texture(TEXTURE, UV) * COLOR;

	vec2 half_size = rect_size * 0.5;
	vec2 p = UV * rect_size - half_size;
	vec2 q = abs(p) - (half_size - vec2(radius_px));

	float dist = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - radius_px;
	float mask = 1.0 - smoothstep(0.0, edge_softness, dist);

	COLOR = vec4(base.rgb, base.a * mask);
}
