shader_type canvas_item;

uniform float time_speed = 0.5;
uniform float web_density = 14.0;
uniform float pulse_speed = 2.0;
uniform float glow_strength = 0.3;
uniform vec4 base_color : source_color = vec4(0.9, 1.0, 0.9, 1.0);
uniform vec4 web_color = vec4(0.6, 1.0, 0.6, 1.0);
uniform vec4 pulse_color = vec4(0.8, 0.2, 0.5, 1.0);

uniform bool is_hovered = false;
uniform bool is_selected = false;

uniform bool flash_invalid = false;

void fragment() {
	vec2 uv = UV * web_density;
	float t = TIME * time_speed;

	// Tangled wave pattern
	float tangle = sin(uv.x + sin(uv.y + t)) * cos(uv.y + t * 0.5);
	tangle *= sin(uv.y * 1.5 + t * 0.7);

	// Normalize the tangle
	tangle = abs(tangle);

	// Pulsing effect based on time and position
	float pulse = sin(uv.x + t * pulse_speed) * sin(uv.y - t * pulse_speed * 1.2);
	pulse = pulse * 0.5 + 0.5;

	// Combine glow, tangle, and pulse
	float web_intensity = tangle * pulse * glow_strength;

	vec4 final_color = base_color + web_color * web_intensity + pulse_color * web_intensity * 0.5;
	final_color.a = texture(TEXTURE, UV).a;

	COLOR = final_color;
	
	if (is_selected) {
		COLOR.rgb = mix(COLOR.rgb, vec3(0.4, 1.0, 0.4), 0.6); // green highlight
	} else if (is_hovered) {
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.85, 0.5), 0.5); // yellow-orange hover
	}
	if (flash_invalid) {
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.2, 0.2), 0.7); // flash red
	}
}