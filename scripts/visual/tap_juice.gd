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
	to_remove.reverse()
	for idx in to_remove:
		effects.remove_at(idx)
	queue_redraw()

func _draw() -> void:
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
