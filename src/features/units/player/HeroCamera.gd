extends SpringArm3D
class_name HeroCamera

@export_group("Settings")
@export var mouse_sensitivity := 0.003
@export var min_pitch := -80.0
@export var max_pitch := 60.0
@export var normal_lag_speed := 200.0
@export var dash_lag_speed := 8.0

@onready var camera: Camera3D = $Camera3D

var target: Node3D
var local_offset := Vector3.ZERO

var cam_pitch := 0.0
var cam_yaw := 0.0
var lag_speed := 0.0

var is_dashing := false
var is_strafe := true

# --------------------------------------------------

func setup(t: Node3D):
	target = t
	cam_pitch = rotation.x
	cam_yaw = rotation.y
	local_offset = position
	lag_speed = normal_lag_speed
	set_as_top_level(true)

func set_dash_state(dashing: bool):
	is_dashing = dashing
	# Don't snap speed instantly; let _process lerp it for the lag effect

func warp_camera():
	if not target: return
	global_position = target.global_position + local_offset
	lag_speed = normal_lag_speed

# --------------------------------------------------

func _unhandled_input(event):
	if not target: return
	if event is InputEventMouseMotion:
		cam_yaw -= event.relative.x * mouse_sensitivity
		cam_pitch -= event.relative.y * mouse_sensitivity
		cam_pitch = clamp(cam_pitch, deg_to_rad(min_pitch), deg_to_rad(max_pitch))

		rotation = Vector3(cam_pitch, cam_yaw, 0)

		if is_strafe:
			target.rotation.y = cam_yaw

# --------------------------------------------------

func _process(delta):
	if not target: return

	var desired_speed = dash_lag_speed if is_dashing else normal_lag_speed
	lag_speed = lerp(lag_speed, desired_speed, delta * 3.0)

	# Rotate horizontal offset only
	var horiz = Vector3(local_offset.x, 0, local_offset.z)
	var vert  = Vector3(0, local_offset.y, 0)
	var rotated = Basis(Vector3.UP, cam_yaw) * horiz

	var target_pos = target.global_position + rotated + vert

	if lag_speed > 100.0:
		global_position = target_pos
	else:
		global_position = global_position.lerp(
			target_pos,
			clamp(delta * lag_speed, 0.0, 1.0)
		)

	if is_strafe:
		rotation.y = target.rotation.y
		cam_yaw = rotation.y

func get_camera_angle() -> float:
	return rad_to_deg(rotation.x)
