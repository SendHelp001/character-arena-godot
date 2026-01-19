extends Resource
class_name Artifact

@export_group("Visuals")
@export var name: String = "Artifact Name"
@export var icon: Texture2D
@export_multiline var description: String = "Artifact Description"

@export_group("Mechanics")
## The ability resource to grant when equipped.
@export var granted_ability: Ability 
## Stats to modify when equipped (e.g. {"move_speed": 50, "max_hp": 100})
@export var stat_modifiers: Dictionary = {}

@export_group("Inventory")
## Unique ID for save systems
@export var id: String = ""
@export var gold_value: int = 100
