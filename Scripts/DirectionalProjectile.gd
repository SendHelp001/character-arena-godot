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

	# Safe Connection for area_entered
	if not area_entered.is_connected(_on_area_entered):
		area_entered.connect(_on_area_entered)
	# Safe Connection for body_entered
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

func _physics_process(delta):
	var move_amount = speed * delta
	position -= transform.basis.z * move_amount
	distance_traveled += move_amount
	
	if distance_traveled >= max_range:
		queue_free()

func _on_area_entered(area):
	# Handle HitboxComponent interaction
	if area is HitboxComponent or area.has_method("take_damage"):
		_try_damage(area)

func _on_body_entered(body):
	if body == caster:
		return
	# Handle Wall/Terrain
	if body is StaticBody3D or body is CSGShape3D:
		queue_free()
	# Fallback for Units without Hitboxes (if any)
	elif body.has_method("take_damage"):
		_try_damage(body)

func _try_damage(target):
	if target == caster: return
	
	# Check teams if possible
	var target_team = -1
	var caster_team = -1
	
	if target.has_method("get_team_id"): target_team = target.get_team_id()
	if caster and caster.has_method("get_team_id"): caster_team = caster.get_team_id()
	
	if target_team != -1 and caster_team != -1 and target_team == caster_team:
		return # Ally hit
		
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print("🔥 Projectile hit %s for %d damage" % [target.name, damage])
		queue_free()
