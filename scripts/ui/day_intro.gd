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

func set_hints_visible(vis: bool) -> void:
	for hint in _active_hints:
		if is_instance_valid(hint):
			hint.visible = vis

func _create_hint_bubble(text: String, pos: Vector2, arrow_dir: String) -> Control:
	var container = Control.new()
	container.position = pos
	container.size = Vector2(300, 72)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Shadow layer
	var shadow = ColorRect.new()
	shadow.position = Vector2(4, 4)
	shadow.size = Vector2(300, 72)
	shadow.color = Color(0, 0, 0, 0.35)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(shadow)

	# Background panel
	var bg = ColorRect.new()
	bg.position = Vector2(0, 0)
	bg.size = Vector2(300, 72)
	bg.color = Color(0.1, 0.08, 0.14, 0.93)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(bg)

	# Top highlight strip
	var top_hl = ColorRect.new()
	top_hl.position = Vector2(0, 0)
	top_hl.size = Vector2(300, 1)
	top_hl.color = Color(1, 1, 1, 0.1)
	top_hl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(top_hl)

	# Colored icon panel on left — varies by hint type
	var icon_color: Color
	var icon_char: String
	match arrow_dir:
		"down":
			icon_color = Color(0.2, 0.55, 0.9, 0.35)
			icon_char = "\ud83e\udd77"
		"up":
			icon_color = Color(0.9, 0.55, 0.15, 0.35)
			icon_char = "\ud83e\udd77"
		_:
			icon_color = Color(0.3, 0.75, 0.4, 0.35)
			icon_char = "\ud83e\udd77"
	var icon_bg = ColorRect.new()
	icon_bg.position = Vector2(0, 0)
	icon_bg.size = Vector2(48, 72)
	icon_bg.color = icon_color
	icon_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon_bg)

	# Icon symbol
	var icon = Label.new()
	icon.text = icon_char
	icon.add_theme_font_size_override("font_size", 30)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	icon.position = Vector2(4, 10)
	icon.size = Vector2(40, 52)
	icon.modulate = Color(1.0, 0.95, 0.85)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(icon)

	# Gold accent bar (bottom)
	var accent = ColorRect.new()
	accent.position = Vector2(0, 68)
	accent.size = Vector2(300, 4)
	accent.color = Color(1.0, 0.75, 0.2)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(accent)

	# Text
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(56, 8)
	label.size = Vector2(234, 56)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.modulate = Color(1.0, 0.96, 0.88)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(label)

	# Arrow pointer — triangular (stacked rects)
	var arrow_color = Color(1.0, 0.75, 0.2)
	match arrow_dir:
		"down":
			for i in 4:
				var aw = 20 - i * 5
				var ar = ColorRect.new()
				ar.position = Vector2(150 - aw / 2, 70 + i * 4)
				ar.size = Vector2(aw, 4)
				ar.color = arrow_color
				ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				container.add_child(ar)
		"up":
			for i in 4:
				var aw = 20 - i * 5
				var ar = ColorRect.new()
				ar.position = Vector2(150 - aw / 2, -4 - i * 4)
				ar.size = Vector2(aw, 4)
				ar.color = arrow_color
				ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				container.add_child(ar)
		"left":
			for i in 4:
				var ah = 18 - i * 4
				var ar = ColorRect.new()
				ar.position = Vector2(-4 - i * 4, 36 - ah / 2)
				ar.size = Vector2(4, ah)
				ar.color = arrow_color
				ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				container.add_child(ar)
		"right":
			for i in 4:
				var ah = 18 - i * 4
				var ar = ColorRect.new()
				ar.position = Vector2(300 + i * 4, 36 - ah / 2)
				ar.size = Vector2(4, ah)
				ar.color = arrow_color
				ar.mouse_filter = Control.MOUSE_FILTER_IGNORE
				container.add_child(ar)

	return container

func _process(delta: float) -> void:
	_pulse_time += delta
	# Gentle pulse on active hints
	for hint in _active_hints:
		if is_instance_valid(hint):
			var pulse = 0.85 + 0.15 * sin(_pulse_time * 2.5)
			hint.modulate.a = pulse
