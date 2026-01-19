extends Control

@onready var progress_bar = $ProgressBar
@onready var label = $ProgressBar/Label

var total_duration: float = 1.0

func _ready():
	hide()

func show_cast_point(ability_name: String, duration: float):
	total_duration = duration
	progress_bar.max_value = duration
	progress_bar.value = duration
	progress_bar.modulate = Color(1, 1, 1) # White for cast point
	label.text = "Casting " + ability_name
	show()

func show_channel(ability_name: String, duration: float):
	total_duration = duration
	progress_bar.max_value = duration
	progress_bar.value = duration
	progress_bar.modulate = Color(0, 0.8, 1) # Blue for channel
	label.text = "Channeling " + ability_name
	show()

func update_timer(time_remaining: float):
	progress_bar.value = time_remaining

func hide_cast():
	hide()
