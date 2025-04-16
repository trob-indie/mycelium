shader_type canvas_item;

uniform float time_speed = 0.4;
uniform float noise_scale = 10.0; // was 6.0
uniform float tangle_freq = 20.0; // was 10.0
uniform float tangle_speed = 1.5;
uniform float dark_vein_strength = 0.5;
uniform vec4 base_color : source_color = vec4(0.8, 0.85, 0.8, 1.0);
uniform vec4 vein_color = vec4(0.1, 0.0, 0.1, 1.0);
uniform vec4 pulse_color = vec4(0.6, 0.0, 0.2, 1.0);

void fragment() {
	vec2 uv = UV * noise_scale;
	float time = TIME * time_speed;

	// Tangled sine pattern (like roots)
	float tangle = sin(uv.x * tangle_freq + time * tangle_speed)
	             + sin(uv.y * tangle_freq * 1.2 - time * tangle_speed * 0.7);

	// Organic pulsation
	float pulse = sin(uv.x * 2.0 + time * 2.0) * sin(uv.y * 2.0 - time * 2.5);
	pulse = pulse * 0.5 + 0.5; // normalize

	// Vein shadows (dark tendrils)
	float veins = step(0.4, abs(sin(uv.x * 3.0 + uv.y * 2.0 + time))) * dark_vein_strength;

	vec4 color = base_color;
	color -= vein_color * veins;        // darken with veins
	pulse = pow(pulse * 0.5 + 0.5, 3.0); // makes it spike
	color.a = texture(TEXTURE, UV).a;   // preserve sprite alpha
	// Contrast boost
	color.rgb = pow(color.rgb, vec3(0.8)); // lower gamma = punchier
	
	float chaos = sin((uv.x * 13.0 + time * 3.0) * sin(uv.y * 11.0 + time)) * 0.5 + 0.5;
	color += chaos * 0.05; // subtle noise flicker

	COLOR = color;
}