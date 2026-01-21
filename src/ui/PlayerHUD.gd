extends Control

@onready var crosshair = $CenterContainer/Crosshair
@onready var container = $MarginContainer/VBoxContainer
@onready var weapon_label = $MarginContainer/VBoxContainer/WeaponLabel if has_node("MarginContainer/VBoxContainer/WeaponLabel") else null
@onready var health_label = $MarginContainer/VBoxContainer/HealthLabel
@onready var active_ability_label = $MarginContainer/VBoxContainer/ActiveAbilityLabel
@onready var inventory_ui = $InventoryUI

# Weapon Wheel Scene
const WEAPON_WHEEL_SCENE = preload("res://src/ui/scenes/WeaponWheel.tscn")
var weapon_wheel_instance: Control

@onready var fps_label = $FPSLabel if has_node("FPSLabel") else null

func _ready():
	_create_weapon_ui()

func _process(_delta):
	if fps_label:
		fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

func _create_weapon_ui():
	# Instantiate Scene
	weapon_wheel_instance = WEAPON_WHEEL_SCENE.instantiate()
	add_child(weapon_wheel_instance)
	
	# Scene is already configured with Anchors in the .tscn
	# But we might need to ensure it's positioned correctly relative to HUD logic if needed.
	# The .tscn has anchors for Left Center.

func update_weapon_info(weapon_name: String):
	# Update Weapon Wheel
	if weapon_wheel_instance and weapon_wheel_instance.has_method("update_weapon"):
		weapon_wheel_instance.update_weapon(weapon_name)
			
	# Update Old Label (if exists)
	if weapon_label:
		weapon_label.text = "Weapon: %s" % weapon_name

func update_health(current: int, max_hp: int):
	if health_label:
		health_label.text = "HP: %d / %d" % [current, max_hp]

func update_active_ability_label(ability_name: String):
	if active_ability_label:
		active_ability_label.text = "Active: " + ability_name

# Debug UI
var debug_visible: bool = false
var debug_label: Label = null

func toggle_debug():
	debug_visible = !debug_visible
	if debug_label:
		debug_label.visible = debug_visible

func update_debug_info(velocity: float, angle: float):
	if not debug_visible: return
	
	if not debug_label:
		debug_label = Label.new()
		debug_label.name = "DebugLabel"
		debug_label.position = Vector2(10, 200)
		add_child(debug_label)
		
	debug_label.text = "Vel: %.1f\nCam Angle: %.1f" % [velocity, angle]

func setup_inventory(inventory: UnitInventory):
	if inventory_ui:
		inventory_ui.setup(inventory)

func select_inventory_slot(index: int):
	if inventory_ui:
		inventory_ui.select_slot(index)
