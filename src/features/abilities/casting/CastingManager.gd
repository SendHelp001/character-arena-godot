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

const DECAL_SCENE_PATH = "res://src/features/abilities/casting/DecalIndicator.tscn"
const TEX_CIRCLE_PATH = "res://src/features/abilities/casting/assets/IndicatorCircle.tres"
# const TEX_ARROW_PATH = ... (Not made yet, fallback to Circle or Code)

const TERRAIN_MASK = 1 # Layer 1 for Terrain/Ground

signal casting_started(ability_name: String)
signal casting_finished()
signal casting_cancelled()

func _ready():
	process_priority = -100
	add_to_group("casting_manager")

func start_casting(ability_inst: AbilityInstance, casting_unit: Node):
	print("📥 CastingManager: start_casting requested for ", ability_inst.ability.ability_name if ability_inst and ability_inst.ability else "Unknown")
	if not ability_inst or not ability_inst.ability:
		print("❌ CastingManager: Aborting - Invalid Ability")
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
	
	var decal_scene = load(DECAL_SCENE_PATH)
	if not decal_scene:
		print("❌ CastingManager: Decal Scene not found at ", DECAL_SCENE_PATH)
		return
		
	var circle_tex = load(TEX_CIRCLE_PATH)
	
	# 1. Create Range Indicator (Ring Decal)
	if current_ability.cast_range > 0:
		range_indicator = decal_scene.instantiate()
		get_tree().root.add_child(range_indicator)
		_setup_decal(range_indicator, circle_tex, Vector3(current_ability.cast_range * 2.0, 10.0, current_ability.cast_range * 2.0))
		range_indicator.global_position = caster.global_position

	# 2. Create Targeting Indicator (Decal)
	match targeting_type:
		TargetingType.CIRCULAR, TargetingType.POINT:
			indicator = decal_scene.instantiate()
			get_tree().root.add_child(indicator)
			var size = current_ability.cast_radius * 2.0 if targeting_type == TargetingType.CIRCULAR else 2.0
			_setup_decal(indicator, circle_tex, Vector3(size, 10.0, size))
			
		TargetingType.DIRECTIONAL:
			indicator = decal_scene.instantiate()
			get_tree().root.add_child(indicator)
			# Fallback to circle if no arrow tex
			_setup_decal(indicator, circle_tex, Vector3(2.0, 10.0, current_ability.cast_range))
			
func _setup_decal(node: Node3D, texture: Texture2D, size: Vector3):
	var decal = node.get_node_or_null("Decal")
	if decal:
		decal.texture_albedo = texture
		decal.size = size

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
	# IF Mouse is captured, use screen center
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		mouse_pos = viewport.get_visible_rect().size / 2.0
	
	var origin = camera.project_ray_origin(mouse_pos)
	var direction = camera.project_ray_normal(mouse_pos)
	
	var space_state = get_tree().root.get_world_3d().direct_space_state
	var ray = PhysicsRayQueryParameters3D.new()
	ray.from = origin
	ray.to = origin + direction * 1000
	ray.collision_mask = TERRAIN_MASK # Only hit ground
	
	# Exclude caster so we don't hit ourselves inside the collision shape (especially when jumping/falling)
	if caster is CollisionObject3D:
		ray.exclude = [caster.get_rid()]
	
	var result = space_state.intersect_ray(ray)
	
	var mouse_world_pos
	if result:
		mouse_world_pos = result.position
	else:
		# Hit nothing (Air) - Project far
		mouse_world_pos = origin + direction * 1000.0
	
	var caster_pos = caster.global_position
	
	# Update Targeting Indicator
	if indicator:
		if targeting_type == TargetingType.DIRECTIONAL:
			# Directional: Anchored to caster, rotates to face mouse
			
			indicator.global_position = caster_pos
			var look_target = mouse_world_pos
			# For directional, we might want 3D or 2D? Usually ground 2D.
			# If user wants 3D directional (shooting up), we need to look_at in 3D.
			# But DirectionalProjectile usually moves flat or logic handles pitch.
			# Let's keep it flat Y for consistency unless specified.
			look_target.y = caster_pos.y 
			indicator.look_at(look_target, Vector3.UP)
			
			# Offset the decal forward by half its length so it starts at caster
			# (Decals are centered by default)
			indicator.translate_object_local(Vector3(0, 0, -current_ability.cast_range / 2.0))
			
		else:
			# Circular/Point: Follows mouse, clamped to range
			var target_pos = mouse_world_pos
			
			# For 3D Blink (Ground/Air), we normally want to clamp DISTANCE from caster.
			var to_target = target_pos - caster_pos
			# to_target.y = 0 # DISABLED Y-flattening for 3D air targeting
			
			if to_target.length() > current_ability.cast_range:
				to_target = to_target.normalized() * current_ability.cast_range
				target_pos = caster_pos + to_target
				# target_pos.y = mouse_world_pos.y # Already 3D
			
			indicator.global_position = target_pos

func _confirm_cast():
	if not is_casting:
		return
	
	var target_pos = Vector3.ZERO
	
	
	
	if targeting_type == TargetingType.DIRECTIONAL:
		if indicator:
			# Re-calculate target based on look direction
			# For 3D Aim, we should regenerate the Ray from Center if captured
			var mouse_pos = get_viewport().get_mouse_position()
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				mouse_pos = get_viewport().get_visible_rect().size / 2.0
				
			var camera = get_viewport().get_camera_3d()
			var origin = camera.project_ray_origin(mouse_pos)
			var direction = camera.project_ray_normal(mouse_pos)
			
			# Dumb directional: Just origin + direction * range ?
			# For DirectionalProjectile setup, we usually pass 'direction'.
			# But here we return a target_pos.
			# Let's ensure we return a point on the ray.
			target_pos = origin + direction * current_ability.cast_range
			
			# (If we relied on 'result' previously, we were floor-clamping)
	else:
		# Point / Circular
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
