extends Control

## DayIntro - Full-screen overlay that shows at the start of each day.
## Day 1 has special tutorial hints that guide the player.
## Fades in, holds, fades out, then triggers the day to actually start.

signal intro_finished

var _hints_shown: Dictionary = {}  # Tracks which hints have been dismissed
var _active_hints: Array[Control] = []
var _pulse_time: float = 0.0

func show_day_intro(day: int) -> void:
	visible = true
	mouse_filter = Control.MOUSE_FILTER_STOP  # Block input during intro

	# Clear any old children
	for child in get_children():
		child.queue_free()

	# Dimmer background
	var dimmer = ColorRect.new()
	dimmer.name = "Dimmer"
	dimmer.anchors_preset = Control.PRESET_FULL_RECT
	dimmer.color = Color(0.06, 0.05, 0.08, 0.85)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	# Day number - big and bold
	var day_label = Label.new()
	day_label.name = "DayNum"
	day_label.text = "Day %d" % day
	day_label.add_theme_font_size_override("font_size", 72)
	day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	day_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	day_label.anchors_preset = Control.PRESET_CENTER
	day_label.position = Vector2(360 - 200, 500)
	day_label.size = Vector2(400, 80)
	day_label.modulate = Color(1.0, 0.92, 0.7)
	add_child(day_label)

	# Subtitle
	var subtitle = Label.new()
	subtitle.name = "Subtitle"
	if day == 1:
		subtitle.text = "Welcome to your shop"
	elif day <= 3:
		subtitle.text = "Another day, another customer"
	elif day <= 7:
		subtitle.text = "Business is picking up"
	else:
		subtitle.text = "The regulars are here"
	subtitle.add_theme_font_size_override("font_size", 32)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	subtitle.position = Vector2(360 - 250, 590)
	subtitle.size = Vector2(500, 50)
	subtitle.modulate = Color(0.85, 0.82, 0.75, 0.8)
	add_child(subtitle)

	# Tip text for Day 1
	if day == 1:
		var tip = Label.new()
		tip.name = "Tip"
		tip.text = "Serve customers. Keep shelves stocked. Earn coins."
		tip.add_theme_font_size_override("font_size", 24)
		tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tip.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tip.position = Vector2(360 - 300, 660)
		tip.size = Vector2(600, 40)
		tip.modulate = Color(0.7, 0.85, 0.65, 0.9)
		add_child(tip)

	# Animate in
	dimmer.modulate.a = 0.0
	day_label.modulate.a = 0.0
	subtitle.modulate.a = 0.0
	day_label.scale = Vector2(0.6, 0.6)
	day_label.pivot_offset = day_label.size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.4)
	tween.tween_property(day_label, "modulate:a", 1.0, 0.5).set_delay(0.2)
	tween.tween_property(day_label, "scale", Vector2(1.0, 1.0), 0.4).set_delay(0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(subtitle, "modulate:a", 0.8, 0.4).set_delay(0.6)

	# Hold for 2 seconds, then fade out
	var hold_time = 2.5 if day == 1 else 1.8
	tween.chain().tween_interval(hold_time)
	# Fade out — launch a parallel tween from a callback so all three fade together
	tween.chain().tween_callback(func():
		var fade = create_tween().set_parallel(true)
		fade.tween_property(dimmer, "modulate:a", 0.0, 0.4)
		fade.tween_property(day_label, "modulate:a", 0.0, 0.3)
		fade.tween_property(subtitle, "modulate:a", 0.0, 0.3)
		fade.chain().tween_callback(func():
			visible = false
			mouse_filter = Control.MOUSE_FILTER_IGNORE
			intro_finished.emit()
		)
	)

## --- Contextual hint system (Day 1 only) ---

func show_hint(hint_id: String, text: String, world_pos: Vector2, arrow_dir: String = "down") -> void:
	if hint_id in _hints_shown:
		return
	var hint = _create_hint_bubble(text, world_pos, arrow_dir)
	hint.set_meta("hint_id", hint_id)
	_active_hints.append(hint)
	get_parent().add_child(hint)  # Add to UI layer
	# Fade in
	hint.modulate.a = 0.0
	hint.scale = Vector2(0.7, 0.7)
	hint.pivot_offset = hint.size / 2
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hint, "modulate:a", 1.0, 0.3)
	tween.tween_property(hint, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func dismiss_hint(hint_id: String) -> void:
	_hints_shown[hint_id] = true
	for hint in _active_hints:
		if hint.get_meta("hint_id", "") == hint_id:
			var tween = create_tween()
			tween.tween_property(hint, "modulate:a", 0.0, 0.25)
			tween.tween_callback(func():
				_active_hints.erase(hint)
				hint.queue_free()
			)
			return

func dismiss_all_hints() -> void:
	for hint in _active_hints:
		hint.queue_free()
	_active_hints.clear()

func has_hint(hint_id: String) -> bool:
	return hint_id in _hints_shown

func _create_hint_bubble(text: String, pos: Vector2, arrow_dir: String) -> Control:
	var container = Control.new()
	container.position = pos
	container.size = Vector2(280, 60)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Background panel
	var bg = ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(280, 60)
	bg.color = Color(0.12, 0.1, 0.15, 0.9)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# Accent border top
	var accent = ColorRect.new()
	accent.position = Vector2(0, 0)
	accent.size = Vector2(280, 3)
	accent.color = Color(1.0, 0.75, 0.2)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(accent)

	# Text
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(10, 8)
	label.size = Vector2(260, 44)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.modulate = Color(1.0, 0.95, 0.8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)

	# Arrow indicator
	var arrow = Label.new()
	arrow.add_theme_font_size_override("font_size", 28)
	arrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	arrow.modulate = Color(1.0, 0.75, 0.2)
	match arrow_dir:
		"down":
			arrow.text = "v"
			arrow.position = Vector2(120, 58)
			arrow.size = Vector2(40, 30)
		"up":
			arrow.text = "^"
			arrow.position = Vector2(120, -28)
			arrow.size = Vector2(40, 30)
		"left":
			arrow.text = "<"
			arrow.position = Vector2(-20, 15)
			arrow.size = Vector2(30, 30)
		"right":
			arrow.text = ">"
			arrow.position = Vector2(278, 15)
			arrow.size = Vector2(30, 30)
	container.add_child(arrow)

	return container

func _process(delta: float) -> void:
	_pulse_time += delta
	# Gentle pulse on active hints
	for hint in _active_hints:
		if is_instance_valid(hint):
			var pulse = 0.85 + 0.15 * sin(_pulse_time * 2.5)
			hint.modulate.a = pulse
