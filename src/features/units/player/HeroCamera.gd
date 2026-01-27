extends SpringArm3D
class_name HeroCamera

@export_group("Settings")
@export var mouse_sensitivity := 0.003
@export var min_pitch := -80.0
@export var max_pitch := 60.0
@export var normal_lag_speed := 200.0

@onready var camera: Camera3D = $Camera3D

var target: Node3D
var local_offset := Vector3.ZERO

var cam_pitch := 0.0
var cam_yaw := 0.0
	
var is_strafe := true

# --------------------------------------------------

func setup(t: Node3D):
	target = t
	cam_pitch = rotation.x
	cam_yaw = rotation.y
	local_offset = position
	set_as_top_level(true)

func warp_camera():
	if not target: return
	global_position = target.global_position + local_offset

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

	# Rotate horizontal offset only
	var horiz = Vector3(local_offset.x, 0, local_offset.z)
	var vert  = Vector3(0, local_offset.y, 0)
	var rotated = Basis(Vector3.UP, cam_yaw) * horiz

	var target_pos = target.global_position + rotated + vert
	
	# Fix Wall Clipping:
	# Raycast from Character Axis (origin) to the desired Offset Position (target_pos).
	# If we hit a wall, stop the camera base from entering it.
	var pivot_origin = target.global_position + vert
	target_pos = _prevent_wall_clip(pivot_origin, target_pos)

	# Use normal lag speed (if high enough, it acts as instant)
	if normal_lag_speed > 100.0:
		global_position = target_pos
	else:
		global_position = global_position.lerp(
			target_pos,
			clamp(delta * normal_lag_speed, 0.0, 1.0)
		)

func _prevent_wall_clip(from: Vector3, to: Vector3) -> Vector3:
	var space = get_world_3d().direct_space_state
	# Create ray parameters
	var query = PhysicsRayQueryParameters3D.create(from, to)
	# Set mask to collide with World/Static (Layer 1 usually, assuming default).
	# Adjust this mask if your walls act differently!
	query.collision_mask = 1 
	# Exclude target (Character) just in case
	if target is CollisionObject3D:
		query.exclude = [target.get_rid()]
	
	var result = space.intersect_ray(query)
	if result:
		# Pull back slightly (margin) to avoid near-clipping
		return result.position + (result.normal * 0.1)
	return to



	if is_strafe:
		rotation.y = target.rotation.y
		cam_yaw = rotation.y

func get_camera_angle() -> float:
	return rad_to_deg(rotation.x)
