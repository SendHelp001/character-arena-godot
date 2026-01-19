extends Unit
class_name HeroController

# Preload some weapons for demo purposes
const WEAPON_WARRIOR = preload("res://src/items/definitions/weapon_greatsword.tres")
const WEAPON_ARCHER = preload("res://src/items/definitions/weapon_bow.tres")
const WEAPON_MAGE = preload("res://src/items/definitions/weapon_wand.tres")

@export_group("Movement")
@export var speed := 10.0
@export var sprint_speed := 18.0
@export var jump_velocity := 12.0
@export var acceleration := 60.0
@export var friction := 50.0
@export var air_control := 0.3

@export_group("Camera")
@export var mouse_sensitivity := 0.003
@export var min_pitch := -80.0
@export var max_pitch := 60.0

@onready var camera_boom := $CameraBoom
@onready var camera := $CameraBoom/Camera3D

var hud_scene = preload("res://src/ui/scenes/scenes/PlayerHUD.tscn")
var hud_instance = null

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	super._ready() # Initialize Stats, UI, etc.
	
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
		if stats_resource:
			hud_instance.update_weapon_info(stats_resource.name)
			if stats:
				hud_instance.update_health(stats.current_hp, stats_resource.max_hp)

		# Connect Health Update
		if stats:
			stats.health_changed.connect(_on_health_changed)

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

	# Weapon Swap Demo
	if event.is_action_pressed("ability_1"): # Map 1 to Greatsword
		equip_weapon(WEAPON_WARRIOR)
	if event.is_action_pressed("ability_2"): # Map 2 to Bow
		equip_weapon(WEAPON_ARCHER)
	if event.is_action_pressed("ability_3"): # Map 3 to Wand
		equip_weapon(WEAPON_MAGE)

	if event is InputEventMouseMotion:
		# Rotate Character around Y axis (Left/Right) - Aiming direction
		rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate CameraBoom around X axis (Up/Down)
		if camera_boom:
			camera_boom.rotate_x(-event.relative.y * mouse_sensitivity)
			camera_boom.rotation.x = clamp(camera_boom.rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

func _physics_process(delta):
	# Handle Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get Input Direction
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Transform input to be relative to character rotation
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var current_speed = sprint_speed if Input.is_action_pressed("dash") else speed
	
	if direction:
		velocity.x = move_toward(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = move_toward(velocity.z, direction.z * current_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	move_and_slide()
	
	# Forward combat inputs
	_handle_combat_inputs()

func _handle_combat_inputs():
	if Input.is_action_pressed("fire"):
		if combat:
			# Get Aim Direction from Camera
			var aim_dir = -camera_boom.global_transform.basis.z
			var origin = global_position + Vector3(0, 1.5, 0) # Approx shoulder/head height
			combat.execute_manual_attack(origin, aim_dir)
	
	# Abilities handled via input map inside generic ability component or here

# ------------------------------
# Weapon System
# ------------------------------
func equip_weapon(new_weapon_data: StatData):
	if not new_weapon_data: return
	
	print("Swapping weapon to: ", new_weapon_data.name)
	
	# Update Stats
	stats_resource = new_weapon_data
	if stats:
		stats.stat_data = new_weapon_data
		# Update Health? Maybe keep current percentage?
		# For now, full reset for simplicity or just max_hp update
		stats.emit_signal("max_hp_changed", new_weapon_data.max_hp)
	
	if hud_instance:
		hud_instance.update_weapon_info(new_weapon_data.name)
		if stats:
			hud_instance.update_health(stats.current_hp, new_weapon_data.max_hp)
		
	# Update Abilities
	if abilities:
		abilities.load_abilities_from_resources(new_weapon_data.abilities)
		
	# Update Combat Logic (Ranged vs Melee)
	if combat:
		# Heuristic: If range > 4, it's ranged
		combat.is_ranged = new_weapon_data.attack_range > 4.0
		# Update generic stats on combat if needed (combat pulls from stats component mostly)

