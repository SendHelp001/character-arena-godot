extends Node
class_name UnitCombat

# ------------------------------
# Signals
# ------------------------------
signal target_acquired(target: Node)
signal attack_windup_started(target: Node)
signal attack_executed(target: Node)
# signal combat_mode_changed(is_aggressive: bool) # Removing aggression mode for Brawler

# ------------------------------
# References
# ------------------------------
var unit  # Unit type
var stats  # Stats type
var movement  # UnitMovement type

# ------------------------------
# Ranged Settings
# ------------------------------
@export var is_ranged: bool = false
@export var projectile_scene: PackedScene
@export var projectile_spawn_offset: Vector3 = Vector3(0, 1.2, 0)

# ------------------------------
# State
# ------------------------------
var target: Node = null
var attack_timer := 0.0
var windup_timer := 0.0

# ------------------------------
# Initialization
# ------------------------------
func setup(p_unit, p_stats, p_movement):
	unit = p_unit
	stats = p_stats
	movement = p_movement

# ------------------------------
# Target Management
# ------------------------------
func set_target(new_target: Node):
	# Switching targets cancels current windup
	if target != new_target:
		cancel_windup()
		
	target = new_target
	if new_target:
		target_acquired.emit(new_target)

func get_current_target() -> Node:
	return target

func clear_target():
	cancel_windup()
	target = null

func stop_all_actions():
	"""Stop all combat actions"""
	cancel_windup()
	clear_target()

func cancel_windup():
	if windup_timer > 0:
		windup_timer = 0.0
		# Optional: Emit a signal that windup was cancelled?
		# For now, just silently stop it.

# ------------------------------
# Manual API (For Hero Controller)
# ------------------------------
func execute_manual_attack(origin_pos: Vector3, direction: Vector3):
	"""
	Called by HeroController to fire immediately in a direction.
	Bypasses the auto-target windup loop.
	"""
	if attack_timer > 0:
		return # Cooldown active
		
	if not stats or not stats.stat_data:
		return

	# Apply Cooldown
	attack_timer = stats.stat_data.attack_cooldown
	
	if is_ranged:
		_spawn_manual_projectile(origin_pos, direction)
	else:
		_perform_manual_melee(origin_pos, direction)

func execute_manual_melee_box(origin_pos: Vector3, direction: Vector3, box_size: Vector3):
	"""Manual melee attack with defined box size"""
	if attack_timer > 0:
		return
		
	if not stats or not stats.stat_data:
		return
		
	# Apply Cooldown
	attack_timer = stats.stat_data.attack_cooldown
	
	# Perform Box Cast
	# Calculate center of the box: slightly in front of the unit
	var center = origin_pos + (direction * (box_size.z / 2.0))
	
	# Create query parameter
	var space_state = unit.get_world_3d().direct_space_state
	var shape = BoxShape3D.new()
	shape.size = box_size
	
	var query = PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	
	# Transform: Positioned at 'center', looking in 'direction'
	var xform = Transform3D()
	xform.origin = center
	
	# Orient box to face direction
	# Basis should be constructed from direction. 
	# Safest is to use look_at on a temp node logic or basis.looking_at
	if direction.length_squared() > 0.001:
		xform.basis = Basis.looking_at(direction, Vector3.UP)
	
	query.transform = xform
	query.collision_mask = 1 | 4 # Terrain(1) isn't needed for damage, but good to know. Enemy(4).
	query.exclude = [unit] # Don't hit self
	
	var results = space_state.intersect_shape(query)
	var hit_something = false
	
	for result in results:
		var collider = result.collider
		if collider and is_instance_valid(collider):
			if collider.has_method("take_damage"):
				# Friendly Fire check
				if collider.has_method("get_team_id") and unit.has_method("get_team_id"):
					if collider.get_team_id() == unit.get_team_id():
						continue
				
				collider.take_damage(stats.stat_data.attack_damage)
				hit_something = true
				
	if hit_something:
		print("⚔️ Sword hit!")
		# Optional: Play sound/effect

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
		
		if windup_timer <= 0:
			_execute_attack()
			
		return

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
		projectile.setup(unit, damage_amount, stats.stat_data.attack_range if stats else 10.0, 20.0, target)

func _spawn_manual_projectile(origin_pos: Vector3, direction: Vector3):
	if not projectile_scene:
		push_warning("Ranged unit has no projectile scene assigned!")
		return
		
	var projectile = projectile_scene.instantiate()
	unit.get_tree().current_scene.add_child(projectile)
	
	# Spawn at camera/origin height (usually passed from camera)
	projectile.global_position = origin_pos
	
	# Look in direction
	# We want the projectile to fly along 'direction'.
	# We can use look_at if we have a point, or set basis manually.
	var target_point = origin_pos + (direction * 50.0)
	projectile.look_at(target_point, Vector3.UP)
	
	if projectile.has_method("setup_directional"):
		var damage_amount = stats.stat_data.attack_damage if stats else 10
		var range_val = stats.stat_data.attack_range if stats else 20.0
		projectile.setup_directional(unit, damage_amount, range_val, 40.0, direction)
	elif projectile.has_method("setup"):
		# Fallback for old projectiles
		var damage_amount = stats.stat_data.attack_damage if stats else 10
		projectile.setup(unit, damage_amount, stats.stat_data.attack_range if stats else 10.0, 40.0, null)

func _perform_manual_melee(origin_pos: Vector3, direction: Vector3):
	# Simple hitbox check in front
	# This requires a proper hitbox system, for now we can do a shape cast or simplified raycast
	print("Manual Melee Attack performed towards: ", direction)
	# TODO: Implement Sector/Shape Cast for melee



# ------------------------------
# Auto-Targeting AI (Removed for Brawler/Action style)
# ------------------------------
# func _find_auto_target(delta: float): ...
