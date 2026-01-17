extends Node

# -----------------------------------------------------------
# GLOBAL GRID NAVIGATION (AStarGrid2D)
# -----------------------------------------------------------
# High-performance C++ implementation for Godot 4+
# - Maps 3D World (X, Z) -> 2D Grid (X, Y)
# - Handles 8-way movement and diagonals automatically
# -----------------------------------------------------------

var astar: AStarGrid2D
var map_rect: Rect2i
var cell_size: float = 1.0
var grid_origin: Vector3 # Top-Left of the grid in world space

# Debug
var active_region: Node3D = null
var debug_mesh_instance: MeshInstance3D

func _ready():
	astar = AStarGrid2D.new()
	# STRICT CORNERING: Prevents cutting corners if adjacent cells are blocked
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.jumping_enabled = true # Fast pathfinding
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	
	_setup_debug_draw()
	print("[GridManager] Autoload ready. Waiting for GridRegion...")

func _process(_delta):
	if debug_enabled:
		_update_debug_grid()

func register_region(region_node: Node3D):
	print("[GridManager] Region registered: ", region_node.name)
	active_region = region_node
	cell_size = region_node.cell_size
	
	# Calculate Grid Dimensions
	var width = int(region_node.map_size.x / cell_size)
	var height = int(region_node.map_size.z / cell_size)
	map_rect = Rect2i(0, 0, width, height)
	
	# Calculate Origin (Top-Left corner world pos)
	# Assuming region position is Center
	var corner_x = region_node.global_position.x - (region_node.map_size.x / 2.0)
	var corner_z = region_node.global_position.z - (region_node.map_size.z / 2.0)
	grid_origin = Vector3(corner_x, 0, corner_z)
	
	# Configure AStar
	astar.region = map_rect
	astar.cell_size = Vector2(cell_size, cell_size)
	astar.update() # Build internal graph
	
	call_deferred("_scan_grid")

func _scan_grid():
	if not active_region: return
	var start_time = Time.get_ticks_msec()
	
	# Raycast Param setup
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var ray_y_high = active_region.global_position.y + 10.0
	var ray_y_low = active_region.global_position.y - 10.0
	
	# Prepare Shape for Scanning (Represents the Unit/Cell Volume)
	# This adds a "Buffer" so we don't path too close to walls
	var scan_shape = SphereShape3D.new()
	scan_shape.radius = cell_size * 0.45 # Slightly less than half-cell to avoid false positives
	
	# Iterate Grid
	for x in range(map_rect.size.x):
		for y in range(map_rect.size.y):
			# Grid (x, y) -> World (x, z)
			var world_pos = _grid_to_world(Vector2i(x, y))
			var scan_pos = Vector3(world_pos.x, active_region.global_position.y + 0.5, world_pos.z)
			
			var is_walkable = true
			
			# 1. OBSTACLE CHECK (Shape Cast)
			# Replaces thin raycast with a volume check
			var query = PhysicsShapeQueryParameters3D.new()
			query.shape = scan_shape
			query.transform = Transform3D(Basis(), scan_pos)
			query.collision_mask = 8 # Layer 4 (Walls)
			
			var hits = space_state.intersect_shape(query, 1) # Max 1 hit enough
			if hits.size() > 0:
				is_walkable = false
			else:
				# 2. TERRAIN CHECK (Raycast down)
				# Only check if no obstacle
				var from = Vector3(world_pos.x, ray_y_high, world_pos.z)
				var to = Vector3(world_pos.x, ray_y_low, world_pos.z)
				var t_query = PhysicsRayQueryParameters3D.create(from, to)
				t_query.collision_mask = 1 # Terrain
				
				var result = space_state.intersect_ray(t_query)
				if result:
					if result.normal.dot(Vector3.UP) > 0.7:
						is_walkable = true
					else:
						is_walkable = false # Too steep
				else:
					is_walkable = false # Void/Hole
			
			# AStarGrid2D Logic: "Solid" means BLOCKED
			astar.set_point_solid(Vector2i(x, y), not is_walkable)

	print("[GridManager] Grid Scan (AStarGrid2D) complete in %dms." % (Time.get_ticks_msec() - start_time))

# -----------------------------------------------------------
# Public API
# -----------------------------------------------------------
# -----------------------------------------------------------
# Public API
# -----------------------------------------------------------
func get_path_points(from_world: Vector3, to_world: Vector3) -> PackedVector3Array:
	if not active_region:
		push_error("[GridManager] Cannot get path: No GridRegion registered! Add a GridRegion node to your scene.")
		return PackedVector3Array()
	
	var from_id = _world_to_grid(from_world)
	var to_id = _world_to_grid(to_world)
	
	# Clamp to grid bounds
	from_id = _clamp_to_grid(from_id)
	to_id = _clamp_to_grid(to_id)
	
	# SMART PATHING: If target is blocked, find closest walkable cell
	if astar.is_point_solid(to_id):
		to_id = _find_closest_walkable(to_id)
	
	var id_path = astar.get_id_path(from_id, to_id)
	var world_path = PackedVector3Array()
	
	for id in id_path:
		world_path.append(_grid_to_world(id))
	
	# Optimize!
	world_path = _smooth_path(world_path)
		
	# Draw Debug
	# _draw_path_line(id_path) # Debug Draw Raw?
	_draw_path_line(world_path)
		
	_draw_path_line(world_path)
		
	return world_path

func get_closest_walkable_point(world_pos: Vector3) -> Vector3:
	if not active_region: 
		return world_pos
		
	var grid_id = _world_to_grid(world_pos)
	
	# If already valid, return as is (snapped to center though? Maybe keep original if valid?)
	# Actually, for Blink, snapping to center is safer to avoid wall clips.
	if not astar.is_point_solid(grid_id):
		return world_pos # Return exact click if valid
		
	var safe_id = _find_closest_walkable(grid_id)
	return _grid_to_world(safe_id)

func _find_closest_walkable(start_id: Vector2i, search_radius: int = 4) -> Vector2i:
	# Spiral outward to find first non-solid cell
	# Radius 1 to N
	for r in range(1, search_radius + 1):
		for x in range(start_id.x - r, start_id.x + r + 1):
			for y in range(start_id.y - r, start_id.y + r + 1):
				# Only check perimeter of this radius/box
				if abs(x - start_id.x) != r and abs(y - start_id.y) != r:
					continue
				
				var id = Vector2i(x, y)
				# Check bounds
				if not map_rect.has_point(id):
					continue
					
				if not astar.is_point_solid(id):
					return id # Found closest!
	
	return start_id # Fallback (Stay blocked if nothing found)

func _smooth_path(raw_path: PackedVector3Array) -> PackedVector3Array:
	if raw_path.size() < 3:
		return raw_path
		
	var smoothed = PackedVector3Array()
	smoothed.append(raw_path[0])
	
	var current_idx = 0
	
	while current_idx < raw_path.size() - 1:
		# Greedy look-ahead: Find the furthest visible point
		var next_idx = current_idx + 1
		
		# Iterate backwards from end to next
		for probe_idx in range(raw_path.size() -1, current_idx, -1):
			var start_pos = raw_path[current_idx]
			var end_pos = raw_path[probe_idx]
			
			# Lift rays slightly to avoid ground clips
			var ray_from = start_pos + Vector3(0, 0.5, 0)
			var ray_to = end_pos + Vector3(0, 0.5, 0)
			
			# THICK RAYCAST (Whiskers)
			# Check width of unit (0.4 radius) to prevent corner clipping
			var dir = (ray_to - ray_from).normalized()
			var side = dir.cross(Vector3.UP).normalized() * 0.4 # 0.4 Margin
			
			var from_left = ray_from + side
			var to_left = ray_to + side
			var from_right = ray_from - side
			var to_right = ray_to - side
			
			var space_state = get_tree().root.get_world_3d().direct_space_state
			
			# Check Left Whisker
			var query_l = PhysicsRayQueryParameters3D.create(from_left, to_left)
			query_l.collision_mask = 1 + 8
			if space_state.intersect_ray(query_l):
				continue # Blocked
				
			# Check Right Whisker
			var query_r = PhysicsRayQueryParameters3D.create(from_right, to_right)
			query_r.collision_mask = 1 + 8
			if space_state.intersect_ray(query_r):
				continue # Blocked
			
			# Clear line of sight (WIDTH VERIFIED)
			next_idx = probe_idx
			break
		
		smoothed.append(raw_path[next_idx])
		current_idx = next_idx
		
	return smoothed

# -----------------------------------------------------------
# Coordinate Conversion
# -----------------------------------------------------------
func _world_to_grid(pos: Vector3) -> Vector2i:
	var local_x = pos.x - grid_origin.x
	var local_z = pos.z - grid_origin.z
	var x = int(local_x / cell_size)
	var y = int(local_z / cell_size)
	return Vector2i(x, y)

func _grid_to_world(id: Vector2i) -> Vector3:
	var x = grid_origin.x + (id.x * cell_size) + (cell_size * 0.5)
	var z = grid_origin.z + (id.y * cell_size) + (cell_size * 0.5)
	return Vector3(x, 0.5, z) # +0.5 height bias

func _clamp_to_grid(id: Vector2i) -> Vector2i:
	return Vector2i(
		clamp(id.x, 0, map_rect.size.x - 1),
		clamp(id.y, 0, map_rect.size.y - 1)
	)

var debug_enabled: bool = false

var debug_texture_mesh: MeshInstance3D

func _setup_debug_draw():
	# Path Line Debug
	debug_mesh_instance = MeshInstance3D.new()
	debug_mesh_instance.name = "DebugPathParams"
	add_child(debug_mesh_instance)
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color.CYAN
	mat.vertex_color_use_as_albedo = false
	debug_mesh_instance.material_override = mat

	# Grid Debug (Texture Plane)
	debug_texture_mesh = MeshInstance3D.new()
	debug_texture_mesh.name = "DebugGridTexture"
	debug_texture_mesh.visible = false
	debug_texture_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	
	# CRITICAL FIX: Huge AABB to prevent culling when looking away from center
	debug_texture_mesh.custom_aabb = AABB(Vector3(-100000, -100000, -100000), Vector3(200000, 200000, 200000))
	add_child(debug_texture_mesh)
	
	var plane_mesh = PlaneMesh.new()
	debug_texture_mesh.mesh = plane_mesh
	
	# Shader Material for "Grid" look (Gaps)
	var shader = load("res://debug_grid.gdshader")
	if shader:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = shader
		debug_texture_mesh.material_override = shader_mat
	else:
		push_error("GridManager: Could not load debug_grid.gdshader!")

func _update_debug_grid():
	if not active_region or not debug_enabled: return
	
	var start_t = Time.get_ticks_msec()
	
	# Resize Plane to match map
	var plane = debug_texture_mesh.mesh as PlaneMesh
	plane.size = Vector2(map_rect.size.x * cell_size, map_rect.size.y * cell_size)
	
	# Center it
	var center_x = grid_origin.x + (plane.size.x / 2.0)
	var center_z = grid_origin.z + (plane.size.y / 2.0)
	debug_texture_mesh.global_position = Vector3(center_x, active_region.global_position.y + 0.05, center_z)
	
	# Create/Update Image
	var width = map_rect.size.x
	var height = map_rect.size.y
	
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	
	# Colors
	var col_blocked = Color(1, 0, 0, 0.5)
	var col_walkable = Color(0, 1, 0, 0.2) # Slightly more visible
	
	for y in range(height):
		for x in range(width):
			var id = Vector2i(x, y)
			if astar.is_point_solid(id):
				img.set_pixel(x, y, col_blocked)
			else:
				img.set_pixel(x, y, col_walkable)
				
	var tex = ImageTexture.create_from_image(img)
	
	var mat = debug_texture_mesh.material_override as ShaderMaterial
	if mat:
		mat.set_shader_parameter("grid_texture", tex)
		mat.set_shader_parameter("grid_size", Vector2(width, height))
	
	print("[GridManager] Texture Debug Grid updated in %dms" % (Time.get_ticks_msec() - start_t))

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_F6:
		_toggle_debug()

func _toggle_debug():
	debug_enabled = not debug_enabled
	print("[GridManager] Debug View: ", debug_enabled)
	
	if debug_enabled:
		_update_debug_grid()
		if debug_texture_mesh:
			debug_texture_mesh.visible = true
	else:
		if debug_texture_mesh:
			debug_texture_mesh.visible = false

func _draw_path_line(points: PackedVector3Array):
	if points.size() < 2: 
		debug_mesh_instance.mesh = null
		return
		
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		mesh.surface_add_vertex(p + Vector3(0, 0.6, 0)) # Lift to match grid
	mesh.surface_end()
	
	debug_mesh_instance.mesh = mesh
