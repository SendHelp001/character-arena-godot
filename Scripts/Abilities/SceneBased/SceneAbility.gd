extends Ability
class_name SceneAbility

@export var ability_scene: PackedScene

# Override _cast to use the scene's logic
func _cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	if not ability_scene:
		push_warning("SceneAbility: No scene assigned!")
		return false
		
	# Instantiate the scene to run its logic
	var instance = ability_scene.instantiate()
	caster.get_tree().root.add_child(instance)
	
	# If the root has a cast method, call it
	if instance.has_method("cast"):
		var result = instance.cast(caster, target_pos, level)
		# We might want to keep the instance alive if it has duration, 
		# or queue_free it if it was just a logic runner.
		# For now, let the instance manage its own life (e.g. projectile spawner)
		# If it's just a data container, we should free it.
		
		# If it's a projectile spawner, it likely spawned something and can be freed?
		# Or maybe the instance IS the projectile?
		# Let's assume AbilityRoot handles its lifecycle or is just a spawner.
		
		# If the instance is an AbilityRoot, it might just spawn things.
		# Let's queue_free it after a frame if it's just a spawner.
		# But if it's a persistent effect, we shouldn't.
		# For safety, let the AbilityRoot decide (e.g. call queue_free() in its cast())
		return result
		
	return false
