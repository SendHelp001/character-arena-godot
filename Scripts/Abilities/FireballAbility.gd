extends Ability
class_name FireballAbility

func _init():
	# Defaults now in .tres resource file
	ability_name = "Fireball" 
	
	# Connect to lifecycle events
	on_cast_point_finish.connect(_spawn_fireball)

func _spawn_fireball(caster: Node, target_pos: Vector3, level: int):
	"""Spawn fireball projectile when cast point finishes"""
	if not projectile_scene:
		push_warning("Fireball has no projectile scene!")
		return
	
	var proj = projectile_scene.instantiate()
	caster.get_tree().current_scene.add_child(proj)
	
	# Setup projectile transform
	var spawn_pos = caster.global_position + Vector3(0, 1, 0)
	proj.global_position = spawn_pos
	proj.look_at(Vector3(target_pos.x, spawn_pos.y, target_pos.z), Vector3.UP)
	
	# Pass data to projectile
	if proj.has_method("setup"):
		var dmg = calculate_value(caster, level)
		proj.setup(caster, dmg, cast_range, 20.0)
	
	print("🔥 Fireball spawned! Damage: %d" % calculate_value(caster, level))
