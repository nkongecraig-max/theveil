extends Control

## MenuBackground - Atmospheric procedural background for the main menu.
## Uses Control (not Node2D) since it's parented under a Control tree.

var particles: Array[Dictionary] = []
var time: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	for i in 30:
		particles.append({
			"x": rng.randf_range(0, 720),
			"y": rng.randf_range(0, 1280),
			"speed": rng.randf_range(5, 20),
			"size": rng.randf_range(2, 6),
			"alpha": rng.randf_range(0.05, 0.15),
			"drift": rng.randf_range(-8, 8),
			"phase": rng.randf_range(0, TAU),
		})

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	# Background gradient
	var top_color = Color(0.08, 0.07, 0.12)
	var mid_color = Color(0.12, 0.1, 0.18)
	var bot_color = Color(0.15, 0.12, 0.2)
	var band_h = 1280.0 / 16.0
	for i in 16:
		var t = float(i) / 16.0
		var c: Color
		if t < 0.5:
			c = top_color.lerp(mid_color, t * 2.0)
		else:
			c = mid_color.lerp(bot_color, (t - 0.5) * 2.0)
		draw_rect(Rect2(0, i * band_h, 720, band_h + 1), c)

	# Misty veil bands
	for i in 5:
		var y = 200 + i * 180 + sin(time * 0.3 + i) * 25
		var alpha = 0.03 + sin(time * 0.5 + i * 0.8) * 0.015
		draw_rect(Rect2(0, y, 720, 60), Color(0.6, 0.55, 0.7, alpha))

	# Floating particles
	for p in particles:
		var px = fmod(p["x"] + sin(time * 0.5 + p["phase"]) * p["drift"], 720.0)
		var py = fmod(p["y"] - time * p["speed"], 1280.0)
		if py < 0:
			py += 1280.0
		if px < 0:
			px += 720.0
		var alpha = p["alpha"] * (0.7 + sin(time * 1.5 + p["phase"]) * 0.3)
		draw_circle(Vector2(px, py), p["size"], Color(0.7, 0.65, 0.8, alpha))

	# Central soft glow
	for r in 4:
		var radius = 80.0 + r * 30.0
		var alpha = 0.02 - r * 0.004
		if alpha > 0:
			draw_circle(Vector2(360, 480), radius, Color(0.5, 0.45, 0.65, alpha))

	# Bottom fade
	for i in 8:
		var y = 1020 + i * 32
		var alpha = 0.02 + i * 0.006
		draw_rect(Rect2(0, y, 720, 34), Color(0.08, 0.06, 0.12, alpha))
