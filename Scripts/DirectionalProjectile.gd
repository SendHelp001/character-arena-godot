extends Area3D
class_name DirectionalProjectile

var speed: float = 20.0
var damage: float = 0.0
var max_range: float = 0.0
var distance_traveled: float = 0.0
var caster: Node = null

func setup(caster_unit: Node, dmg: float, range_val: float, speed_val: float = 20.0):
	caster = caster_unit
	damage = dmg
	max_range = range_val
	speed = speed_val

func _physics_process(delta):
	var move_amount = speed * delta
	position -= transform.basis.z * move_amount
	distance_traveled += move_amount
	
	if distance_traveled >= max_range:
		queue_free()

func _on_body_entered(body):
	if body == caster:
		return
		
	if body.has_method("take_damage"):
		# Check teams if possible
		if caster and caster.has_method("get_team_id") and body.has_method("get_team_id"):
			if caster.get_team_id() == body.get_team_id():
				return # Don't hit allies
		
		body.take_damage(damage)
		print("🔥 Projectile hit %s for %d damage" % [body.name, damage])
		queue_free()
	elif body is StaticBody3D or body is CSGShape3D:
		# Hit wall/terrain
		queue_free()
