extends Control

@onready var primary_circle = $PrimaryCircle
@onready var secondary_circle = $SecondaryCircle
@onready var primary_label = $PrimaryCircle/Label
@onready var secondary_label = $SecondaryCircle/Label

# Textures (We can assign these in Editor, but for now we keep the procedural ones or load assets)
# For this refactor, I will define the textures here or expect them on the nodes.

func update_weapon(weapon_name: String):
	if weapon_name == "Gun":
		primary_label.text = "GUN"
		secondary_label.text = "SWORD"
		
		# Highlight Primary
		primary_circle.modulate = Color.WHITE
		secondary_circle.modulate = Color(1, 1, 1, 0.5)
	else:
		primary_label.text = "SWORD"
		secondary_label.text = "GUN"
		
		# Highlight Primary
		primary_circle.modulate = Color.WHITE
		secondary_circle.modulate = Color(1, 1, 1, 0.5)
