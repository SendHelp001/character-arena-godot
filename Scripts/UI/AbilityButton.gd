extends Button

# Child Nodes
@onready var cooldown_overlay = $CooldownOverlay
@onready var cooldown_label = $CooldownLabel
@onready var hotkey_label = $HotkeyLabel
@onready var mana_label = $ManaLabel

var ability_instance: AbilityInstance = null
var slot_index: int = 0

const HOTKEY_NAMES = ["Q", "W", "E", "R", "D", "F"]

func setup(ability_inst: AbilityInstance, slot: int):
	# Wait for ready so onready nodes are valid
	if not is_inside_tree():
		await ready
		
	ability_instance = ability_inst
	slot_index = slot
	
	if not ability_instance or not ability_instance.ability:
		_set_empty()
		return
	
	# Set Icon (If proper button, we use icon property. For now just text removal)
	text = "" 
	icon = ability_instance.ability.icon
	expand_icon = true
	
	# Set Hotkey
	if slot < HOTKEY_NAMES.size():
		hotkey_label.text = HOTKEY_NAMES[slot]
		# Override if ability has specific preference?
		if ability_instance.ability.suggested_hotkey != "":
			hotkey_label.text = ability_instance.ability.suggested_hotkey
	
	# Set Mana
	mana_label.text = str(ability_instance.ability.mana_cost)
	
	# Initialize cooldown state (Hidden by default)
	cooldown_overlay.visible = false
	cooldown_label.text = ""
	
	# Connect signals
	if not ability_instance.cooldown_changed.is_connected(_on_cooldown_changed):
		ability_instance.cooldown_changed.connect(_on_cooldown_changed)
	
	# Check if already on cooldown (e.g. UI recreated)
	if ability_instance.current_cooldown > 0:
		_on_cooldown_changed(ability_instance.current_cooldown, ability_instance.ability.cooldown)
	
	_update_state()

func _set_empty():
	text = "-"
	disabled = true
	cooldown_overlay.visible = false
	cooldown_label.text = ""
	hotkey_label.text = ""
	mana_label.text = ""

func _process(_delta):
	if ability_instance:
		_update_state()

func _update_state():
	if not ability_instance or not ability_instance.ability:
		return
	
	var stats = ability_instance.caster.get_stats() if ability_instance.caster else null
	var current_mana = stats.current_mana if stats else 0
	var has_mana = current_mana >= ability_instance.ability.mana_cost
	
	# Dim icon if no mana (but not full gray out unless CD)
	modulate = Color(0.5, 0.5, 1, 1) if not has_mana else Color.WHITE
	
	# Mana text color
	mana_label.modulate = Color.RED if not has_mana else Color.WHITE

func _on_cooldown_changed(remaining: float, _total: float):
	if remaining > 0:
		cooldown_overlay.visible = true
		cooldown_label.text = "%.1f" % remaining
		disabled = true
	else:
		cooldown_overlay.visible = false
		cooldown_label.text = ""
		disabled = false
