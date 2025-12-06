extends Ability
class_name BlinkAbility

func _init():
	ability_name = "Blink"
	description = "Teleports to target location"
	cooldown = 12.0
	mana_cost = 75.0
	max_level = 4
	cast_range = 12.0
	cast_point = 0.0  # Instant!
	requires_turn = false
	targeting_mode = CastingMode.TargetingType.POINT
	suggested_hotkey = "E"

func _cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	print("✨ Blink cast at level %d!" % level)
	
	# Clamp to max range
	var caster_pos = caster.global_position
	var direction = target_pos - caster_pos
	direction.y = 0
	
	var current_range = cast_range + (level * 1.0)  # +1m per level
	
	if direction.length() > current_range:
		direction = direction.normalized() * current_range
		target_pos = caster_pos + direction
	
	# Keep Y position (same height)
	target_pos.y = caster_pos.y
	
	# Teleport!
	caster.global_position = target_pos
	print("  Teleported to: ", target_pos)
	
	return true
