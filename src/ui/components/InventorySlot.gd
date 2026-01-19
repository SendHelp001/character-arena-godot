extends Panel

@onready var label = $NameLabel
@onready var selection_border = $SelectionBorder

func update_slot(artifact: Artifact):
	if artifact:
		label.text = artifact.name
		tooltip_text = artifact.name + "\n" + artifact.description
	else:
		label.text = "Empty"
		tooltip_text = "Empty Slot"

func set_selected(is_selected: bool):
	selection_border.visible = is_selected
