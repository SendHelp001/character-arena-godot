@tool
extends Ability
class_name SceneAbility

@export var ability_scene: PackedScene:
	set(value):
		ability_scene = value
		_sync_from_scene()

func _sync_from_scene():
	if not ability_scene:
		return
		
	# Instantiate momentarily to read values
	# We use can_instantiate check just in case
	if not ability_scene.can_instantiate():
		return
		
	var instance = ability_scene.instantiate()
	if instance is AbilityRoot: # Ensure it's our visual root
		# Sync Data
		ability_name = instance.ability_name
		icon = instance.icon
		suggested_hotkey = instance.suggested_hotkey
		
		cooldown = instance.cooldown
		mana_cost = instance.mana_cost
		max_level = instance.max_level
		
		targeting_mode = instance.targeting_mode
		cast_range = instance.cast_range
		cast_radius = instance.cast_radius
		
		cast_point = instance.cast_point
		requires_turn = instance.requires_turn
		
		print("🔄 Synced stats from Scene: ", ability_name)
	
	instance.queue_free()

# Override _cast to use the scene's logic
func _cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	if not ability_scene:
		push_warning("SceneAbility: No scene assigned!")
		return false
		
	# Instantiate the scene to run its logic
	var instance = ability_scene.instantiate()
	caster.get_tree().root.add_child(instance)
	
	if instance.has_method("cast"):
		var result = instance.cast(caster, target_pos, level)
		# NOTE: logic instances usually need to persist if they are projectiles.
		# If it's a spawner, it should queue_free itself.
		return result
		
	return false
