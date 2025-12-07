extends Node3D
class_name UnitHealthBar

@onready var health_bar: ProgressBar = $SubViewport/Control/VBoxContainer/HealthBar
@onready var mana_bar: ProgressBar = $SubViewport/Control/VBoxContainer/ManaBar
@onready var sprite: Sprite3D = $Sprite3D

var unit: Node = null

func _ready():
	# Set viewport texture to sprite
	sprite.texture = $SubViewport.get_texture()

func setup(unit_node: Node):
	"""Connect to unit's stat signals"""
	unit = unit_node
	
	if unit.has_method("get_stats"):
		var stats = unit.get_stats()
		if stats:
			# Connect signals
			if stats.has_signal("hp_changed"):
				stats.hp_changed.connect(_on_hp_changed)
			if stats.has_signal("mana_changed"):
				stats.mana_changed.connect(_on_mana_changed)
			
			# Initial values
			_update_health(stats.current_hp, stats.stat_data.max_hp)
			_update_mana(stats.current_mana, stats.stat_data.max_mana)

func _on_hp_changed(current: float, max_hp: float):
	_update_health(current, max_hp)

func _on_mana_changed(current: float, max_mana: float):
	_update_mana(current, max_mana)

func _update_health(current: float, max_value: float):
	if health_bar:
		health_bar.max_value = max_value
		health_bar.value = current

func _update_mana(current: float, max_value: float):
	if mana_bar:
		mana_bar.max_value = max_value
		mana_bar.value = current
