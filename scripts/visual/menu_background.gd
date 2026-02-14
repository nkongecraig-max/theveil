extends Node2D

## MenuBackground - Atmospheric procedural background for the main menu.
## Misty, mysterious, with floating particles suggesting "the veil."

var particles: Array[Dictionary] = []
var time: float = 0.0
var veil_offset: float = 0.0

func _ready() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 99
	# Create floating particles
	for i in 40:
		particles.append({
			"x": rng.randf_range(0, 720),
			"y": rng.randf_range(0, 1280),
			"speed": rng.randf_range(5, 25),
			"size": rng.randf_range(2, 8),
			"alpha": rng.randf_range(0.05, 0.2),
			"drift": rng.randf_range(-10, 10),
			"phase": rng.randf_range(0, TAU),
		})

func _process(delta: float) -> void:
	time += delta
	veil_offset += delta * 8.0
	queue_redraw()

func _draw() -> void:
	# Deep background gradient
	var top_color = Color(0.08, 0.07, 0.12)
	var mid_color = Color(0.12, 0.1, 0.18)
	var bot_color = Color(0.15, 0.12, 0.2)
	var band_h = 1280.0 / 20.0
	for i in 20:
		var t = float(i) / 20.0
		var c: Color
		if t < 0.5:
			c = top_color.lerp(mid_color, t * 2.0)
		else:
			c = mid_color.lerp(bot_color, (t - 0.5) * 2.0)
		draw_rect(Rect2(0, i * band_h, 720, band_h + 1), c)

	# Veil layers (horizontal misty bands)
	for i in 6:
		var y = 200 + i * 150 + sin(time * 0.3 + i) * 30
		var alpha = 0.03 + sin(time * 0.5 + i * 0.8) * 0.015
		draw_rect(Rect2(-20, y, 760, 80), Color(0.6, 0.55, 0.7, alpha))

	# Floating particles
	for p in particles:
		var px = fmod(p["x"] + sin(time * 0.5 + p["phase"]) * p["drift"], 740.0)
		var py = fmod(p["y"] - time * p["speed"], 1300.0)
		if py < -10:
			py += 1300.0
		if px < -10:
			px += 740.0
		var alpha = p["alpha"] * (0.7 + sin(time * 1.5 + p["phase"]) * 0.3)
		draw_circle(Vector2(px, py), p["size"], Color(0.7, 0.65, 0.8, alpha))

	# Central glow (where title sits)
	for r in 5:
		var radius = 120 + r * 40
		var alpha = 0.025 - r * 0.004
		draw_circle(Vector2(360, 480), radius, Color(0.5, 0.45, 0.65, alpha))

	# Bottom veil curtain
	for i in 10:
		var y = 1000 + i * 28
		var alpha = 0.02 + i * 0.008
		var wave = sin(time * 0.4 + i * 0.5) * 15
		draw_rect(Rect2(-10 + wave, y, 740, 30), Color(0.08, 0.06, 0.12, alpha))
