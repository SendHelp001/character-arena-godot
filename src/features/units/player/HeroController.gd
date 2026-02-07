extends Unit
class_name HeroController



@export_group("Race")
@export var race_data: RaceData:
	set(value):
		race_data = value
		if is_inside_tree(): _apply_race_data()

signal dash_cooldown_updated(current_cooldown: float, max_cooldown: float)

@export_group("Components")
@onready var hero_movement = $HeroMovement
@onready var hero_weapons = $HeroWeapons
@onready var animation_tree = $AnimationTree
@onready var anim_state_machine = animation_tree.get("parameters/playback") if animation_tree else null

@export_group("Camera")
# Camera settings moved to HeroCamera.gd
# We just hold reference for aim calculations
@onready var camera_boom := $CameraBoom # This is now HeroCamera
@onready var camera := $CameraBoom/Camera3D

var hud_scene = preload("res://src/ui/scenes/PlayerHUD.tscn")
var hud_instance = null



func _ready():
	super._ready() # Initialize Stats, UI, etc.
	
	# Setup Components
	if hero_movement:
		hero_movement.setup(self)
	if hero_weapons:
		hero_weapons.setup(self, combat) # Pass combat component
	
	# Apply Race Data if present
	if race_data:
		_apply_race_data()
	
	# Setup Camera
	if camera_boom and camera_boom.has_method("setup"):
		camera_boom.setup(self)

	# Setup Movement View Reference
	if hero_movement:
		hero_movement.view_node = camera_boom # Movement is relative to Camera Boom
		_set_combat_mode(false) # Default to Free Movement (Out of Combat)

	# Disable standard UnitMovement if it exists
	if movement:
		movement.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	# Setup HUD
	if hud_scene:
		hud_instance = hud_scene.instantiate()
		add_child(hud_instance)

	# Initial Update
	if hud_instance:
		hud_instance.update_weapon_info("Gun") # Always init to Gun
		
		# Connect Dash UI via Movement Component Signal
		var dash_indicator = hud_instance.get_node_or_null("CenterContainer/DashIndicator")
		if dash_indicator and hero_movement:
			dash_indicator.visible = hero_movement.can_dash
			if hero_movement.can_dash:
				hero_movement.dash_cooldown_updated.connect(dash_indicator.update_progress)
				# Init
				dash_indicator.update_progress(0, hero_movement.dash_cooldown)
	
	if stats_resource:
		if stats:
			hud_instance.update_health(stats.current_hp, stats_resource.max_hp)
			
	# Connect Health Update
	if stats:
		stats.hp_changed.connect(_on_health_changed)
		# DEBUG: Force Mana for testing
		stats.current_mana = 100
		print("🧪 DEBUG: Forced Mana to 100")
		
	# Setup Inventory UI
	if inventory:
		hud_instance.setup_inventory(inventory)
			
	# Initialize speed from stats
	if stats_resource and hero_movement:
		hero_movement.speed = stats_resource.move_speed

func _on_health_changed(new_val, max_val):
	if hud_instance:
		hud_instance.update_health(new_val, max_val)

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	# Input for Slot Selection (1-4)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode >= KEY_1 and event.keycode <= KEY_4:
			var slot_idx = event.keycode - KEY_1
			_select_inventory_slot(slot_idx)
			
		# Weapon Swap (TAB)
		if event.keycode == KEY_TAB:
			_swap_weapon()

	# Combat Mode Toggle (Hold Right Click / Alt Fire)
	# REMOVED: Replaced with Automatic Combat Mode on Attack/Cast
	# if event.is_action_pressed("alt_fire"):
	# 	_set_combat_mode(true)
	# elif event.is_action_released("alt_fire"):
	# 	_set_combat_mode(false)

const COMBAT_COOLDOWN: float = 3.0
var combat_mode_timer: float = 0.0

func trigger_combat_action():
	"""
	Called by weapons/abilities when the player attacks or casts.
	Engages combat mode (Strafe) and resets the cooldown timer.
	"""
	combat_mode_timer = COMBAT_COOLDOWN
	_set_combat_mode(true)

func _set_combat_mode(is_combat: bool):
	if hero_movement:
		hero_movement.is_strafe = is_combat
	if camera_boom:
		camera_boom.is_strafe = is_combat
		
		# If entering combat mode, snap character to camera look direction immediately
		if is_combat and camera_boom:
			rotation.y = camera_boom.rotation.y

	# NOTE: Camera/Character rotation is now handled by HeroCamera._unhandled_input

var active_slot_index: int = 0

func _select_inventory_slot(index: int):
	active_slot_index = index
	if hud_instance:
		hud_instance.select_inventory_slot(index)
		hud_instance.update_active_ability_label(_get_ability_name_at(index))

func _get_ability_name_at(index: int) -> String:
	if inventory:
		var artifact = inventory.get_artifact(index)
		if artifact and artifact.granted_ability:
			# Get ability name from resource
			# Note: granted_ability is PackedScene or Ability resource? 
			# In Artifact.gd it's typed as Resource (implicitly) or Ability
			# If it's a resource, it has 'ability_name'
			if "ability_name" in artifact.granted_ability:
				return artifact.granted_ability.ability_name
			return artifact.name
	return "None"

	return "None"

func _physics_process(delta):
	# Delegate movement to component
	# Note: HeroMovement handles character.move_and_slide() internally.
	# We just ensure animations update based on the resulting velocity.
	
	# Animation Logic
	_update_animations()
	
	# Pass dash state to camera
	if camera_boom.has_method("set_dash_state") and hero_movement:
		# Use timer > 0 to determine active dash
		if is_on_floor():
			camera_boom.set_dash_state(hero_movement.dash_active_timer > 0.0)

	# Camera Logic handled by HeroCamera process (lag/follow)
	
	# Update Stats/Combat Timers
	if combat:
		combat.process_combat(delta)
		
	# Automatic Combat Mode Timer
	if combat_mode_timer > 0.0:
		combat_mode_timer -= delta
		if combat_mode_timer <= 0.0:
			_set_combat_mode(false) # Revert to Free Movement
	
	# Forward combat inputs
	if hero_weapons:
		hero_weapons.handle_input(camera, abilities)
	
	# DEBUG F5 Info
	if Input.is_action_just_pressed("f5_debug"): 
		# Toggle Debug
		if hud_instance and hud_instance.has_method("toggle_debug"):
			hud_instance.toggle_debug()
			
	if hud_instance and hud_instance.has_method("update_debug_info"):
		var cam_rot = Vector3.ZERO
		if camera_boom:
			cam_rot = camera_boom.rotation_degrees
		
		var horiz_speed = Vector3(velocity.x, 0, velocity.z).length()
		
		# Scale velocity x30 to mimic Source Engine / Deadlock numbers visually
		# 10 m/s -> 300 units/s
		var display_speed = horiz_speed * 30.0
		hud_instance.update_debug_info(display_speed, cam_rot)

func _update_animations():
	if not anim_state_machine: return
	
	var speed_xz = Vector3(velocity.x, 0, velocity.z).length()
	
	# Transition based on speed
	# Using state names from your screenshot
	if speed_xz > 0.1:
		anim_state_machine.travel("UAL1_Standard_Armature|Jog_Fwd")
	else:
		anim_state_machine.travel("UAL1_Standard_Armature|Idle")

func _swap_weapon():
	if hero_weapons:
		hero_weapons.swap_weapon()
		if hud_instance:
			# Get string from enum? Or simplify
			var mode_str = "Sword" if hero_weapons.current_weapon == hero_weapons.WeaponMode.SWORD else "Gun"
			hud_instance.update_weapon_info(mode_str)

func _get_camera_aim_point() -> Vector3:
	# Keep helper for now if needed by other systems, or delegate to Weapons
	if hero_weapons:
		return hero_weapons._get_camera_aim_point(camera)
	return global_position




func _apply_race_data():
	if not race_data: return
	
	print("🧬 Applying Race: %s" % race_data.display_name)
	
	# Apply Physics through components
	if hero_movement:
		hero_movement.jump_velocity = race_data.jump_velocity
		hero_movement.air_control = race_data.air_control
		hero_movement.can_glide = race_data.can_glide
		hero_movement.can_dash = race_data.can_dash
		
		# Recalculate Gravity
		var base_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
		hero_movement.gravity_multiplier = race_data.gravity_multiplier
	
	# Apply Stats to base stats
	if race_data.base_stats_template:
		# Copy race stats to runtime variables
		if hero_movement:
			hero_movement.speed = race_data.base_stats_template.move_speed
		
		# If we have a Stats component, override limits
		if stats:
			# Note: We probably shouldn't fully overwrite stats if they scale, 
			# but for initialization this sets the baseline.
			stats.stat_data = race_data.base_stats_template
			stats._ready() # Re-init HP/Mana from new template
