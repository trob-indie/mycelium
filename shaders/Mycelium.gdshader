shader_type canvas_item;

uniform float time_speed = 0.5;
uniform float web_density = 14.0;
uniform float pulse_speed = 2.0;
uniform float glow_strength = 0.3;
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
	tangle = abs(tangle);

	// Pulsing effect
	float pulse = sin(uv.x + t * pulse_speed) * sin(uv.y - t * pulse_speed * 1.2);
	pulse = pulse * 0.5 + 0.5;

	// Radial fade from edge to center
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	float edge_fade = smoothstep(0.05, 0.5, dist); // edge = 1, center = 0

	// Web glow intensity
	float web_intensity = tangle * pulse * glow_strength * edge_fade;

	// Sample base texture
	vec4 tex_color = texture(TEXTURE, UV);

	// Compose mycelium overlay
	vec4 web_overlay = web_color * web_intensity + pulse_color * web_intensity * 0.5;

	// Combine base texture + overlay (overlay fades near center)
	vec4 final_color = tex_color + web_overlay;
	final_color.a = tex_color.a;

	// Hover / select highlights
	if (is_selected) {
		final_color.rgb = mix(final_color.rgb, vec3(0.4, 1.0, 0.4), 0.6); // green
	} else if (is_hovered) {
		final_color.rgb = mix(final_color.rgb, vec3(1.0, 0.85, 0.5), 0.5); // yellow-orange
	}

	// Flash red if invalid
	if (flash_invalid) {
		final_color.rgb = mix(final_color.rgb, vec3(1.0, 0.2, 0.2), 0.7); // red flash
	}

	COLOR = final_color;
}