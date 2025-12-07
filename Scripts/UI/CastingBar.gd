extends Control
class_name CastingBar

# UI Elements
@onready var progress_bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var label: Label = $VBoxContainer/Label
@onready var cast_name_label: Label = $VBoxContainer/CastNameLabel

# State
var is_visible_casting: bool = false
var timer: float = 0.0
var max_time: float = 1.0
var cast_type: String = ""  # "Cast Point" or "Channeling"

func _ready():
	hide()

func _process(delta):
	if is_visible_casting:
		# Update label
		label.text = "%.1f" % timer
		
		# Update progress bar
		if max_time > 0:
			progress_bar.value = (1.0 - (timer / max_time)) * 100.0

func show_cast_point(ability_name: String, duration: float):
	"""Show casting bar for cast point windup"""
	cast_type = "Cast Point"
	cast_name_label.text = ability_name
	timer = duration
	max_time = duration
	is_visible_casting = true
	show()
	
	# Green for casting
	progress_bar.modulate = Color(0.3, 1.0, 0.3)

func show_channel(ability_name: String, duration: float):
	"""Show casting bar for channeling"""
	cast_type = "Channeling"
	cast_name_label.text = ability_name + " (Channeling)"
	timer = duration
	max_time = duration
	is_visible_casting = true
	show()
	
	# Blue for channeling
	progress_bar.modulate = Color(0.3, 0.6, 1.0)

func update_timer(remaining: float):
	"""Called externally to update remaining time"""
	timer = remaining

func hide_cast():
	"""Hide the casting bar"""
	is_visible_casting = false
	hide()
