extends Button

var ability_instance: AbilityInstance = null
var slot_index: int = 0

const HOTKEY_NAMES = ["Q", "W", "E", "R", "D", "F"]

func setup(ability_inst: AbilityInstance, slot: int):
	ability_instance = ability_inst
	slot_index = slot
	
	if not ability_instance or not ability_instance.ability:
		text = "-"
		disabled = true
		return
	
	# Set basic text and hotkey
	text = ability_instance.ability.ability_name.substr(0, 1)
	
	# Connect to cooldown signal
	if not ability_instance.cooldown_changed.is_connected(_on_cooldown_changed):
		ability_instance.cooldown_changed.connect(_on_cooldown_changed)
	
	_update_state()

func _process(_delta):
	if ability_instance:
		_update_state()

func _update_state():
	if not ability_instance or not ability_instance.ability:
		return
	
	# Check if can cast
	var can_cast = ability_instance.can_cast()
	disabled = not can_cast
	
	# Gray out if can't cast
	modulate = Color.WHITE if can_cast else Color(0.5, 0.5, 0.5, 1.0)

func _on_cooldown_changed(remaining: float, _total: float):
	if not ability_instance:
		return
		
	if remaining > 0:
		text = "%.1f" % remaining
	else:
		text = ability_instance.ability.ability_name.substr(0, 1)
