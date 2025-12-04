extends Button

var ability_instance: AbilityInstance = null
var slot_index: int = 0

@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var hotkey_label: Label = $HotkeyLabel
@onready var mana_label: Label = $ManaLabel

const HOTKEY_NAMES = ["Q", "W", "E", "R", "D", "F"]

func setup(ability_inst: AbilityInstance, slot: int):
	ability_instance = ability_inst
	slot_index = slot
	
	if ability_instance and ability_instance.ability:
		text = ability_instance.ability.ability_name.substr(0, 1)
		hotkey_label.text = HOTKEY_NAMES[slot] if slot < HOTKEY_NAMES.size() else ""
		mana_label.text = str(int(ability_instance.ability.mana_cost))
		
		# Connect to cooldown signal
		ability_instance.cooldown_changed.connect(_on_cooldown_changed)
	
	_update_state()

func _process(_delta):
	_update_state()

func _update_state():
	if not ability_instance:
		return
	
	# Update visual state
	var can_cast = ability_instance.can_cast()
	disabled = not can_cast
	modulate = Color.WHITE if can_cast else Color(0.5, 0.5, 0.5)
	
	# Update cooldown overlay
	var cd_ratio = ability_instance.get_cooldown_ratio()
	if cooldown_overlay:
		cooldown_overlay.visible = cd_ratio > 0.0
		cooldown_overlay.size.y = size.y * cd_ratio

func _on_cooldown_changed(remaining: float, _total: float):
	if remaining > 0:
		text = "%.1f" % remaining
	elif ability_instance:
		text = ability_instance.ability.ability_name.substr(0, 1)
