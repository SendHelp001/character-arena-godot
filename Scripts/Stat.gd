extends Node
class_name Stats

@export var stat_data: StatData

var current_hp: int
var current_mana: float

func _ready():
	if stat_data:
		current_hp = stat_data.max_hp
		current_mana = stat_data.mana
	else:
		push_warning("No StatData assigned!")

func take_damage(amount: float):
	# Reduce damage by armor
	var effective_damage = max(0.0, amount - (stat_data.armor if stat_data else 0.0))
	current_hp -= int(effective_damage)
	if current_hp <= 0:
		die()

func die():
	if is_inside_tree():
		queue_free()

func heal(amount: float):
	current_hp = min(stat_data.max_hp, current_hp + amount) if stat_data else current_hp

func spend_mana(amount: float) -> bool:
	if current_mana >= amount:
		current_mana -= amount
		return true
	return false

func regen_mana(delta: float):
	if stat_data:
		current_mana = min(stat_data.mana, current_mana + stat_data.mana_regen * delta)
