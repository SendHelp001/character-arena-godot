extends Unit
class_name HeroController



@export_group("Race")
@export var race_data: RaceData:
	set(value):
		race_data = value
		if is_inside_tree(): _apply_race_data()

signal dash_cooldown_updated(current_cooldown: float, max_cooldown: float)

@export_group("Movement")
@export var speed := 10.0
@export var sprint_speed := 18.0
@export var dash_impulse := 25.0 # Instant velocity burst
@export var dash_duration := 0.2 # How long friction is disabled
@export var dash_cooldown := 3.0
var dash_timer: float = 0.0
var dash_active_timer: float = 0.0

@export var jump_velocity := 12.0 # Increased from 12.0 for higher force against high gravity
@export var acceleration := 60.0
@export var friction := 50.0
@export var air_control := 0.3

@export_group("Camera")
# Camera settings moved to HeroCamera.gd
# We just hold reference for aim calculations
@onready var camera_boom := $CameraBoom # This is now HeroCamera
@onready var camera := $CameraBoom/Camera3D

var hud_scene = preload("res://src/ui/scenes/PlayerHUD.tscn")
var hud_instance = null

enum WeaponMode { GUN, SWORD }
var current_weapon: WeaponMode = WeaponMode.GUN
var sword_hitbox_size: Vector3 = Vector3(2.0, 2.0, 3.0)

# Placeholder Visuals (Created in code for now)
var gun_mesh: MeshInstance3D
var sword_mesh: MeshInstance3D

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity") * 3.0 # Tripled gravity for snappy feel

func _ready():
	super._ready() # Initialize Stats, UI, etc.
	
	# Apply Race Data if present
	if race_data:
		_apply_race_data()
	
	# Setup Camera
	if camera_boom and camera_boom.has_method("setup"):
		camera_boom.setup(self)

	# Disable standard UnitMovement if it exists
	if movement:
		movement.process_mode = Node.PROCESS_MODE_DISABLED
	
	# Capture mouse
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_create_weapon_visuals()

	# Setup HUD
	if hud_scene:
		hud_instance = hud_scene.instantiate()
		add_child(hud_instance)

	# Initial Update
	if hud_instance:
		hud_instance.update_weapon_info("Gun") # Always init to Gun
		
		# Connect Dash UI
		var dash_indicator = hud_instance.get_node_or_null("CenterContainer/DashIndicator")
		if dash_indicator:
			dash_indicator.visible = can_dash
			if can_dash:
				dash_cooldown_updated.connect(dash_indicator.update_progress)
				# Init
				dash_indicator.update_progress(0, dash_cooldown)
	
	if stats_resource:
		if stats:
			hud_instance.update_health(stats.current_hp, stats_resource.max_hp)
			
	_update_weapon_visuals()

	# Connect Health Update
	if stats:
		stats.hp_changed.connect(_on_health_changed)
		# DEBUG: Force Mana for testing
		stats.current_mana = 100
		print("🧪 DEBUG: Forced Mana to 100")
		
	print("🧪 DEBUG: Gravity: %s. Fall Gravity will be: %s" % [gravity, gravity * 2.0])
		
	# Setup Inventory UI
	if inventory:
		hud_instance.setup_inventory(inventory)
			
	# Initialize speed from stats
	if stats_resource:
		speed = stats_resource.move_speed

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

var can_glide: bool = false
var can_dash: bool = true

func _physics_process(delta):
	# Handle Gravity
	if not is_on_floor():
		var applied_gravity = gravity
		
		# Glide Logic
		if can_glide and velocity.y < 0 and Input.is_action_pressed("jump"):
			# Reduce gravity significantly for glide
			applied_gravity *= 0.1 
			# Cap falling speed
			velocity.y = max(velocity.y, -2.0)
			
		# Normal Fall
		elif velocity.y < 0:
			applied_gravity *= 2.0 # Fall 2x faster than rise
		
		velocity.y -= applied_gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get Input Direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Transform input to be relative to character rotation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# Dash Mechanics
	# Cooldown Management
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer < 0.0:
			dash_timer = 0.0
		dash_cooldown_updated.emit(dash_timer, dash_cooldown)
	
	# Dash Active Management
	if dash_active_timer > 0.0:
		dash_active_timer -= delta
		
		# End Dash
		if dash_active_timer <= 0.0:
			if camera_boom.has_method("set_dash_state"):
				camera_boom.set_dash_state(false)
		
		# While dashing, we skip normal ground movement/friction
		# We essentially preserve the current velocity (linear motion)
		# NOTE: You might want to allow *slight* air-control-like steering here?
		# For now: LOCKED TRAJECTORY (Fixed distance feel)
		
		# FIX: Disable Gravity completely during dash for straight line flight
		velocity.y = 0 
		
		move_and_slide()
		return # SKIP THE REST OF PHYSICS (Normal move logic)
		
	# Dash Input
	if can_dash and Input.is_action_just_pressed("dash") and dash_timer <= 0.0:
		# Apply Dash Impulse
		# FIX: Default forward is -transform.basis.z (Negative Z)
		var dash_dir = direction if direction else -transform.basis.z 
		velocity = dash_dir * dash_impulse 
		
		dash_timer = dash_cooldown
		dash_active_timer = dash_duration # Start friction lock
		
		# FIX: Emit signal AFTER setting timer so UI knows we are on cooldown
		dash_cooldown_updated.emit(dash_timer, dash_cooldown)
		
		if camera_boom.has_method("set_dash_state"):
			# user request: Mid-air dashes should NOT lag the camera
			if is_on_floor():
				camera_boom.set_dash_state(true)
			
		print("⚡ Dash Used!")
		
		# Execute one frame of movement immediately?
		move_and_slide()
		return

	# Ground Movement
	if direction:
		# Snappy Movement Logic
		var applied_accel = acceleration
		if is_on_floor():
			var dot = velocity.normalized().dot(direction)
			if dot < 0.8:
				applied_accel *= 8.0 
		
		velocity.x = move_toward(velocity.x, direction.x * speed, applied_accel * delta)
		velocity.z = move_toward(velocity.z, direction.z * speed, applied_accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()
	
	# Camera Logic handled by HeroCamera process (lag/follow)
	
	# Update Stats/Combat Timers
	if combat:
		combat.process_combat(delta)
	
	# Forward combat inputs
	_handle_combat_inputs()
	
	# DEBUG F5 Info
	if Input.is_action_just_pressed("f5_debug"): 
		# Toggle Debug
		if hud_instance and hud_instance.has_method("toggle_debug"):
			hud_instance.toggle_debug()
			
	if hud_instance and hud_instance.has_method("update_debug_info"):
		var cam_angle = 0.0
		if camera_boom and camera_boom.has_method("get_camera_angle"):
			cam_angle = camera_boom.get_camera_angle()
		
		var horiz_speed = Vector3(velocity.x, 0, velocity.z).length()
		hud_instance.update_debug_info(horiz_speed, cam_angle)

func _handle_combat_inputs():
	# Check if Casting (Targeting Mode)
	var casting_mgr = get_tree().get_first_node_in_group("casting_manager")
	if casting_mgr and casting_mgr.is_casting:
		return

	# Check if Casting (Ability Windup/Channel) - Prevents cancelling ability with attack
	if abilities and abilities.is_any_ability_casting():
		return

	# Left Click: Attack (Gun or Sword)
	if Input.is_action_pressed("fire"):
		if combat:
			var origin = global_position + Vector3(0, 1.5, 0) # Default Head
			
			# Use Actual Muzzle Position if visual exists
			if current_weapon == WeaponMode.GUN and gun_mesh:
				# Use forward face of the box? 
				# Gun is at local (0.6, 1.0, -0.5). Box is 0.5 long. Muzzle is roughly -0.75?
				# Let's just use the mesh origin for now, or to_global offset
				origin = gun_mesh.global_position
				
			elif current_weapon == WeaponMode.SWORD and sword_mesh:
				origin = sword_mesh.global_position

			var aim_target = _get_camera_aim_point()
			var aim_dir = (aim_target - origin).normalized()
			
			if current_weapon == WeaponMode.GUN:
				# Continuous Gun Fire
				combat.execute_manual_attack(origin, aim_dir)
				
			elif current_weapon == WeaponMode.SWORD:
				# Melee Attack
				combat.execute_manual_melee_box(origin, aim_dir, sword_hitbox_size)
			
	# Right Click: Cast Active Ability
	if Input.is_action_just_pressed("alt_fire"): # Changed to Just Pressed strictly for toggle/cast
		print("Right Click (alt_fire) detected!")
		if abilities:
			abilities.try_cast_ability(active_slot_index)

func _swap_weapon():
	if current_weapon == WeaponMode.GUN:
		current_weapon = WeaponMode.SWORD
		print("⚔️ Swapped to SWORD")
		if hud_instance:
			hud_instance.update_weapon_info("Sword")
	else:
		current_weapon = WeaponMode.GUN
		print("🔫 Swapped to GUN")
		if hud_instance:
			hud_instance.update_weapon_info("Gun")
	
	_update_weapon_visuals()

func _get_camera_aim_point() -> Vector3:
	var viewport = get_viewport()
	var center = viewport.get_visible_rect().size / 2.0
	
	var ray_len = 1000.0
	var from = camera.project_ray_origin(center)
	var to = from + camera.project_ray_normal(center) * ray_len
	
	var space = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# Exclude self and camera parts
	var excludes = [self]
	
	query.exclude = excludes
	query.collision_mask = 1 | 4 # Landscape(1) + Enemy(4)
	
	var result = space.intersect_ray(query)
	
	if result:
		return result.position
	else:
		return to
	
	# Abilities handled via input map inside generic ability component or here

func _create_weapon_visuals():
	# Gun: Box
	gun_mesh = MeshInstance3D.new()
	var gun_box = BoxMesh.new()
	gun_box.size = Vector3(0.1, 0.1, 0.5)
	gun_mesh.mesh = gun_box
	var gun_mat = StandardMaterial3D.new()
	gun_mat.albedo_color = Color.CYAN
	gun_mesh.material_override = gun_mat
	
	# Sword: Prerism/Flat box
	sword_mesh = MeshInstance3D.new()
	var sword_box = BoxMesh.new()
	sword_box.size = Vector3(0.1, 0.5, 0.1) # Vertical blade look? Or forward
	sword_box.size = Vector3(0.1, 0.05, 1.2) # Long blade forward
	sword_mesh.mesh = sword_box
	var sword_mat = StandardMaterial3D.new()
	sword_mat.albedo_color = Color.ORANGE
	sword_mesh.material_override = sword_mat
	
	# Attach to Character Root (TPS/Brawler style)
	# Ideally attach to a BoneAttachment3D if using a skeleton.
	# For now, just offset from root.
	add_child(gun_mesh)
	add_child(sword_mesh)
	
	# Offset positions (Right hand side of character)
	# Assuming character faces -Z, Right is +X
	gun_mesh.position = Vector3(0.6, 1.0, -0.5)
	sword_mesh.position = Vector3(0.6, 1.0, -0.5)
		
func _update_weapon_visuals():
	if gun_mesh: gun_mesh.visible = (current_weapon == WeaponMode.GUN)
	if sword_mesh: sword_mesh.visible = (current_weapon == WeaponMode.SWORD)

func _apply_race_data():
	if not race_data: return
	
	print("🧬 Applying Race: %s" % race_data.display_name)
	
	# Apply Physics
	jump_velocity = race_data.jump_velocity
	air_control = race_data.air_control
	can_glide = race_data.can_glide
	can_dash = race_data.can_dash
	
	# Recalculate Gravity
	var base_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
	gravity = base_gravity * 3.0 * race_data.gravity_multiplier
	
	# Apply Stats to base stats
	if race_data.base_stats_template:
		# Copy race stats to runtime variables
		speed = race_data.base_stats_template.move_speed
		
		# If we have a Stats component, override limits
		if stats:
			# Note: We probably shouldn't fully overwrite stats if they scale, 
			# but for initialization this sets the baseline.
			stats.stat_data = race_data.base_stats_template
			stats._ready() # Re-init HP/Mana from new template
