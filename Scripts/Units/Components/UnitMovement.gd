extends Node
class_name UnitMovement

# ------------------------------
# Signals
# ------------------------------
signal movement_finished
signal target_reached

# ------------------------------
# References
# ------------------------------
var unit  # CharacterBody3D type
var stats  # Stats type
var agent  # NavigationAgent3D type

# ------------------------------
# Initialization
# ------------------------------
func setup(p_unit, p_stats, p_agent):
	unit = p_unit
	stats = p_stats
	agent = p_agent

# ------------------------------
# Movement Control
# ------------------------------
var follow_target: Node = null  # Unit to follow

func set_target_position(pos: Vector3):
	follow_target = null
	if agent:
		agent.set_target_position(pos)

func set_follow_target(target: Node):
	"""Follow another unit continuously"""
	follow_target = target

func is_navigation_finished() -> bool:
	return agent.is_navigation_finished() if agent else true

func stop_movement():
	follow_target = null
	if agent and unit:
		agent.set_target_position(unit.global_position)

func face_position(target_pos: Vector3):
	"""Instantly rotate unit to face target position (Y-axis only)"""
	if not unit: return
	
	var look_pos = target_pos
	look_pos.y = unit.global_position.y
	
	if unit.global_position.distance_to(look_pos) > 0.1:
		unit.look_at(look_pos, Vector3.UP)

# ------------------------------
# Movement Processing
# ------------------------------
func process_movement(_delta: float):
	if not stats or not stats.stat_data or not agent or not unit:
		return
	
	# Update follow target position
	if follow_target and is_instance_valid(follow_target):
		agent.set_target_position(follow_target.global_position)
	elif follow_target:
		# Follow target no longer valid
		follow_target = null
	
	if agent.is_navigation_finished():
		movement_finished.emit()
		return
	
	var next = agent.get_next_path_position()
	var dir = (next - unit.global_position)
	dir.y = 0  # flatten to XZ
	var distance = dir.length()
	
	if distance > 0.1:
		var move_velocity = dir.normalized() * stats.stat_data.move_speed * 0.01
		
		# Apply avoidance steering (separation + tangent)
		var avoidance = _calculate_separation_force()
		
		# Combine movement + avoidance
		var final_velocity = (move_velocity + avoidance)
		final_velocity.y = 0
		unit.velocity = final_velocity
		unit.move_and_slide()
	else:
		# Stop at target
		if not follow_target:
			agent.set_target_position(unit.global_position)
			target_reached.emit()

# ------------------------------
# Local Steering / Separation
# ------------------------------
func _calculate_separation_force() -> Vector3:
	var avoidance_force = Vector3.ZERO
	var separation_area = unit.get_node_or_null("SeparationArea")
	if not separation_area:
		return avoidance_force
	
	var neighbors = separation_area.get_overlapping_bodies()
	var personal_space = 1.0
	var separation_strength = 4.0
	var tangent_strength = 6.0
	
	for neighbor in neighbors:
		if neighbor != unit and neighbor is CharacterBody3D:
			var offset = neighbor.global_position - unit.global_position
			offset.y = 0
			var dist = offset.length()
			if dist < 0.01: continue
			
			# 1. Repulsion (personal space)
			if dist < personal_space:
				var push = (personal_space - dist) / personal_space
				avoidance_force -= offset.normalized() * push * separation_strength
			
			# 2. Tangent steering (go around unit)
			var forward = unit.velocity.normalized() if unit.velocity.length() > 0.1 else -unit.global_transform.basis.z
			var dot = forward.dot(offset.normalized())
			if dot > 0.5 and dist < 2.0:
				var tangent = offset.cross(Vector3.UP).normalized()
				var side = forward.cross(offset).y
				if side > 0:
					avoidance_force -= tangent * tangent_strength
				else:
					avoidance_force += tangent * tangent_strength
	
	avoidance_force.y = 0
	return avoidance_force
