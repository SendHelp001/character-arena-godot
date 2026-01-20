extends Area3D
class_name Projectile

@export var speed: float = 15.0
var target: Node
var owner_unit: Node
var damage: int = 10
var max_range: float = 0.0

func _ready():
	body_entered.connect(_on_body_entered)

func setup(caster_unit: Node, dmg: int, range_val: float, speed_val: float = 15.0, target_unit: Node = null):
	owner_unit = caster_unit
	damage = dmg
	max_range = range_val
	speed = speed_val
	target = target_unit

func _physics_process(delta):
	# Timeout / Range check could be added here
	
	if target:
		# Homing Behavior
		if not is_instance_valid(target):
			queue_free()
			return
			
		var dir = (target.global_position - global_position).normalized()
		global_position += dir * speed * delta
		
		if global_position.distance_to(target.global_position) < 0.6:
			_hit_target(target)
	else:
		# Directional / Dumb Behavior -> handled by Area3D signals usually? 
		# For now, let's assume it moves forward or is handled by subclass
		pass

func _on_body_entered(body):
	# Area3D collision
	_hit_target(body)

func _hit_target(hit_node: Node):
	if hit_node == owner_unit:
		return
		
	if hit_node.has_method("get_team_id") and owner_unit.has_method("get_team_id"):
		if hit_node.get_team_id() == owner_unit.get_team_id():
			return # Don't hit allies
			
	if hit_node.has_method("take_damage"):
		hit_node.take_damage(damage)
		queue_free()
