extends Node
class_name UnitCombat

# ------------------------------
# Signals
# ------------------------------
signal target_acquired(target: Node)
signal attack_windup_started(target: Node)
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
# Ranged Unit Settings
# ------------------------------
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene
@export var projectile_spawn_offset: Vector3 = Vector3(0, 1.2, 0)

# ------------------------------
# State
# ------------------------------
var target: Node = null
var attack_timer := 0.0
var auto_target_timer := 0.0
var windup_timer := 0.0  # Time remaining in windup

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
	# Switching targets cancels current windup
	if target != new_target:
		cancel_windup()
		
	target = new_target
	if new_target:
		# Setting a target puts unit in aggressive mode
		set_aggressive_mode(true)
		target_acquired.emit(new_target)

func get_current_target() -> Node:
	return target

func clear_target():
	cancel_windup()
	target = null

func stop_all_actions():
	"""Stop all combat actions and return to passive mode"""
	cancel_windup()
	set_aggressive_mode(false)
	clear_target()

func cancel_windup():
	if windup_timer > 0:
		windup_timer = 0.0
		# Optional: Emit a signal that windup was cancelled?
		# For now, just silently stop it.

# ------------------------------
# Combat Processing
# ------------------------------
func process_combat(delta: float):
	attack_timer = max(0, attack_timer - delta)
	
	if stats:
		stats.regen_mana(delta)
	
	# Handle Windup
	if windup_timer > 0:
		windup_timer -= delta
		
		# Check if target is still valid/alive during windup
		if not target or not is_instance_valid(target) or (target.has_method("get_stats") and target.get_stats().current_hp <= 0):
			cancel_windup()
			return
			
		# Check if we moved? UnitMovement usually handles moving unit, 
		# so if velocity > 0 maybe cancel? 
		# But UnitMovement.stop_movement() should be called when we start attack.
		# If user manually moves, Unit.gd calls set_move_target -> movement.set_target_position
		# which doesn't directly call us, but Unit.set_move_target calls combat.set_aggressive_mode(false)
		# which calls clear_target -> cancel_windup. So that path is covered.
		
		if windup_timer <= 0:
			_execute_attack()
			
		return # Don't look for new attacks while winding up

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
	
	# Check facing
	if movement:
		var dir_to_target = (target.global_position - unit.global_position).normalized()
		var forward = -unit.global_transform.basis.z
		var dot = forward.dot(dir_to_target)
		
		# Use movement's face_requirement or a default high value for attacking (like 0.9 for ~25 degrees)
		var attack_face_requirement = movement.face_requirement if "face_requirement" in movement else 0.9
		
		if dot < attack_face_requirement:
			movement.look_at_point(target.global_position)
			return # Not facing yet, don't attack
		else:
			movement.stop_looking() # We are facing, stop forcing look so we can attack/move freely if needed
	
	var dist = unit.global_position.distance_to(target.global_position)
	var attack_range = stats.stat_data.attack_range
	
	if dist <= attack_range:
		# Stop movement inside range
		if movement and not movement.is_navigation_finished():
			movement.stop_movement()
		
		if attack_timer <= 0 and windup_timer <= 0:
			_start_windup()
	else:
		# Move toward target if out of range
		if movement:
			movement.set_target_position(target.global_position)

func _start_windup():
	if not stats or not stats.stat_data: return
	
	windup_timer = stats.stat_data.attack_point
	attack_windup_started.emit(target)
	
	# Ensure we stay still
	if movement:
		movement.stop_movement()

func _execute_attack():
	if not stats or not stats.stat_data or not target:
		return
	
	attack_timer = stats.stat_data.attack_cooldown
	
	if is_ranged:
		_spawn_projectile()
	else:
		# Melee damage
		if target.has_method("take_damage"):
			target.take_damage(stats.stat_data.attack_damage)
			attack_executed.emit(target)
			print("%s attacked %s for %d damage" % [unit.name, target.name, stats.stat_data.attack_damage])
		else:
			print("Warning: %s cannot take damage!" % target.name)

# ------------------------------
# Ranged Projectile Spawning
# ------------------------------
func _spawn_projectile():
	if not projectile_scene:
		push_warning("Ranged unit has no projectile scene assigned!")
		return # Keep the return
	# Spawn projectile
	var projectile = projectile_scene.instantiate()
	
	# Add to scene first
	unit.get_tree().current_scene.add_child(projectile)
	
	# Now global_position is valid
	projectile.global_position = unit.global_position + Vector3(0, 1.5, 0)
	
	# Aim at target
	if target:
		projectile.look_at(target.global_position + Vector3(0, 1, 0), Vector3.UP)
	
	# Setup projectile (damage, speed, range)
	if projectile.has_method("setup"):
		var damage_amount = stats.stat_data.attack_damage if stats else 10
		projectile.setup(unit, damage_amount, stats.stat_data.attack_range if stats else 10.0, 20.0)


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
