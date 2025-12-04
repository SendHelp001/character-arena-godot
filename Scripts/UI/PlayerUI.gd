extends CanvasLayer

# UI Elements
@onready var hp_bar: ProgressBar = $Panel/MarginContainer/HBox/VBox/HPBar
@onready var mp_bar: ProgressBar = $Panel/MarginContainer/HBox/VBox/MPBar
@onready var portrait: TextureRect = $Panel/MarginContainer/HBox/Portrait
@onready var ability_container: HBoxContainer = $Panel/MarginContainer/HBox/VBox/AbilityContainer

# Reference to the player's unit
var tracked_unit: Unit = null

# Ability button scene (we'll create buttons dynamically)
const ABILITY_BUTTON_SCENE = preload("res://Scenes/UI/AbilityButton.tscn")

func _ready():
	# Find player's unit (assumes first selected friendly unit)
	# In a real game, you'd have a proper player controller
	pass

func track_unit(unit: Unit):
	tracked_unit = unit
	_update_ability_buttons()

func _process(_delta):
	if tracked_unit and is_instance_valid(tracked_unit):
		_update_bars()

func _update_bars():
	var stats = tracked_unit.get_stats()
	if not stats or not stats.stat_data:
		return
	
	# Update HP bar
	hp_bar.max_value = stats.stat_data.max_hp
	hp_bar.value = stats.current_hp
	
	# Update MP bar
	mp_bar.max_value = stats.stat_data.mana
	mp_bar.value = stats.current_mana

func _update_ability_buttons():
	# Clear existing buttons
	for child in ability_container.get_children():
		child.queue_free()
	
	if not tracked_unit:
		return
	
	var abilities_component = tracked_unit.get_abilities()
	if not abilities_component:
		return
	
	# Create button for each ability slot
	for i in range(6):
		var ability_instance = abilities_component.get_ability(i)
		var button = ABILITY_BUTTON_SCENE.instantiate() if ABILITY_BUTTON_SCENE else Button.new()
		
		if ability_instance and ability_instance.ability:
			button.text = ability_instance.ability.ability_name[0]  # First letter
			if button.has_method("setup"):
				button.setup(ability_instance, i)
		else:
			button.text = "-"
			button.disabled = true
		
		ability_container.add_child(button)
