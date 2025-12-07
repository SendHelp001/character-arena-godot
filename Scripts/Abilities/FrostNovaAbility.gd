extends Ability
class_name FrostNovaAbility

func _init():
	ability_name = "Frost Nova"
	description = "Creates an AoE slow at target location"
	cooldown = 8.0
	mana_cost = 125.0
	max_level = 4
	cast_range = 10.0
	cast_radius = 5.0  # 5 meter AoE
	cast_point = 0.2
	requires_turn = true  # Must face target
	targeting_mode = CastingMode.TargetingType.CIRCULAR
	suggested_hotkey = "W"

func _cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	print("❄️ Frost Nova cast at level %d!" % level)
	
	# The target_pos passed here is ALREADY clamped and positioned by CastingManager
	# So we should use it directly!
	
	# Calculate damage and slow
	var damage = 75 + (level * 30)
	
	# Find all units in AoE
	var units = caster.get_tree().get_nodes_in_group("unit")
	var hit_count = 0
	
	for unit in units:
		if unit == caster:
			continue
		
		# Check distance to the TARGET CENTER (where the circle was)
		# Ignore Y difference for ground-based AoE
		var unit_pos = unit.global_position
		unit_pos.y = target_pos.y 
		
		var dist = target_pos.distance_to(unit_pos)
		
		# Use cast_radius for hit detection
		if dist <= cast_radius:
			# Check if enemy
			if unit.has_method("get_team_id") and caster.has_method("get_team_id"):
				if unit.get_team_id() != caster.get_team_id():
					unit.take_damage(damage)
					hit_count += 1
					print("  Hit %s for %d damage!" % [unit.name, damage])
	
	print("  Total enemies hit: %d" % hit_count)
	return true
