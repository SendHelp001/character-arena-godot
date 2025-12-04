extends Resource
class_name Ability

# Visual & Info
@export var ability_name: String = "Unnamed Ability"
@export var description: String = "No description"
@export var icon: Texture2D = null

# Stats
@export var cooldown: float = 5.0
@export var mana_cost: float = 50.0
@export var max_level: int = 4
@export var cast_range: float = 0.0  # 0 = self-cast

# Hotkey hint (for UI display, actual binding handled by component)
@export_enum("Q", "W", "E", "R", "D", "F") var suggested_hotkey: String = "Q"

# Virtual method - override in derived ability scripts
func _cast(caster: Node, target_pos: Vector3, level: int) -> bool:
	push_warning("Ability._cast() not implemented for: " + ability_name)
	return false

# Can this ability be cast? (override for custom conditions)
func can_cast(caster: Node, level: int) -> bool:
	if not caster.has_method("get_stats"):
		return false
	
	var stats = caster.get_stats()
	if not stats:
		return false
	
	# Check mana
	if stats.current_mana < mana_cost:
		return false
	
	return true
