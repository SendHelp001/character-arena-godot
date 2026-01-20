extends StaticBody3D

const DAMAGE_NUMBER_SCENE = preload("res://src/ui/components/DamageNumber.tscn")

@onready var label_3d = $Label3D
@onready var mesh = $MeshInstance3D

var total_damage: float = 0.0
var tracking_active: bool = false
var reset_time: float = 5.0
var current_reset_timer: float = 0.0

@export var team_id: int = 2 # 0=Player, 1=Enemy, 2=Neutral

# Optional: DPS tracking
var combat_start_time: float = 0.0

func get_team_id() -> int:
	return team_id

func _ready():
	_update_label()

func take_damage(amount: float):
	if not tracking_active:
		tracking_active = true
		combat_start_time = Time.get_ticks_msec() / 1000.0
		total_damage = 0.0
	
	total_damage += amount
	current_reset_timer = reset_time
	
	_spawn_damage_number(amount)
	_update_label()
	
	# Flash effect
	if mesh:
		var tween = create_tween()
		tween.tween_property(mesh, "scale", Vector3(1.2, 1.2, 1.2), 0.05)
		tween.tween_property(mesh, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func _process(delta):
	if tracking_active:
		curr_dps_logic(delta)
		
		# Reset timer logic
		current_reset_timer -= delta
		if current_reset_timer <= 0:
			tracking_active = false
			total_damage = 0.0
			_update_label()

func curr_dps_logic(_delta):
	# Update label every frame or so to show DPS if desired
	# For now, just ensuring reset logic works is priority.
	# But updating the label with current DPS could be nice.
	_update_label()

func _update_label():
	if not label_3d:
		return
		
	if not tracking_active:
		label_3d.text = "Dummy\n(Idle)"
		label_3d.modulate = Color.WHITE
	else:
		var current_time = Time.get_ticks_msec() / 1000.0
		var duration = max(0.1, current_time - combat_start_time)
		var dps = total_damage / duration
		
		label_3d.text = "Total: %d\nDPS: %.1f\nReset: %.1fs" % [int(total_damage), dps, current_reset_timer]
		label_3d.modulate = Color(1, 0.5, 0.5) # Reddish while active

func _spawn_damage_number(amount: float):
	if DAMAGE_NUMBER_SCENE:
		var damage_num = DAMAGE_NUMBER_SCENE.instantiate()
		get_tree().current_scene.add_child(damage_num)
		damage_num.global_position = global_position + Vector3(randf_range(-0.5, 0.5), 2.5, randf_range(-0.5, 0.5))
		damage_num.setup(amount, "PHYSICAL") # Defaulting to physical for now
