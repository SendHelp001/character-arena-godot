extends Node
class_name UnitCombat

# ------------------------------
# Signals
# ------------------------------
signal target_acquired(target: Node)
signal attack_executed(target: Node)
signal combat_mode_changed(is_aggressive: bool)

# ------------------------------
# Auto-targeting settings
# ------------------------------
@export var auto_target_range := 15.0
@export var auto_target_interval := 0.5

# ------------------------------
# Combat Mode
# ------------------------------
enum CombatMode { PASSIVE, AGGRESSIVE }
var combat_mode: CombatMode = CombatMode.PASSIVE

# ------------------------------
# References
# ------------------------------
var unit  # Unit type
var stats  # Stats type
var movement  # UnitMovement type

# ------------------------------
# State
# ------------------------------
var target: Node = null
var attack_timer := 0.0
var auto_target_timer := 0.0

# ------------------------------
# Initialization
# ------------------------------
func setup(p_unit, p_stats, p_movement):
	unit = p_unit
	stats = p_stats
	movement = p_movement

# ------------------------------
# Combat Mode Management
# ------------------------------
func set_aggressive_mode(aggressive: bool):
	var new_mode = CombatMode.AGGRESSIVE if aggressive else CombatMode.PASSIVE
	if combat_mode != new_mode:
		combat_mode = new_mode
		combat_mode_changed.emit(aggressive)
		if not aggressive:
			clear_target()

func is_aggressive() -> bool:
	return combat_mode == CombatMode.AGGRESSIVE

# ------------------------------
# Target Management
# ------------------------------
func set_target(new_target: Node):
	target = new_target
	if new_target:
		# Setting a target puts unit in aggressive mode
		set_aggressive_mode(true)
		target_acquired.emit(new_target)

func get_current_target() -> Node:
	return target

func clear_target():
	target = null

func stop_all_actions():
	"""Stop all combat actions and return to passive mode"""
	set_aggressive_mode(false)
	clear_target()

# ------------------------------
# Combat Processing
# ------------------------------
func process_combat(delta: float):
	attack_timer = max(0, attack_timer - delta)
	
	if stats:
		stats.regen_mana(delta)
	
	_process_attack()
	
	# Only auto-target if in aggressive mode
	if combat_mode == CombatMode.AGGRESSIVE:
		_find_auto_target(delta)

func _process_attack():
	if not target or not is_instance_valid(target):
		target = null
		return
	
	# Only attack enemies
	if target.has_method("get_team_id") and target.get_team_id() == unit.team_id:
		target = null
		return
	
	if not stats or not stats.stat_data:
		return
	
	var dist = unit.global_position.distance_to(target.global_position)
	var attack_range = stats.stat_data.attack_range
	
	if dist <= attack_range:
		# Stop movement inside range
		if movement and not movement.is_navigation_finished():
			movement.stop_movement()
		
		if attack_timer <= 0:
			_execute_attack()
	else:
		# Move toward target if out of range
		if movement:
			movement.set_target_position(target.global_position)

func _execute_attack():
	if not stats or not stats.stat_data or not target:
		return
	
	attack_timer = stats.stat_data.attack_cooldown
	
	# Call take_damage directly on the target unit
	if target.has_method("take_damage"):
		target.take_damage(stats.stat_data.attack_damage)
		attack_executed.emit(target)
		print("%s attacked %s for %d damage" % [unit.name, target.name, stats.stat_data.attack_damage])
	else:
		print("Warning: %s cannot take damage!" % target.name)

# ------------------------------
# Auto-Targeting AI
# ------------------------------
func _find_auto_target(delta: float):
	auto_target_timer -= delta
	if auto_target_timer > 0:
		return
	auto_target_timer = auto_target_interval
	
	# Keep current target if valid and near enough
	if target and is_instance_valid(target):
		if target.has_method("get_team_id") and target.get_team_id() != unit.team_id:
			var dist = unit.global_position.distance_to(target.global_position)
			if dist <= stats.stat_data.attack_range * 1.5:  # buffer
				return
	
	# Find nearest enemy
	var nearest = null
	var min_dist = auto_target_range
	for enemy in unit.get_tree().get_nodes_in_group("unit"):
		if enemy.has_method("get_team_id") and enemy.get_team_id() != unit.team_id and enemy != unit and is_instance_valid(enemy):
			var d = unit.global_position.distance_to(enemy.global_position)
			if d < min_dist:
				min_dist = d
				nearest = enemy
	
	if nearest != target:
		set_target(nearest)
