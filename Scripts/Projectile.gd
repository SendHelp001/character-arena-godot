extends Area3D
class_name Projectile

@export var speed: float = 15.0
var target: Node
var owner_unit: Node
var damage: int = 10
var max_range: float = 0.0

func setup(caster_unit: Node, dmg: int, range_val: float, speed_val: float = 15.0, target_unit: Node = null):
	owner_unit = caster_unit
	damage = dmg
	max_range = range_val
	speed = speed_val
	target = target_unit

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
