extends Ability
class_name FrostNovaAbility

func _init():
	# Defaults now in .tres resource file
	ability_name = "Frost Nova"
	
	# Connect to lifecycle events
	on_cast_point_finish.connect(_execute_frost_nova)

func _execute_frost_nova(caster: Node, target_pos: Vector3, level: int):
	"""Apply AoE damage at target location"""
	print("❄️ Frost Nova cast at level %d!" % level)
	
	# Calculate damage
	var damage = base_amount + (amount_per_level * (level - 1))
	
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
