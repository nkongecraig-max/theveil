extends Node

## DrawUtils - Shared procedural drawing helpers for The Veil's visual style.
## Cozy hand-drawn aesthetic. Warm wood, soft stone, organic shapes.

# -- Wood plank pattern --
static func draw_wood_planks(canvas: CanvasItem, rect: Rect2, base_color: Color, plank_count: int = 5, horizontal: bool = true) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = int(rect.position.x * 100 + rect.position.y)
	if horizontal:
		var plank_h = rect.size.y / plank_count
		for i in plank_count:
			var shade = rng.randf_range(-0.04, 0.04)
			var c = Color(base_color.r + shade, base_color.g + shade * 0.8, base_color.b + shade * 0.5)
			var y = rect.position.y + i * plank_h
			canvas.draw_rect(Rect2(rect.position.x, y, rect.size.x, plank_h - 1), c)
			# Grain lines
			for _g in 3:
				var gy = y + rng.randf_range(2, plank_h - 3)
				var grain_c = Color(c.r - 0.03, c.g - 0.03, c.b - 0.02, 0.4)
				canvas.draw_line(Vector2(rect.position.x + 2, gy), Vector2(rect.position.x + rect.size.x - 2, gy), grain_c, 1.0)
	else:
		var plank_w = rect.size.x / plank_count
		for i in plank_count:
			var shade = rng.randf_range(-0.04, 0.04)
			var c = Color(base_color.r + shade, base_color.g + shade * 0.8, base_color.b + shade * 0.5)
			var x = rect.position.x + i * plank_w
			canvas.draw_rect(Rect2(x, rect.position.y, plank_w - 1, rect.size.y), c)
			for _g in 3:
				var gx = x + rng.randf_range(2, plank_w - 3)
				var grain_c = Color(c.r - 0.03, c.g - 0.03, c.b - 0.02, 0.4)
				canvas.draw_line(Vector2(gx, rect.position.y + 2), Vector2(gx, rect.position.y + rect.size.y - 2), grain_c, 1.0)

# -- Stone/tile floor pattern --
static func draw_stone_floor(canvas: CanvasItem, rect: Rect2, base_color: Color, tile_size: float = 60.0) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	var cols = int(rect.size.x / tile_size) + 1
	var rows = int(rect.size.y / tile_size) + 1
	for r in rows:
		var offset = (tile_size * 0.5) if (r % 2 == 1) else 0.0
		for c in cols:
			var shade = rng.randf_range(-0.03, 0.03)
			var color = Color(base_color.r + shade, base_color.g + shade, base_color.b + shade)
			var tx = rect.position.x + c * tile_size + offset
			var ty = rect.position.y + r * tile_size
			if tx < rect.position.x + rect.size.x and ty < rect.position.y + rect.size.y:
				var tw = minf(tile_size - 2, rect.position.x + rect.size.x - tx)
				var th = minf(tile_size - 2, rect.position.y + rect.size.y - ty)
				canvas.draw_rect(Rect2(tx, ty, tw, th), color)

# -- Brick/wall pattern --
static func draw_brick_wall(canvas: CanvasItem, rect: Rect2, base_color: Color, brick_w: float = 40.0, brick_h: float = 20.0) -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 77
	var cols = int(rect.size.x / brick_w) + 2
	var rows = int(rect.size.y / brick_h) + 1
	# Mortar
	canvas.draw_rect(rect, Color(base_color.r - 0.1, base_color.g - 0.1, base_color.b - 0.08))
	for r in rows:
		var offset = (brick_w * 0.5) if (r % 2 == 1) else 0.0
		for c in cols:
			var shade = rng.randf_range(-0.03, 0.03)
			var color = Color(base_color.r + shade, base_color.g + shade * 0.8, base_color.b + shade * 0.6)
			var bx = rect.position.x + c * brick_w + offset
			var by = rect.position.y + r * brick_h
			if bx < rect.position.x + rect.size.x and by < rect.position.y + rect.size.y:
				var bw = minf(brick_w - 2, rect.position.x + rect.size.x - bx)
				var bh = minf(brick_h - 2, rect.position.y + rect.size.y - by)
				if bw > 0 and bh > 0:
					canvas.draw_rect(Rect2(bx + 1, by + 1, bw, bh), color)

# -- Shelf with items --
static func draw_shelf(canvas: CanvasItem, pos: Vector2, size: Vector2, wood_color: Color, items: Array = []) -> void:
	# Shadow
	canvas.draw_rect(Rect2(pos.x + 3, pos.y + 3, size.x, size.y), Color(0, 0, 0, 0.15))
	# Back panel
	canvas.draw_rect(Rect2(pos, size), Color(wood_color.r - 0.08, wood_color.g - 0.08, wood_color.b - 0.06))
	# Shelf boards (3 shelves)
	var board_h = 6.0
	for i in 3:
		var sy = pos.y + (i + 1) * (size.y / 4.0)
		canvas.draw_rect(Rect2(pos.x, sy - board_h / 2, size.x, board_h), wood_color)
		# Board edge highlight
		canvas.draw_line(Vector2(pos.x, sy - board_h / 2), Vector2(pos.x + size.x, sy - board_h / 2), Color(1, 1, 1, 0.15), 1.0)
	# Side trim
	canvas.draw_rect(Rect2(pos.x, pos.y, 4, size.y), wood_color.darkened(0.1))
	canvas.draw_rect(Rect2(pos.x + size.x - 4, pos.y, 4, size.y), wood_color.darkened(0.1))
	# Top trim
	canvas.draw_rect(Rect2(pos.x - 2, pos.y - 4, size.x + 4, 6), wood_color.darkened(0.05))

# -- Rounded panel (for UI) --
static func draw_rounded_panel(canvas: CanvasItem, rect: Rect2, color: Color, radius: float = 8.0) -> void:
	# Simple approximation using rects + corner circles
	canvas.draw_rect(Rect2(rect.position.x + radius, rect.position.y, rect.size.x - radius * 2, rect.size.y), color)
	canvas.draw_rect(Rect2(rect.position.x, rect.position.y + radius, rect.size.x, rect.size.y - radius * 2), color)
	canvas.draw_circle(Vector2(rect.position.x + radius, rect.position.y + radius), radius, color)
	canvas.draw_circle(Vector2(rect.position.x + rect.size.x - radius, rect.position.y + radius), radius, color)
	canvas.draw_circle(Vector2(rect.position.x + radius, rect.position.y + rect.size.y - radius), radius, color)
	canvas.draw_circle(Vector2(rect.position.x + rect.size.x - radius, rect.position.y + rect.size.y - radius), radius, color)

# -- Character body --
static func draw_character(canvas: CanvasItem, pos: Vector2, body_color: Color, hair_color: Color, size: float = 1.0) -> void:
	var s = size
	# Shadow
	draw_ellipse(canvas, Rect2(pos.x - 14 * s, pos.y + 14 * s, 28 * s, 8 * s), Color(0, 0, 0, 0.15))
	# Body
	canvas.draw_rect(Rect2(pos.x - 10 * s, pos.y - 4 * s, 20 * s, 22 * s), body_color)
	# Shirt detail
	canvas.draw_rect(Rect2(pos.x - 10 * s, pos.y - 4 * s, 20 * s, 3 * s), body_color.lightened(0.1))
	# Head
	canvas.draw_circle(pos + Vector2(0, -12 * s), 10 * s, Color(0.85, 0.72, 0.58))
	# Hair
	canvas.draw_arc(pos + Vector2(0, -16 * s), 9 * s, deg_to_rad(180), deg_to_rad(360), 12, hair_color, 4 * s)
	# Eyes
	canvas.draw_circle(pos + Vector2(-3.5 * s, -13 * s), 1.5 * s, Color(0.15, 0.12, 0.1))
	canvas.draw_circle(pos + Vector2(3.5 * s, -13 * s), 1.5 * s, Color(0.15, 0.12, 0.1))
	# Mouth (small smile)
	canvas.draw_arc(pos + Vector2(0, -8 * s), 3 * s, deg_to_rad(20), deg_to_rad(160), 6, Color(0.4, 0.25, 0.2), 1.0 * s)
	# Feet
	canvas.draw_rect(Rect2(pos.x - 8 * s, pos.y + 18 * s, 7 * s, 4 * s), Color(0.35, 0.25, 0.2))
	canvas.draw_rect(Rect2(pos.x + 1 * s, pos.y + 18 * s, 7 * s, 4 * s), Color(0.35, 0.25, 0.2))

# -- Item icon --
static func draw_item_icon(canvas: CanvasItem, pos: Vector2, item_id: String, icon_size: float = 24.0) -> void:
	var s = icon_size / 24.0
	match item_id:
		"coffee":
			# Coffee mug — deep espresso
			canvas.draw_rect(Rect2(pos.x - 7 * s, pos.y - 4 * s, 14 * s, 12 * s), Color(0.35, 0.2, 0.12))
			canvas.draw_rect(Rect2(pos.x - 5 * s, pos.y - 2 * s, 10 * s, 8 * s), Color(0.48, 0.3, 0.18))
			canvas.draw_arc(pos + Vector2(7 * s, 2 * s), 4 * s, deg_to_rad(-70), deg_to_rad(70), 6, Color(0.3, 0.18, 0.1), 2 * s)
			# Steam
			canvas.draw_arc(pos + Vector2(-2 * s, -9 * s), 3 * s, deg_to_rad(180), deg_to_rad(360), 4, Color(0.8, 0.75, 0.7, 0.5), 1 * s)
			canvas.draw_arc(pos + Vector2(2 * s, -11 * s), 2 * s, deg_to_rad(180), deg_to_rad(360), 4, Color(0.8, 0.75, 0.7, 0.4), 1 * s)
		"spices":
			# Spice jar — vivid saffron
			canvas.draw_rect(Rect2(pos.x - 6 * s, pos.y - 6 * s, 12 * s, 14 * s), Color(0.9, 0.5, 0.05))
			canvas.draw_rect(Rect2(pos.x - 5 * s, pos.y - 5 * s, 10 * s, 12 * s), Color(0.95, 0.6, 0.1))
			canvas.draw_rect(Rect2(pos.x - 7 * s, pos.y - 9 * s, 14 * s, 4 * s), Color(0.7, 0.38, 0.05))
			canvas.draw_circle(pos + Vector2(-2 * s, 0), 2 * s, Color(0.95, 0.15, 0.1))
			canvas.draw_circle(pos + Vector2(2 * s, 2 * s), 1.5 * s, Color(0.95, 0.85, 0.15))
		"wine":
			# Wine bottle — rich ruby
			canvas.draw_rect(Rect2(pos.x - 5 * s, pos.y - 4 * s, 10 * s, 16 * s), Color(0.62, 0.08, 0.18))
			canvas.draw_rect(Rect2(pos.x - 3 * s, pos.y - 12 * s, 6 * s, 10 * s), Color(0.62, 0.08, 0.18))
			canvas.draw_rect(Rect2(pos.x - 2 * s, pos.y - 14 * s, 4 * s, 4 * s), Color(0.5, 0.05, 0.12))
			canvas.draw_rect(Rect2(pos.x - 4 * s, pos.y + 2 * s, 8 * s, 5 * s), Color(0.95, 0.92, 0.85))
		"tools":
			# Wrench — cool slate blue
			canvas.draw_rect(Rect2(pos.x - 2 * s, pos.y - 8 * s, 4 * s, 18 * s), Color(0.3, 0.38, 0.48))
			canvas.draw_rect(Rect2(pos.x - 6 * s, pos.y - 12 * s, 12 * s, 6 * s), Color(0.35, 0.42, 0.55))
			canvas.draw_rect(Rect2(pos.x - 2 * s, pos.y - 12 * s, 4 * s, 3 * s), Color(0.2, 0.25, 0.35))
			canvas.draw_rect(Rect2(pos.x - 3 * s, pos.y + 4 * s, 6 * s, 6 * s), Color(0.55, 0.35, 0.2))
		"leather":
			# Leather wallet — warm cognac
			canvas.draw_rect(Rect2(pos.x - 8 * s, pos.y - 6 * s, 16 * s, 12 * s), Color(0.55, 0.32, 0.12))
			canvas.draw_rect(Rect2(pos.x - 7 * s, pos.y - 5 * s, 14 * s, 10 * s), Color(0.65, 0.4, 0.18))
			for i in 5:
				var sx = pos.x - 5 * s + i * 3 * s
				canvas.draw_rect(Rect2(sx, pos.y - 4 * s, 1.5 * s, 1.5 * s), Color(0.85, 0.68, 0.4))
			canvas.draw_circle(pos + Vector2(0, 4 * s), 2 * s, Color(0.85, 0.72, 0.3))
		"spirits":
			# Whiskey bottle — bright gold
			canvas.draw_rect(Rect2(pos.x - 5 * s, pos.y - 2 * s, 10 * s, 14 * s), Color(0.85, 0.65, 0.1))
			canvas.draw_rect(Rect2(pos.x - 3 * s, pos.y - 10 * s, 6 * s, 10 * s), Color(0.8, 0.58, 0.08))
			canvas.draw_rect(Rect2(pos.x - 3 * s, pos.y - 13 * s, 6 * s, 4 * s), Color(0.25, 0.2, 0.1))
			canvas.draw_rect(Rect2(pos.x - 4 * s, pos.y + 2 * s, 8 * s, 6 * s), Color(0.95, 0.92, 0.82))
			canvas.draw_rect(Rect2(pos.x - 3 * s, pos.y + 4 * s, 6 * s, 1 * s), Color(0.3, 0.2, 0.08))
		_:
			# Generic box
			canvas.draw_rect(Rect2(pos.x - 8 * s, pos.y - 8 * s, 16 * s, 16 * s), Color(0.7, 0.65, 0.6))

# -- Draw ellipse helper (Godot doesn't have a built-in) --
static func draw_ellipse(canvas: CanvasItem, rect: Rect2, color: Color, segments: int = 16) -> void:
	var center = rect.get_center()
	var rx = rect.size.x / 2.0
	var ry = rect.size.y / 2.0
	var points: PackedVector2Array = PackedVector2Array()
	for i in segments + 1:
		var angle = TAU * i / segments
		points.append(Vector2(center.x + cos(angle) * rx, center.y + sin(angle) * ry))
	if points.size() >= 3:
		canvas.draw_colored_polygon(points, color)
