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
		unit.velocity = dir.normalized() * stats.stat_data.move_speed
		unit.move_and_slide()
	else:
		# Only stop if not following
		if not follow_target:
			agent.set_target_position(unit.global_position)
			target_reached.emit()
