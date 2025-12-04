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
	# Clear follow target when manually moving
	follow_target = null
	if agent:
		agent.set_target_position(pos)

func set_follow_target(target: Node):
	"""Follow another unit continuously"""
	follow_target = target

func is_navigation_finished() -> bool:
	return agent.is_navigation_finished() if agent else true

func stop_movement():
	follow_target = null  # Stop following
	if agent and unit:
		agent.set_target_position(unit.global_position)

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
	var dir = next - unit.global_position
	
	if dir.length() > 0.1:
		var move_velocity = dir.normalized() * stats.stat_data.move_speed
		
		# Apply avoidance steering (separation + tangent)
		var avoidance = _calculate_separation_force()
		unit.velocity = move_velocity + avoidance
		unit.move_and_slide()
	else:
		# Only stop if not following
		if not follow_target:
			agent.set_target_position(unit.global_position)
			target_reached.emit()

func _calculate_separation_force() -> Vector3:
	var avoidance_force = Vector3.ZERO
	var neighbors = unit.get_node("SeparationArea").get_overlapping_bodies()
	var separation_strength = 4.0
	var steering_strength = 6.0
	
	for neighbor in neighbors:
		if neighbor != unit and neighbor is CharacterBody3D:
			var to_neighbor = neighbor.global_position - unit.global_position
			var dist = to_neighbor.length()
			
			if dist < 0.01: continue
			
			# 1. Repulsion (Personal Space) - Push away if too close
			if dist < 1.0:
				var push_force = (1.0 - dist) / 1.0
				avoidance_force -= to_neighbor.normalized() * push_force * separation_strength
			
			# 2. Tangent Steering (Going Around)
			# Check if neighbor is roughly in front of us
			var forward = -unit.global_transform.basis.z
			if unit.velocity.length() > 0.1:
				forward = unit.velocity.normalized()
				
			var dot = forward.dot(to_neighbor.normalized())
			
			# If neighbor is in front (dot > 0.5 means within ~60 degrees)
			if dot > 0.5 and dist < 2.0:
				# Calculate tangent vector (perpendicular to direction to neighbor)
				# We want to steer to the side that is "easier"
				var tangent = to_neighbor.cross(Vector3.UP).normalized()
				
				# Determine which side to steer towards using cross product with forward
				# If neighbor is slightly left, steer right. If slightly right, steer left.
				var side = forward.cross(to_neighbor).y
				if side > 0:
					avoidance_force -= tangent * steering_strength # Steer Left
				else:
					avoidance_force += tangent * steering_strength # Steer Right
	
	# Flatten to XZ plane
	avoidance_force.y = 0
	return avoidance_force
