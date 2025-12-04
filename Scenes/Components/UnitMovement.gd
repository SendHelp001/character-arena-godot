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
func set_target_position(pos: Vector3):
	if agent:
		agent.set_target_position(pos)

func is_navigation_finished() -> bool:
	return agent.is_navigation_finished() if agent else true

func stop_movement():
	if agent and unit:
		agent.set_target_position(unit.global_position)

# ------------------------------
# Movement Processing
# ------------------------------
func process_movement(_delta: float):
	if not stats or not stats.stat_data or not agent or not unit:
		return
	
	if agent.is_navigation_finished():
		movement_finished.emit()
		return
	
	var next = agent.get_next_path_position()
	var dir = next - unit.global_position
	
	if dir.length() > 0.1:
		unit.velocity = dir.normalized() * stats.stat_data.move_speed
		unit.move_and_slide()
	else:
		agent.set_target_position(unit.global_position)
		target_reached.emit()
