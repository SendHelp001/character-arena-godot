extends Control

@onready var crosshair = $CenterContainer/Crosshair
@onready var weapon_label = $MarginContainer/VBoxContainer/WeaponLabel
@onready var health_label = $MarginContainer/VBoxContainer/HealthLabel

func update_weapon_info(weapon_name: String):
	if weapon_label:
		weapon_label.text = "Weapon: %s" % weapon_name

func update_health(current: int, max_hp: int):
	if health_label:
		health_label.text = "HP: %d / %d" % [current, max_hp]
