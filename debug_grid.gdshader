shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled;

uniform sampler2D grid_texture : source_color, filter_nearest;
uniform vec2 grid_size;

void fragment() {
	vec4 color = texture(grid_texture, UV);
	
	// Create "Gaps" between cells to look like a grid
	// fract(UV * grid_size) gives us 0..1 coordinates inside EACH cell
	vec2 cell_uv = fract(UV * grid_size);
	
	// Gap/Border size (e.g., 5% of the cell size on each side)
	float gap = 0.05;
	
	// If we are in the gap area, discard the pixel
	if (cell_uv.x < gap || cell_uv.x > (1.0 - gap) || cell_uv.y < gap || cell_uv.y > (1.0 - gap)) {
		discard;
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
}
