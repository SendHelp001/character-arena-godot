shader_type spatial;
render_mode specular_toon; // Toon lighting for stylized look

uniform vec3 albedo : source_color = vec3(0.0, 0.3, 0.5);
uniform vec3 albedo_deep : source_color = vec3(0.0, 0.1, 0.4);
uniform float beer_factor = 0.2; // How fast light falls off
uniform float roughness : hint_range(0.0, 1.0) = 0.1;

uniform sampler2D wave_noise;
uniform float wave_speed = 0.05;
uniform float wave_scale = 0.2;
uniform float wave_height = 0.1;

// Foam
uniform vec3 foam_color : source_color = vec3(1.0);
uniform float foam_amount : hint_range(0.0, 2.0) = 0.5;

// Godot Depth Texture
uniform sampler2D depth_texture : hint_depth_texture, filter_linear_mipmap;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void vertex() {
	// Simple vertex waves
	vec2 tex_pos = VERTEX.xz * wave_scale + TIME * wave_speed;
	float height = texture(wave_noise, tex_pos).r;
	VERTEX.y += height * wave_height;
}

void fragment() {
	// 1. Robust Depth Calculation for Godot 4
	float depth_tex = texture(depth_texture, SCREEN_UV).r;
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_tex);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_scene_depth = -view.z;
	float linear_surface_depth = FRAGCOORD.z / FRAGCOORD.w; // or just -VERTEX.z in view space if logical
	
	// Actual distance from water surface to ground
	float depth_diff = linear_scene_depth - linear_surface_depth;
	
	// 2. Color Mixing (Beer's Law)
	// depth_diff is in World Units (Meters)
	float depth_blend = exp(-depth_diff * beer_factor);
	depth_blend = clamp(depth_blend, 0.0, 1.0);
	
	vec3 final_color = mix(albedo_deep, albedo, depth_blend);
	
	// 3. Foam
	// If depth_diff is small, we are near shore
	if (depth_diff < foam_amount) {
		// smoothstep(edge0, edge1, x)
		// We want 1.0 at depth 0, 0.0 at depth foam_amount
		float foam_val = 1.0 - smoothstep(0.0, foam_amount, depth_diff);
		
		final_color = mix(final_color, foam_color, foam_val);
	}
	
	ALBEDO = final_color;
	ROUGHNESS = roughness;
	ALPHA = 0.9;
}
