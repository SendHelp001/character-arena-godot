extends Node
class_name AbilityInstance

# Reference to the ability template
var ability: Ability = null

# Runtime state
var current_level: int = 1
var current_cooldown: float = 0.0

# Caster reference
var caster: Node = null

signal cooldown_changed(remaining: float, total: float)
signal level_changed(new_level: int)
signal ability_used(ability_name: String)

func _init(ability_resource: Ability = null, owner_unit: Node = null):
	ability = ability_resource
	caster = owner_unit

# State Machine for Casting
var is_turning: bool = false
var pending_target: Vector3

func _process(delta: float):
	# Cooldown Management
	if current_cooldown > 0.0:
		current_cooldown = max(0.0, current_cooldown - delta)
		cooldown_changed.emit(current_cooldown, ability.cooldown if ability else 1.0)
		
	# CASTING STATE MACHINE: Turning Phase
	if is_turning and caster:
		_process_turning()

func cast(target_pos: Vector3) -> bool:
	if not can_cast():
		return false
		
	# Check Turn Rate Requirement
	if ability.requires_turn and caster.has_method("get_movement"):
		# Get movement component
		var move = caster.get_movement()
		if move:
			# Start turning
			is_turning = true
			pending_target = target_pos
			move.look_at_point(target_pos)
			return true # "Success" in starting the sequence
			
	# Instant Cast (No turn required)
	return _execute_cast(target_pos)

func _process_turning():
	# Check if facing target
	var caster_forward = -caster.global_transform.basis.z
	var dir_to_target = (pending_target - caster.global_position).normalized()
	dir_to_target.y = 0 # Horizontal only
	
	var alignment = caster_forward.dot(dir_to_target)
	
	# Threshold: 0.98 is roughly 11 degrees cone (Very precise)
	if alignment > 0.98:
		# Faced! Execute.
		is_turning = false
		if caster.movement.has_method("stop_looking"):
			caster.movement.stop_looking()
		
		_execute_cast(pending_target)

func _execute_cast(target_pos: Vector3) -> bool:
	# Spend mana
	if caster.has_method("get_stats"):
		var stats = caster.get_stats()
		if stats and not stats.spend_mana(ability.mana_cost):
			return false
	
	# Execute ability effect
	var success = ability._cast(caster, target_pos, current_level)
	
	if success:
		# Start cooldown
		current_cooldown = ability.cooldown
		cooldown_changed.emit(current_cooldown, ability.cooldown)
		ability_used.emit(ability.ability_name)
	
	return success

func can_cast() -> bool:
	if not ability:
		return false
	
	if current_cooldown > 0.0:
		return false
	
	return ability.can_cast(caster, current_level)

func is_ready() -> bool:
	return current_cooldown <= 0.0

func level_up():
	if current_level < ability.max_level:
		current_level += 1
		level_changed.emit(current_level)

func get_cooldown_ratio() -> float:
	if ability and ability.cooldown > 0:
		return current_cooldown / ability.cooldown
	return 0.0
