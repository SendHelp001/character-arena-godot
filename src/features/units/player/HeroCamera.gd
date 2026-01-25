extends SpringArm3D
class_name HeroCamera

@export_group("Settings")
@export var mouse_sensitivity := 0.003
@export var min_pitch := -80.0
@export var max_pitch := 60.0
@export var camera_offset_right := 0.8
@export var normal_lag_speed := 200.0 # High speed = Instant follow
@export var dash_lag_speed := 8.0   # Low speed = Drag effect

var _current_lag_speed: float = 40.0
var _is_dashing: bool = false
var _post_dash_grace_timer: float = 0.0

@onready var camera: Camera3D = $Camera3D

var _target: Node3D = null
var _local_offset: Vector3 = Vector3.ZERO

func setup(target: Node3D):
	_target = target
	
	# Capture the initial local position relative to parent (Hero) BEFORE detaching
	_local_offset = position
	_current_lag_speed = normal_lag_speed
	
	# Detach to allow smooth following
	set_as_top_level(true)
	
	# Apply Offset to Camera child
	if camera:
		camera.position.x = camera_offset_right

func set_dash_state(is_dashing: bool):
	_is_dashing = is_dashing
	if _is_dashing:
		_current_lag_speed = dash_lag_speed
	# No else needed, we just switch target speed in process

func warp_camera():
	"""
	Instantly snaps the camera to the target position, bypassing lag.
	Call this after teleporting/blinking the character.
	"""
	if _target:
		var target_pos = _target.to_global(_local_offset)
		global_position = target_pos
		# Also reset internal smoothing states if we had any velocity-based lag
		_current_lag_speed = normal_lag_speed

func _unhandled_input(event):
	if not _target: return
	
	if event is InputEventMouseMotion:
		# Rotate Target (Character) Yaw
		_target.rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate Boom Pitch
		# FIX: Use Euler addition instead of rotate_x ensures we don't introduce Roll (Z-axis drift)
		rotation.x -= event.relative.y * mouse_sensitivity
		rotation.x = clamp(rotation.x, deg_to_rad(min_pitch), deg_to_rad(max_pitch))
		
func _process(delta):
	if not _target: return
	
	# Determine Target Lag Speed
	var target_speed = normal_lag_speed
	
	if _is_dashing:
		target_speed = dash_lag_speed
		_current_lag_speed = dash_lag_speed # Instant loosen on dash start
	
	# Smoothly transition current speed to target
	_current_lag_speed = lerp(_current_lag_speed, target_speed, delta * 3.0)
	
	# Follow Target Position with Lag
	var target_pos = _target.to_global(_local_offset)
	var dist = global_position.distance_to(target_pos)
	
	# Update grace timer
	if _post_dash_grace_timer > 0.0:
		_post_dash_grace_timer -= delta
	
	var final_speed = _current_lag_speed
	
	# Hard Stick Logic (Visual Frame):
	# If we are effective "instant" (high speed), snap directly to target to avoid ANY floating offset or jitter.
	if final_speed > 100.0:
		global_position = target_pos
		_current_lag_speed = target_speed # Keep internal state synced
	else:
		# Use lerp for smoothing (Dashing)
		var t = clamp(delta * final_speed, 0.0, 1.0)
		global_position = global_position.lerp(target_pos, t)
	
	# Sync Yaw with Target exactly
	rotation.y = _target.rotation.y
# 	
# 	# Debug Info (can be accessed by Controller)
	
func get_camera_angle() -> float:
	return rad_to_deg(rotation.x)
