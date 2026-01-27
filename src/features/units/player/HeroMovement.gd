extends Node
class_name HeroMovement

signal dash_cooldown_updated(current_cooldown: float, max_cooldown: float)

@export_group("Movement")
@export var speed := 10.0
@export var sprint_speed := 18.0
@export var dash_impulse := 25.0
@export var dash_duration := 0.2
@export var dash_cooldown := 3.0
@export var jump_velocity := 12.0
@export var acceleration := 60.0
@export var friction := 50.0
@export var air_control := 0.3

var dash_timer: float = 0.0
var dash_active_timer: float = 0.0
var can_glide: bool = false
var can_dash: bool = true
var gravity_multiplier: float = 3.0

var character: CharacterBody3D
var base_gravity: float

func setup(p_character: CharacterBody3D):
	character = p_character
	base_gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _physics_process(delta):
	if not character: return
	
	_handle_gravity(delta)
	_handle_jump()
	_handle_dash_timers(delta)
	
	var input_velocity = _get_input_velocity(delta)
	
	if dash_active_timer > 0.0:
		# Dash overrides normal move
		_handle_dash_active(delta)
	else:
		_apply_velocity(input_velocity)
		_handle_dash_input()

	character.move_and_slide()

func _handle_gravity(delta):
	if not character.is_on_floor():
		var applied_gravity = base_gravity * gravity_multiplier
		
		# Glide
		if can_glide and character.velocity.y < 0 and Input.is_action_pressed("jump"):
			applied_gravity *= 0.1
			character.velocity.y = max(character.velocity.y, -2.0)
		# Fall
		elif character.velocity.y < 0:
			applied_gravity *= 2.0
			
		character.velocity.y -= applied_gravity * delta

func _handle_jump():
	if Input.is_action_just_pressed("jump") and character.is_on_floor():
		character.velocity.y = jump_velocity

func _handle_dash_timers(delta):
	if dash_timer > 0.0:
		dash_timer -= delta
		if dash_timer < 0.0: dash_timer = 0.0
		dash_cooldown_updated.emit(dash_timer, dash_cooldown)
		
	if dash_active_timer > 0.0:
		dash_active_timer -= delta

func _handle_dash_active(delta):
	# No gravity during dash
	character.velocity.y = 0
	# No friction/input change during dash

@export var rotation_speed := 10.0

var view_node: Node3D
var is_strafe: bool = true # Default to true for now, controlled by Controller

# ... logic updates ...

func _get_input_velocity(delta) -> Vector3:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	
	# Direction is relative to VIEW (Camera) if available, otherwise Character
	var basis_ref = view_node.transform.basis if view_node else character.transform.basis
	var direction = (basis_ref * Vector3(input_dir.x, 0, input_dir.y))
	direction.y = 0 # Flatten to plane
	direction = direction.normalized()
	
	var target_vel = character.velocity
	
	if direction:
		# Free Rotation Logic: Rotate character to face movement direction
		if not is_strafe:
			var target_anim_basis = Basis.looking_at(direction)
			var q_from = Quaternion(character.transform.basis)
			var q_to = Quaternion(target_anim_basis)
			
			# Interpolate rotation
			character.transform.basis = Basis(q_from.slerp(q_to, rotation_speed * delta))
			
			# Ensure X/Z rotation stays flat (might be handled by looking_at implicitly, but safer to force Y-axis only if needed)
			# But looking_at(dir) where dir.y=0 is usually fine for upright chars.
			
		var applied_accel = acceleration
		if character.is_on_floor():
			var dot = character.velocity.normalized().dot(direction)
			if dot < 0.8: applied_accel *= 8.0 # Snappy turn
		
		target_vel.x = move_toward(target_vel.x, direction.x * speed, applied_accel * delta)
		target_vel.z = move_toward(target_vel.z, direction.z * speed, applied_accel * delta)
	else:
		target_vel.x = move_toward(target_vel.x, 0, friction * delta)
		target_vel.z = move_toward(target_vel.z, 0, friction * delta)
		
	return target_vel

func _apply_velocity(target_vel: Vector3):
	character.velocity.x = target_vel.x
	character.velocity.z = target_vel.z

func _handle_dash_input():
	if can_dash and Input.is_action_just_pressed("dash") and dash_timer <= 0.0:
		var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		
		# FIX: Use View/Camera Basis for Dash Direction checks, same as Movement.
		# This ensures that pressing 'W' always dashes "Up" (North/Camera Forward), 
		# even if the character is facing "Down" (South/Camera Backward).
		var basis_ref = view_node.transform.basis if view_node else character.transform.basis
		var direction = (basis_ref * Vector3(input_dir.x, 0, input_dir.y))
		direction.y = 0
		direction = direction.normalized()
		
		# If no input, dash forward relative to CHARACTER facing
		var dash_dir = direction if direction else -character.transform.basis.z 
		
		character.velocity = dash_dir * dash_impulse
		dash_timer = dash_cooldown
		dash_active_timer = dash_duration
		
		dash_cooldown_updated.emit(dash_timer, dash_cooldown)
		
		# Optional: Tell camera about dash state?
		# For simplicity, we just emit, controller can handle effects
