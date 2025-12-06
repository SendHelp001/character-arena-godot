extends Node

# Casting manager - add as child of World scene
# NO autoload needed!

enum TargetingType {
	NONE,
	DIRECTIONAL,
	CIRCULAR,
	POINT,
	UNIT_TARGET,
}

var is_casting: bool = false
var current_ability: Ability = null
var current_ability_instance: AbilityInstance = null
var caster: Node = null
var targeting_type: TargetingType = TargetingType.NONE

var indicator: Node3D = null
var range_indicator: Node3D = null

const DECAL_INDICATOR = preload("res://Scenes/AbilityCasting/DecalIndicator.tscn")
const TEX_CIRCLE = preload("res://Resources/Textures/IndicatorCircle.tres")
const TEX_ARROW = preload("res://Resources/Textures/IndicatorArrow.tres")
const TEX_RING = preload("res://Resources/Textures/IndicatorRing.tres")

signal casting_started(ability_name: String)
signal casting_finished()
signal casting_cancelled()

func _ready():
	process_priority = -100
	add_to_group("casting_manager")

func start_casting(ability_inst: AbilityInstance, casting_unit: Node):
	if not ability_inst or not ability_inst.ability:
		return
	
	is_casting = true
	current_ability_instance = ability_inst
	current_ability = ability_inst.ability
	caster = casting_unit
	targeting_type = current_ability.targeting_mode
	
	_create_indicators()
	casting_started.emit(current_ability.ability_name)
	print("🎯 Casting started: ", current_ability.ability_name)

func _create_indicators():
	# Clear old
	if indicator: indicator.queue_free()
	if range_indicator: range_indicator.queue_free()
	indicator = null
	range_indicator = null
	
	# CHECK: Is this a Scene-Based Ability (via Adapter)?
	if current_ability is SceneAbility and current_ability.ability_scene:
		var scene_instance = current_ability.ability_scene.instantiate()
		
		# Try to find the VisualIndicator child
		var visual_node = scene_instance.get_node_or_null("VisualIndicator")
		if visual_node:
			# We found the indicator!
			# Detach it from the scene instance so we can use it, 
			# or just use the whole scene instance as the indicator container.
			
			# Let's use the whole scene instance, but we need to be careful about its other children.
			# For WYSIWYG, the scene IS the indicator representation.
			
			get_tree().root.add_child(scene_instance)
			indicator = scene_instance # Keep reference to delete later
			
			# If the scene root is AbilityRoot, it might have stats we want to respect?
			# The SceneAbility resource should ideally mirror them, or we trust the scene.
			# For casting, we just need the visual.
			
			# Position it
			indicator.global_position = caster.global_position
			
			# We don't need to manually set texture/size because the Scene already has it configured!
			# That's the beauty of the Visual Editor.
			return # Done, we have our indicator
			
		scene_instance.queue_free() # Failed to find indicator
	
	# Standard Resource-Based Logic (Fallback)
	
	# Standard Resource-Based Logic (Keep this for backward compatibility)
	
	# 1. Create Range Indicator (Ring Decal)
	if current_ability.cast_range > 0:
		range_indicator = DECAL_INDICATOR.instantiate()
		get_tree().root.add_child(range_indicator)
		range_indicator.set_texture(TEX_RING)
		range_indicator.global_position = caster.global_position
		var size = current_ability.cast_range * 2.0
		range_indicator.set_size(Vector3(size, 10.0, size))
	
	# 2. Create Targeting Indicator (Decal)
	match targeting_type:
		TargetingType.CIRCULAR:
			indicator = DECAL_INDICATOR.instantiate()
			get_tree().root.add_child(indicator)
			indicator.set_texture(TEX_CIRCLE)
			var size = current_ability.cast_radius * 2.0
			indicator.set_size(Vector3(size, 10.0, size))
			
		TargetingType.DIRECTIONAL:
			indicator = DECAL_INDICATOR.instantiate()
			get_tree().root.add_child(indicator)
			indicator.set_texture(TEX_ARROW)
			indicator.global_position = caster.global_position
			indicator.set_size(Vector3(2.0, 10.0, current_ability.cast_range))
			
		TargetingType.POINT:
			indicator = DECAL_INDICATOR.instantiate()
			get_tree().root.add_child(indicator)
			indicator.set_texture(TEX_CIRCLE)
			indicator.set_size(Vector3(2.0, 10.0, 2.0))

func _input(event):
	if not is_casting:
		return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_confirm_cast()
		get_viewport().set_input_as_handled()
		return
	
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed) or \
	   (event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed):
		cancel_casting()
		get_viewport().set_input_as_handled()
		return
	
	if event is InputEventMouseButton or event is InputEventKey:
		get_viewport().set_input_as_handled()

func _process(_delta):
	if not is_casting or not caster:
		return
		
	# Update Range Indicator position
	if range_indicator:
		range_indicator.global_position = caster.global_position
	
	# Raycast for mouse position
	var viewport = get_viewport()
	var camera = viewport.get_camera_3d()
	if not camera: return
	
	var mouse_pos = viewport.get_mouse_position()
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = origin
	ray.to = origin + direction * 1000
	
	var result = space_state.intersect_ray(ray)
	if not result: return
	
	var mouse_world_pos = result.position
	var caster_pos = caster.global_position
	
	# Update Targeting Indicator
	if indicator:
		if targeting_type == TargetingType.DIRECTIONAL:
			# Directional: Anchored to caster, rotates to face mouse
			
			indicator.global_position = caster_pos
			var look_target = mouse_world_pos
			look_target.y = caster_pos.y
			indicator.look_at(look_target, Vector3.UP)
			
			# Offset the decal forward by half its length so it starts at caster
			# (Decals are centered by default)
			indicator.translate_object_local(Vector3(0, 0, -current_ability.cast_range / 2.0))
			
		else:
			# Circular/Point: Follows mouse, clamped to range
			var target_pos = mouse_world_pos
			var to_target = target_pos - caster_pos
			to_target.y = 0
			
			if to_target.length() > current_ability.cast_range:
				to_target = to_target.normalized() * current_ability.cast_range
				target_pos = caster_pos + to_target
				target_pos.y = mouse_world_pos.y
			
			indicator.global_position = target_pos

func _confirm_cast():
	if not is_casting:
		return
	
	var target_pos = Vector3.ZERO
	
	if targeting_type == TargetingType.DIRECTIONAL:
		if indicator:
			# Re-calculate target based on look direction
			# Since we translated the indicator, we need to be careful.
			# Best to just use caster pos + direction to mouse
			var mouse_pos = get_viewport().get_mouse_position()
			var camera = get_viewport().get_camera_3d()
			var origin = camera.project_ray_origin(mouse_pos)
			var direction = camera.project_ray_normal(mouse_pos)
			var space_state = get_tree().root.get_world_3d().direct_space_state
			var ray = PhysicsRayQueryParameters3D.new()
			ray.from = origin
			ray.to = origin + direction * 1000
			var result = space_state.intersect_ray(ray)
			
			if result:
				var look_dir = (result.position - caster.global_position).normalized()
				look_dir.y = 0
				target_pos = caster.global_position + look_dir * current_ability.cast_range
	else:
		target_pos = indicator.global_position if indicator else caster.global_position
	
	if current_ability_instance:
		var success = current_ability_instance.cast(target_pos)
		if success:
			print("✅ Cast confirmed: ", current_ability.ability_name)
	
	_end_casting()

func cancel_casting():
	if not is_casting:
		return
	
	print("❌ Casting cancelled")
	casting_cancelled.emit()
	_end_casting()

func _end_casting():
	is_casting = false
	current_ability = null
	current_ability_instance = null
	caster = null
	targeting_type = TargetingType.NONE
	
	if indicator: indicator.queue_free(); indicator = null
	if range_indicator: range_indicator.queue_free(); range_indicator = null
	
	casting_finished.emit()
