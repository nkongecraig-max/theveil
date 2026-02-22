extends Node2D

## TapJuice - Visual feedback when tapping interactive elements.
## Expanding rings + burst particles at tap location.

var effects: Array[Dictionary] = []

func spawn_tap(pos: Vector2, tap_color: Color = Color(1.0, 0.9, 0.5, 0.8)) -> void:
	# Ring effect
	effects.append({
		"type": "ring",
		"pos": pos,
		"radius": 8.0,
		"max_radius": 45.0,
		"alpha": 0.8,
		"color": tap_color,
		"speed": 140.0,
	})
	# Burst particles
	var count = 7
	for i in count:
		var angle = (float(i) / count) * TAU + randf_range(-0.2, 0.2)
		var spd = randf_range(70, 130)
		effects.append({
			"type": "particle",
			"pos": Vector2(pos),
			"vel": Vector2(cos(angle), sin(angle)) * spd,
			"radius": randf_range(3.0, 6.0),
			"alpha": 1.0,
			"color": tap_color.lightened(0.25),
		})
	queue_redraw()

func spawn_coin_pop(pos: Vector2) -> void:
	# Golden coin particles that float up
	for i in 5:
		var ox = randf_range(-20, 20)
		effects.append({
			"type": "coin",
			"pos": Vector2(pos.x + ox, pos.y),
			"vel": Vector2(randf_range(-15, 15), randf_range(-120, -70)),
			"radius": randf_range(4.0, 7.0),
			"alpha": 1.0,
			"color": Color(1.0, 0.85, 0.2),
		})
	queue_redraw()

func spawn_floating_text(pos: Vector2, text: String, color: Color = Color(1.0, 0.9, 0.3)) -> void:
	# Floating text that pops up, scales, then fades out
	effects.append({
		"type": "text",
		"pos": Vector2(pos),
		"vel": Vector2(randf_range(-10, 10), -80),
		"alpha": 1.0,
		"color": color,
		"text": text,
		"scale": 0.5,
		"age": 0.0,
	})
	queue_redraw()

func spawn_streak_flash(pos: Vector2, streak: int) -> void:
	# Big dramatic streak text with expanding ring
	var streak_color = Color(1.0, 0.5, 0.1) if streak < 3 else Color(1.0, 0.2, 0.4)
	if streak >= 5:
		streak_color = Color(0.9, 0.2, 1.0)
	effects.append({
		"type": "text",
		"pos": Vector2(pos.x, pos.y - 40),
		"vel": Vector2(0, -60),
		"alpha": 1.0,
		"color": streak_color,
		"text": "%dx STREAK!" % streak,
		"scale": 0.3,
		"age": 0.0,
	})
	# Big ring burst
	effects.append({
		"type": "ring",
		"pos": pos,
		"radius": 15.0,
		"max_radius": 120.0,
		"alpha": 0.9,
		"color": streak_color,
		"speed": 250.0,
	})
	queue_redraw()

func _process(delta: float) -> void:
	if effects.is_empty():
		return
	var to_remove: Array[int] = []
	for i in effects.size():
		var e = effects[i]
		match e["type"]:
			"ring":
				e["radius"] += e["speed"] * delta
				e["alpha"] -= delta * 2.5
				if e["alpha"] <= 0 or e["radius"] >= e["max_radius"]:
					to_remove.append(i)
			"particle":
				e["pos"] += e["vel"] * delta
				e["vel"] *= 0.90
				e["alpha"] -= delta * 3.0
				if e["alpha"] <= 0:
					to_remove.append(i)
			"coin":
				e["pos"] += e["vel"] * delta
				e["vel"].y += 80.0 * delta  # gravity
				e["alpha"] -= delta * 1.5
				if e["alpha"] <= 0:
					to_remove.append(i)
			"text":
				e["age"] += delta
				e["pos"] += e["vel"] * delta
				e["vel"] *= 0.96
				# Scale up quickly then hold
				if e["age"] < 0.15:
					e["scale"] = lerpf(0.3, 1.2, e["age"] / 0.15)
				elif e["age"] < 0.3:
					e["scale"] = lerpf(1.2, 1.0, (e["age"] - 0.15) / 0.15)
				else:
					e["scale"] = 1.0
				# Fade after 1 second
				if e["age"] > 1.0:
					e["alpha"] -= delta * 2.5
				if e["alpha"] <= 0:
					to_remove.append(i)
	to_remove.reverse()
	for idx in to_remove:
		effects.remove_at(idx)
	queue_redraw()

func _draw() -> void:
	var font = ThemeDB.fallback_font
	for e in effects:
		var c: Color = e["color"]
		c.a = maxf(e["alpha"], 0.0)
		match e["type"]:
			"ring":
				draw_arc(e["pos"], e["radius"], 0, TAU, 24, c, 3.0)
			"particle":
				draw_circle(e["pos"], e["radius"] * maxf(e["alpha"], 0.1), c)
			"coin":
				# Small golden circle with dark outline
				var r: float = e["radius"]
				draw_circle(e["pos"], r + 1, Color(0.4, 0.3, 0.1, c.a))
				draw_circle(e["pos"], r, c)
			"text":
				if font:
					var txt: String = e["text"]
					var s: float = e.get("scale", 1.0)
					var fsize = int(32 * s)
					if fsize < 8:
						fsize = 8
					var text_size = font.get_string_size(txt, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize)
					var pos: Vector2 = e["pos"]
					# Dark outline for readability
					var outline_c = Color(0, 0, 0, c.a * 0.7)
					for ox in [-2, 0, 2]:
						for oy in [-2, 0, 2]:
							if ox != 0 or oy != 0:
								draw_string(font, pos + Vector2(ox - text_size.x / 2, oy), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, outline_c)
					draw_string(font, pos + Vector2(-text_size.x / 2, 0), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, c)
