extends Control
class_name DashIndicator

@onready var progress_bar = $ForegroundBar

func update_progress(current_time: float, max_time: float):
	if not progress_bar: return
	
	# If max_time is 0, we are ready (full bar)
	if max_time <= 0:
		progress_bar.value = progress_bar.max_value
		return

	# Calculate percentage (0 to 100)
	# current_time counts DOWN from max to 0.
	# When current == max, visual should be EMPTY (0%)? Or FULL (100%)?
	# Usually cooldowns:
	# - Empty -> Fills up as cooldown expires.
	# - Remaining Time: 3.0 -> 0.0
	# - Target: 0 -> 100
	
	var percent = 1.0 - (current_time / max_time)
	progress_bar.value = percent * progress_bar.max_value
