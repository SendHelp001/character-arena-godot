extends Node
class_name Stats

@export var stat_data: StatData

var current_hp: float
var current_mana: float

# Signals for UI updates
signal hp_changed(current: float, max_hp: float)
signal mana_changed(current: float, max_mana: float)
signal damage_taken(amount: float, damage_type: String)
signal died()

func _ready():
	if stat_data:
		current_hp = stat_data.max_hp
		current_mana = stat_data.max_mana
	else:
		push_warning("No StatData assigned!")

func _process(delta):
	# Passive mana regeneration
	if stat_data and current_mana < stat_data.max_mana:
		current_mana = min(current_mana + stat_data.mana_regen * delta, stat_data.max_mana)
		mana_changed.emit(current_mana, stat_data.max_mana)

func take_damage(amount: float, damage_type: String = "PHYSICAL"):
	# Reduce damage by armor
	var effective_damage = max(0.0, amount - (stat_data.armor if stat_data else 0.0))
	current_hp -= effective_damage
	
	# Emit signals
	damage_taken.emit(effective_damage, damage_type)
	hp_changed.emit(current_hp, stat_data.max_hp if stat_data else 100.0)
	
	if current_hp <= 0:
		die()

func die():
	died.emit()
	if is_inside_tree():
		get_parent().queue_free()

func heal(amount: float):
	if stat_data:
		current_hp = min(stat_data.max_hp, current_hp + amount)
		hp_changed.emit(current_hp, stat_data.max_hp)

func spend_mana(amount: float) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		mana_changed.emit(current_mana, stat_data.max_mana if stat_data else 100.0)
		return true
	return false

func regen_mana(delta: float):
	if stat_data:
		current_mana = min(stat_data.max_mana, current_mana + stat_data.mana_regen * delta)
		mana_changed.emit(current_mana, stat_data.max_mana)
