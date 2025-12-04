extends Ability
class_name FireballAbility

func _cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	print("🔥 Fireball cast at level %d!" % level)
	
	# Calculate damage based on level
	var damage = 50 + (level * 25)
	
	# Find enemies in range (simple AOE implementation)
	var units = caster.get_tree().get_nodes_in_group("unit")
	var hit_count = 0
	
	for unit in units:
		if unit == caster:
			continue
		
		var dist = caster.global_position.distance_to(unit.global_position)
		if dist <= 5.0:  # 5 meter AOE
			# Check if enemy
			if unit.has_method("get_team_id") and caster.has_method("get_team_id"):
				if unit.get_team_id() != caster.get_team_id():
					unit.take_damage(damage)
					hit_count += 1
					print("  Hit %s for %d damage!" % [unit.name, damage])
	
	print("  Total enemies hit: %d" % hit_count)
	return true
