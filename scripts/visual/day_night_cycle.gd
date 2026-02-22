extends CanvasModulate

## DayNightCycle - Tints the shop based on customer progress through the day.
## Morning=warm gold, Midday=neutral, Evening=warm orange, Night=cool blue.

var current_progress: float = 0.0

# Color keyframes
var morning_color := Color(1.0, 0.95, 0.88)
var midday_color := Color(1.0, 1.0, 1.0)
var evening_color := Color(1.0, 0.88, 0.78)
var night_color := Color(0.78, 0.80, 0.95)

func set_progress(progress: float) -> void:
	var target = clampf(progress, 0.0, 1.0)
	var tween = create_tween()
	tween.tween_method(_apply_progress, current_progress, target, 1.2)
	current_progress = target

func _apply_progress(p: float) -> void:
	if p < 0.2:
		color = morning_color.lerp(midday_color, p / 0.2)
	elif p < 0.55:
		color = midday_color
	elif p < 0.8:
		color = midday_color.lerp(evening_color, (p - 0.55) / 0.25)
	else:
		color = evening_color.lerp(night_color, (p - 0.8) / 0.2)

func snap_to_morning() -> void:
	current_progress = 0.0
	color = morning_color
