shader_type canvas_item;

uniform bool disabled_overlay = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	// Convert to grayscale (stronger desaturation)
	float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = vec3(gray);

	// Apply translucency when disabled
	float alpha = tex_color.a;
	if (disabled_overlay) {
		alpha *= 0.6; // make it slightly translucent
	}

	// Blend grayscale and original color
	vec3 final_color = mix(tex_color.rgb, desaturated, disabled_overlay ? 1.0 : 0.0);

	COLOR = vec4(final_color, alpha);
}