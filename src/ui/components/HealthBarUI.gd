extends Control

@onready var progress_bar = $ProgressBar

func update_health(current: float, max_hp: float):
	if progress_bar:
		progress_bar.max_value = max_hp
		progress_bar.value = current
		
		# Optional: Color coding
		var percent = current / max_hp
		var style = progress_bar.get_theme_stylebox("fill")
		# Changing stylebox resource directly might affect all instances if not careful,
		# but for unique instances it's okay, or use modulate.
		
		if percent < 0.3:
			progress_bar.modulate = Color(1, 0.2, 0.2)
		elif percent < 0.6:
			progress_bar.modulate = Color(1, 1, 0.2)
		else:
			progress_bar.modulate = Color(0.2, 1, 0.2)
