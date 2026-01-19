extends Area3D
class_name DirectionalProjectile

@export var speed: float = 20.0
@export var life_time: float = 3.0

var owner_unit: Node
var damage: int = 10
var direction: Vector3 = Vector3.FORWARD
var traveled_time: float = 0.0

func setup_directional(caster_unit: Node, dmg: int, _range_val: float, speed_val: float, dir: Vector3):
	owner_unit = caster_unit
	damage = dmg
	speed = speed_val
	direction = dir.normalized()
	
	# Connect overlap
	body_entered.connect(_on_body_entered)

func _physics_process(delta):
	global_position += direction * speed * delta
	
	traveled_time += delta
	if traveled_time >= life_time:
		queue_free()

func _on_body_entered(body):
	if body == owner_unit:
		return
		
	# Check if hit something damageable
	if body.has_method("take_damage"):
		# Ensure we don't friendly fire if same team
		if owner_unit.has_method("get_team_id") and body.has_method("get_team_id"):
			if owner_unit.get_team_id() == body.get_team_id():
				return # Ignore friendly
				
		body.take_damage(damage)
		queue_free()
	elif body is StaticBody3D or body is CSGShape3D:
		# Hit wall/obstacles
		queue_free()
