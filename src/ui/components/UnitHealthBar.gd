extends Node3D

@onready var sprite_3d = $Sprite3D
@onready var sub_viewport = $SubViewport
@onready var health_bar_ui = $SubViewport/HealthBarUI

var unit: Unit
var display_timer: float = 0.0
const DISPLAY_DURATION: float = 3.0

func _ready():
	# Initial state: Hidden
	visible = false
	
	# Wait a frame for viewport to be ready if needed, 
	# then assign texture to sprite
	await get_tree().process_frame
	if sprite_3d and sub_viewport:
		sprite_3d.texture = sub_viewport.get_texture()

func setup(new_unit: Unit):
	unit = new_unit
	if unit.stats:
		unit.stats.hp_changed.connect(update_health)
		# Don't show initially, wait for damage
		# update_health(unit.stats.current_hp, unit.stats.stat_data.max_hp)

func update_health(current: float, max_hp: float):
	if health_bar_ui:
		health_bar_ui.update_health(current, max_hp)
	
	# Show on update (damage/heal)
	visible = true
	
	# Reset timer
	display_timer = DISPLAY_DURATION

func _process(delta):
	if visible:
		display_timer -= delta
		if display_timer <= 0:
			visible = false
