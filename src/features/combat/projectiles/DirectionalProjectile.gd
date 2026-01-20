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
	monitoring = true
	print("🚀 Projectile Spawned. Mask: %d, Monitoring: %s" % [collision_mask, monitoring])

func _ready():
	# Ensure we catch things
	if not monitoring:
		monitoring = true
	
	# Force add Layer 4 (Enemy) and Layer 2 (Units/Player??) to mask if missing
	# Bitmask: Layer 1=1, Layer 2=2, Layer 3=4 (Wait, Godot Layers are 1-based in bitmask?)
	# Value of Layer 1 is 1 (2^0).
	# Value of Layer 3 (Enemy? usually) depends on project.
	# The Sword used "1 | 4". 4 is 2^2, which corresponds to Layer 3? Or did I write 4 as value?
	# In UnitCombat.gd I wrote "1 | 4".
	# If that hit, then I should use the same here.
	collision_mask = collision_mask | 4 | 2 # Add bits 2 and 4 (Value 2 and Value 4)
	
	print("🚀 Projectile Spawned. Mask updated to: %d, Monitoring: %s" % [collision_mask, monitoring])

func _physics_process(delta):
	global_position += direction * speed * delta
	
	traveled_time += delta
	if traveled_time >= life_time:
		queue_free()

func _on_body_entered(body):
	if body == owner_unit:
		return
		
	# Check if hit something damageable
	# 1. Check if hit something damageable (Dummy, Unit, Destructible Wall)
	if body.has_method("take_damage"):
		# Ensure we don't friendly fire if same team
		if owner_unit.has_method("get_team_id") and body.has_method("get_team_id"):
			if owner_unit.get_team_id() == body.get_team_id():
				return # Ignore friendly
				
		print("🎯 Projectile hit damageable: ", body.name)
		body.take_damage(damage)
		queue_free()
		return

	# 2. If NOT damageable, check if it's an obstacle
	if body is StaticBody3D or body is CSGShape3D:
		print("🧱 Projectile hit wall/obstacle: ", body.name)
		queue_free()
	else:
		# Hit something else?
		print("💥 Projectile hit unknown body: ", body.name)
		# Don't destroy immediately unless we want to?
		# For now, safe to destroy on any body impact usually
		queue_free()
