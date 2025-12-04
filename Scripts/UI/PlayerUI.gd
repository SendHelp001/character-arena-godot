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
	# Add to group for easy access
	add_to_group("player_ui")
	# Start hidden
	visible = false

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
		# Unit has no abilities component - just show empty slots
		for i in range(6):
			var button = Button.new()
			button.text = "-"
			button.disabled = true
			button.custom_minimum_size = Vector2(48, 48)
			ability_container.add_child(button)
		return
	
	# Create button for each ability slot
	for i in range(6):
		var ability_instance = abilities_component.get_ability(i)
		var button = Button.new()
		button.custom_minimum_size = Vector2(48, 48)
		
		if ability_instance and ability_instance.ability:
			# Has an ability - set it up
			if button.has_method("setup"):
				button.set_script(load("res://Scripts/UI/AbilityButton.gd"))
				button.setup(ability_instance, i)
			else:
				button.text = ability_instance.ability.ability_name.substr(0, 1)
		else:
			# Empty slot
			button.text = "-"
			button.disabled = true
		
		ability_container.add_child(button)
