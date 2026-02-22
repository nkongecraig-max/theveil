extends Control

## SplashScreen - Animated title card shown on launch.
## Fades in the title, shows loading, transitions to main menu.

func _ready() -> void:
	# Block input during splash
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dimmer
	var bg = ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.color = Color(0.06, 0.05, 0.08)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# Warm gradient overlay
	var glow = ColorRect.new()
	glow.anchors_preset = Control.PRESET_FULL_RECT
	glow.color = Color(0.4, 0.25, 0.15, 0.15)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	# Title
	var title = Label.new()
	title.text = "THE VEIL"
	title.add_theme_font_size_override("font_size", 80)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.position = Vector2(60, 480)
	title.size = Vector2(600, 100)
	title.modulate = Color(1.0, 0.92, 0.7, 0.0)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(title)

	# Subtitle
	var sub = Label.new()
	sub.text = "A Ni Biashara Game"
	sub.add_theme_font_size_override("font_size", 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sub.position = Vector2(160, 580)
	sub.size = Vector2(400, 40)
	sub.modulate = Color(0.8, 0.75, 0.65, 0.0)
	sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sub)

	# Version
	var ver = Label.new()
	ver.text = "v0.1.0"
	ver.add_theme_font_size_override("font_size", 18)
	ver.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ver.position = Vector2(280, 1220)
	ver.size = Vector2(160, 30)
	ver.modulate = Color(0.5, 0.48, 0.4, 0.0)
	ver.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ver)

	# Animate in
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.8).set_delay(0.3)
	tween.tween_property(sub, "modulate:a", 0.8, 0.5)
	tween.tween_property(ver, "modulate:a", 0.5, 0.3)
	tween.tween_interval(1.5)
	# Fade out all
	tween.tween_callback(func():
		var fade = create_tween().set_parallel(true)
		fade.tween_property(title, "modulate:a", 0.0, 0.5)
		fade.tween_property(sub, "modulate:a", 0.0, 0.4)
		fade.tween_property(ver, "modulate:a", 0.0, 0.3)
		fade.tween_property(bg, "modulate:a", 0.0, 0.6)
		fade.chain().tween_callback(func():
			# Load save and go to shop (or main menu)
			SaveManager.load_game()
			GameManager.check_daily_reward()
			AudioManager.start_ambient()
			get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")
		)
	)
