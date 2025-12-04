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

func _init(ability_resource: Ability = null, owner_unit: Node = null):
	ability = ability_resource
	caster = owner_unit

func _process(delta: float):
	if current_cooldown > 0.0:
		current_cooldown = max(0.0, current_cooldown - delta)
		cooldown_changed.emit(current_cooldown, ability.cooldown if ability else 1.0)

func cast(target_pos: Vector3) -> bool:
	if not can_cast():
		return false
	
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
