extends Area3D
class_name Projectile

@export var speed: float = 15.0
var target: Node
var owner_unit: Node
var damage: int = 10

func _physics_process(delta):
	if not target or not is_instance_valid(target):
		queue_free()
		return

	var dir = (target.global_position - global_position).normalized()
	global_position += dir * speed * delta

	if global_position.distance_to(target.global_position) < 0.6:
		_hit_target()

func _hit_target():
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)
	queue_free()
