shader_type canvas_item;

uniform float sway_strength = 2.6;
uniform float breath_strength = 0.055;
uniform float glow_strength = 0.18;

void vertex() {
	float phase = TIME * 5.4 + COLOR.r * 3.7 + COLOR.g * 5.1;
	float vertical_weight = smoothstep(0.05, 0.95, UV.y);
	VERTEX.x += sin(phase + UV.y * 5.8) * sway_strength * vertical_weight;
	VERTEX.y *= 1.0 + sin(phase * 0.72) * breath_strength;
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	float rim = smoothstep(0.58, 0.02, distance(UV, vec2(0.5, 0.55)));
	COLOR = vec4(tex.rgb + rim * glow_strength * tex.a, tex.a) * COLOR;
}
