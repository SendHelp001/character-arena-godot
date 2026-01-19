extends Node
# class_name UnitMovement # Removed to fix cyclic dependency


# ------------------------------
# Signals
# ------------------------------
signal movement_finished
signal target_reached

# ------------------------------
# References
# ------------------------------
var unit: CharacterBody3D
var stats
var agent: Node # Deprecated

# ------------------------------
# Tuning
# ------------------------------
const SPEED_SCALE = 0.01

@export_group("Context Steering")
## How fast we turn/accelerate to the new direction (smoothing)
@export var steer_force: float = 15.0      
## How far ahead (in meters) we check for obstacles (Short Path)
@export var look_ahead: float = 2.5        
## How close we need to be to a waypoint to advance
@export var stop_distance: float = 0.5     

@export_group("Dota Mechanics")
## Degrees per second the unit can turn
@export var turn_rate: float = 360.0 
## Facing threshold (0.0 to 1.0). 1.0 = Must face perfectly. 0.7 = ~45 degrees.
@export var face_requirement: float = 0.7

# The 8 cardinal/intercardinal directions flattened to XZ
var ray_directions: Array[Vector3] = []

# ------------------------------
# Pathing State
# ------------------------------
var current_path: PackedVector3Array
var current_path_idx: int = 0
var movement_active: bool = false
var follow_target: Node = null
var forced_facing_target: Vector3 = Vector3.INF # INF = No target

# ------------------------------
# Initialization
# ------------------------------
func _ready():
	_generate_ray_directions()

func _generate_ray_directions():
	# Generate 8 directions in a circle
	ray_directions.clear()
	var num_rays = 8
	for i in range(num_rays):
		var angle = i * (2 * PI / num_rays)
		var dir = Vector3(sin(angle), 0, cos(angle))
		ray_directions.append(dir)

func setup(p_unit, p_stats, _p_agent = null):
	unit = p_unit
	stats = p_stats
	agent = null

# ------------------------------
# Public API
# ------------------------------
func set_target_position(pos: Vector3):
	follow_target = null
	_update_path(pos)

func set_follow_target(target: Node):
	follow_target = target
	if is_instance_valid(target):
		_update_path(target.global_position)

func stop_movement():
	movement_active = false
	follow_target = null
	forced_facing_target = Vector3.INF
	current_path.clear()
	if unit:
		unit.velocity = Vector3.ZERO

func look_at_point(pos: Vector3):
	"""Commands unit to face a point without moving there"""
	stop_movement() # turning interrupts moving
	forced_facing_target = pos
	forced_facing_target.y = unit.global_position.y # Keep horizontal

func stop_looking():
	forced_facing_target = Vector3.INF

func is_navigation_finished() -> bool:
	return not movement_active


# ------------------------------
# Core Logic
# ------------------------------
func process_movement(delta: float):
	if not unit or not stats or not stats.stat_data: return
	
	# 1. Update Path (if following)
	if follow_target and is_instance_valid(follow_target):
		if current_path.is_empty() or (current_path.size() > 0 and current_path[-1].distance_to(follow_target.global_position) > 1.0):
			_update_path(follow_target.global_position)
	elif follow_target:
		stop_movement()
		return

	if not movement_active:
		# IDLE TURNING (For casting)
		if forced_facing_target != Vector3.INF:
			var dir = (forced_facing_target - unit.global_position).normalized()
			dir.y = 0
			if dir.length() > 0.01:
				face_direction(dir, delta)
			# No movement, just rotation
			unit.velocity = Vector3.ZERO
			unit.move_and_slide()
		return

	# 2. Path Following Logic
	if current_path.is_empty():
		_complete_movement()
		return

	# Get goal point
	var target_point = current_path[current_path_idx]
	
	# Use 2D Distance (XZ only) to avoid height miss issues
	var unit_pos_2d = Vector2(unit.global_position.x, unit.global_position.z)
	var target_pos_2d = Vector2(target_point.x, target_point.z)
	var dist_2d = unit_pos_2d.distance_to(target_pos_2d)
	
	# Skip waypoints logic
	while dist_2d < stop_distance:
		current_path_idx += 1
		if current_path_idx >= current_path.size():
			_complete_movement()
			return
		target_point = current_path[current_path_idx]
		target_pos_2d = Vector2(target_point.x, target_point.z)
		dist_2d = unit_pos_2d.distance_to(target_pos_2d)

	# 3. Calculate Velocities
	var target_speed = stats.stat_data.move_speed * SPEED_SCALE
	
	# Short Path Direction (Context Steering)
	var desired_velocity = _calculate_context_velocity(target_point, target_speed)
	var desired_dir = desired_velocity.normalized()
	
	# 4. Turn Rate Mechanic
	if desired_dir.length() > 0.01:
		face_direction(desired_dir, delta)
	
	# Check facing penalty
	var forward = -unit.global_transform.basis.z 
	var facing_dot = forward.dot(desired_dir)
	
	# ANTI-STUCK: If we are barely moving, ignore turn rate penalty to force movement
	var is_stuck = unit.velocity.length() < 0.5
	
	if facing_dot < face_requirement and not is_stuck:
		# Only apply penalty if we are moving significantly
		desired_velocity *= 0.1 
	
	# 5. Integrate Velocity
	unit.velocity = unit.velocity.lerp(desired_velocity, steer_force * delta)
	unit.move_and_slide()
	
	# Debug
	# print("V: %.2f | Dot: %.2f | Stuck: %s" % [unit.velocity.length(), facing_dot, is_stuck])

# ------------------------------
# Rotation Logic
# ------------------------------
func face_direction(dir: Vector3, delta: float):
	"""Rotates unit towards direction using turn rate"""
	# Robust Rotation using Basis
	# This ensures we match Godot's -Z forward convention perfectly
	var target_basis = Basis.looking_at(dir, Vector3.UP)
	var target_rot = target_basis.get_euler().y
	
	# Smoothly rotate
	unit.rotation.y = lerp_angle(unit.rotation.y, target_rot, turn_rate * delta * 0.02)

# ------------------------------
# Context Steering Engine
# ------------------------------
func _calculate_context_velocity(target_pos: Vector3, top_speed: float) -> Vector3:
	var desired_dir = (target_pos - unit.global_position).normalized()
	desired_dir.y = 0
	
	# Setup Maps
	var interest = []
	var danger = []
	interest.resize(8)
	danger.resize(8)
	interest.fill(0.0)
	danger.fill(0.0)
	
	# Interest
	for i in range(8):
		var d = ray_directions[i]
		var dot = d.dot(desired_dir)
		interest[i] = max(0, dot)
	
	# Danger
	var space_state = unit.get_world_3d().direct_space_state
	for i in range(8):
		var d = ray_directions[i]
		var query = PhysicsRayQueryParameters3D.create(
			unit.global_position,
			unit.global_position + (d * look_ahead),
			2 # Detect Units Only (Mask 2)
		)
		query.exclude = [unit.get_rid()]
		var result = space_state.intersect_ray(query)
		if result:
			var dist = (result.position - unit.global_position).length()
			danger[i] = clamp((look_ahead - dist) / look_ahead, 0.0, 1.0)
	
	# Choose
	var chosen_dir = Vector3.ZERO
	for i in range(8):
		var score = interest[i] - (danger[i] * 3.0) 
		if score > 0:
			chosen_dir += ray_directions[i] * score
			
	if chosen_dir.length() > 0.01:
		chosen_dir = chosen_dir.normalized()
	else:
		chosen_dir = desired_dir * 0.5 
		
	return chosen_dir * top_speed

# ------------------------------
# Helpers
# ------------------------------
func _update_path(target_pos: Vector3):
	# USE CUSTOM GRID MANAGER
	# This replaces Godot's NavigationServer with our custom A* Grid
	# USE NAVIGATION SERVER (Standard 3D Navigation)
	# Falling back to standard navigation since GridManager has been deprecated.
	var map = unit.get_world_3d().get_navigation_map()
	current_path = NavigationServer3D.map_get_path(map, unit.global_position, target_pos, true)
	current_path_idx = 0
	
	if current_path.is_empty():
		stop_movement()
	else:
		movement_active = true

func _complete_movement():
	movement_active = false
	unit.velocity = Vector3.ZERO
	movement_finished.emit()
	target_reached.emit()
