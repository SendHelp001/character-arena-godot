extends Resource
class_name StatData

# Allow editing in the inspector
@export var name: String = "Unit"
@export var max_hp: int = 100
@export var move_speed: float = 5.0
@export var attack_damage: int = 10
@export var attack_range: float = 2.5
@export var attack_cooldown: float = 1.0
@export var attack_point: float = 0.3    # Windup time before damage (seconds)
@export var armor: float = 0.0
@export var mana: int = 0
@export var mana_regen: float = 0
@export var abilities: Array[Resource] = []  # Array of Ability resources
@export var gold_worth: int = 0
