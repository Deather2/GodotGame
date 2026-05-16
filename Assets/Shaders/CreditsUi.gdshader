shader_type canvas_item;

uniform vec4 bg_color : source_color = vec4(0.01, 0.008, 0.018, 1.0);
uniform vec4 star_color : source_color = vec4(0.45, 0.65, 1.0, 1.0);

uniform float cell_size = 32.0;
uniform float star_size = 3.0;
uniform float density = 0.18;
uniform float scroll_offset = 0.0;
uniform float brightness = 0.35;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

vec2 hash2(vec2 p) {
	return vec2(
		hash(p),
		hash(p + 19.19)
	);
}

void fragment() {
	vec2 p = FRAGCOORD.xy;

	p.y += scroll_offset;

	vec2 cell = floor(p / cell_size);
	vec2 local = fract(p / cell_size);

	float exists = step(1.0 - density, hash(cell));
	vec2 star_pos = hash2(cell);

	vec2 d = abs(local - star_pos);
	float size_in_cell = star_size / cell_size;

	float star = step(d.x, size_in_cell) * step(d.y, size_in_cell) * exists;

	vec3 col = bg_color.rgb;
	col += star_color.rgb * star * brightness;

	COLOR = vec4(col, 1.0);
}