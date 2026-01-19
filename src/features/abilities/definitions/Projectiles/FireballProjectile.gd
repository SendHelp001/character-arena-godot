extends DirectionalProjectile

# Impact explosion effect
const IMPACT_EXPLOSION = preload("res://Scenes/Abilities/Projectiles/FireballImpact.tscn")

func _on_body_entered(body):
	# Spawn explosion VFX at impact point
	var explosion = IMPACT_EXPLOSION.instantiate()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	explosion.emitting = true
	
	# Call parent damage logic
	super._on_body_entered(body)
