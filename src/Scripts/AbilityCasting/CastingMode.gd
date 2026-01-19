extends Node
class_name AbilityCastingMode

# Targeting modes (like League's ability types)
enum TargetingType {
	NONE,           # Passive abilities
	DIRECTIONAL,    # Skillshot - shoots in a direction (Fireball)
	CIRCULAR,       # AoE on ground (Frost Nova)
	POINT,          # Click location (Blink)
	UNIT_TARGET,    # Click on unit (future: Lightning Bolt)
}

# Current casting state
var is_casting: bool = false
var current_ability: Ability = null
var caster: Node = null
var targeting_type: TargetingType = TargetingType.NONE

# Visual indicator
var indicator_node: Node3D = null

# Indicator scenes
const CIRCLE_INDICATOR = preload("res://Scenes/AbilityCasting/CircleIndicator.tscn")
const ARROW_INDICATOR = preload("res://Scenes/AbilityCasting/ArrowIndicator.tscn")
const POINT_INDICATOR = preload("res://Scenes/AbilityCasting/PointIndicator.tscn")

signal cast_confirmed(target_position: Vector3)
signal cast_cancelled()

func start_casting(ability: Ability, caster_unit: Node):
	is_casting = true
	current_ability = ability
	caster = caster_unit
	targeting_type = ability.targeting_mode
	
	# Spawn visual indicator
	_spawn_indicator()
	
	print("Started casting: ", ability.ability_name, " (Mode: ", targeting_type, ")")

func _spawn_indicator():
	# Remove old indicator
	if indicator_node:
		indicator_node.queue_free()
	
	# Create new indicator based on targeting type
	match targeting_type:
		TargetingType.CIRCULAR:
			indicator_node = CIRCLE_INDICATOR.instantiate()
			# Scale to ability radius
			if current_ability.cast_radius > 0:
				indicator_node.scale = Vector3.ONE * current_ability.cast_radius
		TargetingType.DIRECTIONAL:
			indicator_node = ARROW_INDICATOR.instantiate()
			# Scale length to range
			indicator_node.scale.z = current_ability.cast_range
		TargetingType.POINT:
			indicator_node = POINT_INDICATOR.instantiate()
	
	if indicator_node:
		get_tree().root.add_child(indicator_node)

func _process(_delta):
	if not is_casting or not indicator_node:
		return
	
	# Update indicator position to follow mouse
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	if not camera:
		return
	
	var mouse_pos = viewport.get_mouse_position()
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	# Raycast to ground
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = origin
	ray.to = origin + direction * 1000
	
	var result = get_tree().root.get_world_3d().direct_space_state.intersect_ray(ray)
	
	if result:
		var target_pos = result.position
		
		# Clamp to max range
		var caster_pos = caster.global_position
		var to_target = target_pos - caster_pos
		to_target.y = 0
		
		if to_target.length() > current_ability.cast_range:
			to_target = to_target.normalized() * current_ability.cast_range
			target_pos = caster_pos + to_target
			target_pos.y = result.position.y
		
		# Position indicator
		indicator_node.global_position = target_pos
		
		# For directional, rotate to face from caster
		if targeting_type == TargetingType.DIRECTIONAL:
			var look_dir = (target_pos - caster_pos).normalized()
			if look_dir.length() > 0.1:
				indicator_node.look_at(target_pos + look_dir, Vector3.UP)
				indicator_node.rotate_object_local(Vector3.UP, PI / 2)

func cancel_casting():
	is_casting = false
	current_ability = null
	caster = null
	targeting_type = TargetingType.NONE
	
	# Hide indicator
	if indicator_node:
		indicator_node.queue_free()
		indicator_node = null
	
	cast_cancelled.emit()
	print("Casting cancelled")

func confirm_cast(target_pos: Vector3):
	if not is_casting:
		return
	
	cast_confirmed.emit(target_pos)
	cancel_casting()

func _input(event):
	if not is_casting:
		return
	
	# Cancel on ESC or right-click
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		cancel_casting()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		cancel_casting()
		get_viewport().set_input_as_handled()
