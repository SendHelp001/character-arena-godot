extends Control

@onready var crosshair = $CenterContainer/Crosshair
@onready var weapon_label = $MarginContainer/VBoxContainer/WeaponLabel
@onready var health_label = $MarginContainer/VBoxContainer/HealthLabel
@onready var active_ability_label = $MarginContainer/VBoxContainer/ActiveAbilityLabel
@onready var inventory_ui = $InventoryUI

func update_active_ability_label(ability_name: String):
	if active_ability_label:
		active_ability_label.text = "Active: " + ability_name

func setup_inventory(inventory: UnitInventory):
	if inventory_ui:
		inventory_ui.setup(inventory)

func select_inventory_slot(index: int):
	if inventory_ui:
		inventory_ui.select_slot(index)

func update_weapon_info(weapon_name: String):
	if weapon_label:
		weapon_label.text = "Weapon: %s" % weapon_name

func update_health(current: int, max_hp: int):
	if health_label:
		health_label.text = "HP: %d / %d" % [current, max_hp]
