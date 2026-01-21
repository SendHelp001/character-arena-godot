extends SpringArm3D
class_name HeroCamera

@export_group("Settings")
@export var mouse_sensitivity := 0.003
@export var min_pitch := -80.0
@export var max_pitch := 60.0
@export var camera_offset_right := 0.8
@export var normal_lag_speed := 40.0 # High speed = Almost instant
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
		
		# Force Z to 0 to prevent any skewing
		rotation.z = 0

func _physics_process(delta):
	if not _target: return
	
	# Determine Target Lag Speed
	var target_speed = normal_lag_speed
	
	if _is_dashing:
		target_speed = dash_lag_speed
		_current_lag_speed = dash_lag_speed # Instant loosen on dash start
	
	# Smoothly transition current speed to target
	# This prevents the "Snap" when recovery ends and target jumps 8 -> 40
	_current_lag_speed = lerp(_current_lag_speed, target_speed, delta * 3.0)
	
	# Follow Target Position with Lag
	var target_pos = _target.to_global(_local_offset)
	var dist = global_position.distance_to(target_pos)
	
	# Update grace timer
	if _post_dash_grace_timer > 0.0:
		_post_dash_grace_timer -= delta
	
	# Rubber Banding:
	# If camera falls too far behind (e.g. Moving + Dashing), boost speed to catch up.
	# "Dash from standstill" usually creates ~2-3m gap. "Move + Dash" creates >4m.
	var max_lag_dist = 2.5 # Threshold where we start boosting
	var rubber_band_factor = 1.0
	
	# Only apply Rubber Banding if NOT dashing AND NOT in grace period.
	# When dashing, we intentionally want the camera to lag (Drag Effect).
	# Rubber banding here would fight the drag and cause jitter/glitching.
	if not _is_dashing and _post_dash_grace_timer <= 0.0 and dist > max_lag_dist:
		# Boost speed proportionally to how far we are
		# Logic: speed * (1 + excess_dist * 1.5) - Reduced from 2.0 to prevent snap
		var excess = dist - max_lag_dist
		rubber_band_factor = 1.0 + (excess * 1.5)
	
	var final_speed = _current_lag_speed * rubber_band_factor
	
	# FIX: Clamp interpolation factor to 1.0 to prevent overshoot/jitter
	# If speed is high, t > 1.0 causes the camera to fly past the target and vibrate.
	var t = clamp(delta * final_speed, 0.0, 1.0)
	
	global_position = global_position.lerp(target_pos, t)
	
	# Sync Yaw with Target exactly (since we drive Target's Yaw)
	rotation.y = _target.rotation.y
	
	# Debug Info (can be accessed by Controller)
	
func get_camera_angle() -> float:
	return rad_to_deg(rotation.x)
