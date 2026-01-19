extends Area3D
class_name HitboxComponent

# This component handles receiving damage and forwarding it to the main Unit logic.
# It should be placed on a dedicated Physics Layer (e.g. Layer 3) to separate it from movement collision.

@export var health_component: Node # Optional: Direct reference to health/stats

func _ready():
	# Default configuration:
	# Layer 3 (Value 4) = Hitbox
	# Monitoring = False (Passive)
	# Monitorable = True (Can be hit)
	collision_layer = 4 
	collision_mask = 0 
	monitoring = false
	monitorable = true
	add_to_group("hitbox")

func take_damage(amount: float):
	print("🛡️ Hitbox struck! Forwarding %d damage..." % amount)
	
	# 1. Try explicit reference
	if health_component and health_component.has_method("take_damage"):
		health_component.take_damage(amount)
		return

	# 2. Try parent (Standard Unit composition)
	var parent = get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(amount)
		return
		
	# 3. Try finding "Stats" or "HealthComponent" child
	var stats = parent.get_node_or_null("Stats")
	if stats and stats.has_method("take_damage"):
		stats.take_damage(amount)
		return
	
	push_warning("HitboxComponent: No valid target for take_damage() found on parent: " + parent.name)

func get_team_id() -> int:
	# Forward team check to parent for friendly fire logic
	var parent = get_parent()
	if parent.has_method("get_team_id"):
		return parent.get_team_id()
	return -1
