extends Ability
class_name FireballAbility

func _init():
	ability_name = "Fireball"
	description = "Shoots a fireball in a straight line"
	
	# Stats
	cooldown = 5.0
	mana_cost = 100.0
	max_level = 4
	
	# Targeting
	targeting_mode = CastingMode.TargetingType.DIRECTIONAL
	cast_range = 15.0
	cast_radius = 0.5 # Width of projectile
	
	# Mechanics
	cast_point = 0.3
	requires_turn = true
	
	# Effects
	effect_type = "DAMAGE"
	damage_type = "MAGICAL"
	base_amount = 50.0
	amount_per_level = 25.0
	
	# Visuals
	suggested_hotkey = "Q"
	projectile_scene = preload("res://Scenes/Abilities/Projectiles/FireballProjectile.tscn")
