extends Node2D

## ShopVisuals - Procedural drawing layer for the shop interior.
## Replaces all ColorRect placeholders with textured, hand-drawn style art.

const DU = preload("res://scripts/visual/draw_utils.gd")

# Palette — high contrast, warm cozy tones
var floor_color := Color(0.68, 0.52, 0.36)
var wall_color := Color(0.62, 0.55, 0.50)
var wall_back_color := Color(0.55, 0.48, 0.44)
var counter_wood := Color(0.48, 0.32, 0.20)
var shelf_wood := Color(0.52, 0.40, 0.28)
var door_color := Color(0.38, 0.28, 0.18)
var trim_color := Color(0.72, 0.60, 0.42)

func _draw() -> void:
	# --- Floor: warm parquet wood ---
	DU.draw_parquet_floor(self, Rect2(0, 0, 720, 1280), floor_color, 48.0)

	# --- Back wall: brick ---
	DU.draw_brick_wall(self, Rect2(0, 0, 720, 130), wall_back_color, 45, 22)
	# Wall trim
	draw_rect(Rect2(0, 126, 720, 6), trim_color)

	# --- Decorative tile border along back wall base ---
	for i in int(636.0 / 20.0):
		var tx = 42 + i * 20
		var alt = i % 2 == 0
		draw_rect(Rect2(tx, 132, 19, 14), Color(0.52, 0.42, 0.32) if alt else Color(0.6, 0.5, 0.4))
		if alt:
			var cx = tx + 10
			var cy = 139.0
			var d = 4.0
			var diamond = PackedVector2Array([Vector2(cx, cy - d), Vector2(cx + d, cy), Vector2(cx, cy + d), Vector2(cx - d, cy)])
			draw_colored_polygon(diamond, Color(0.45, 0.35, 0.25))

	# --- Side walls ---
	DU.draw_brick_wall(self, Rect2(0, 0, 42, 1280), wall_color, 42, 22)
	DU.draw_brick_wall(self, Rect2(678, 0, 42, 1280), wall_color, 42, 22)
	# Wall trim strips
	draw_rect(Rect2(40, 0, 3, 1280), trim_color.darkened(0.1))
	draw_rect(Rect2(677, 0, 3, 1280), trim_color.darkened(0.1))

	# --- Counter: wood planks ---
	# Counter top
	DU.draw_wood_planks(self, Rect2(190, 895, 340, 70), counter_wood, 4, true)
	# Counter front face
	DU.draw_wood_planks(self, Rect2(190, 960, 340, 25), counter_wood.darkened(0.15), 6, false)
	# Counter trim
	draw_rect(Rect2(188, 893, 344, 3), trim_color)
	draw_rect(Rect2(188, 893, 3, 95), trim_color.darkened(0.1))
	draw_rect(Rect2(529, 893, 3, 95), trim_color.darkened(0.1))

	# --- Shelves ---
	_draw_shelf_unit(Vector2(42, 195), Vector2(158, 210))   # Left
	_draw_shelf_unit(Vector2(520, 195), Vector2(158, 210))  # Right
	_draw_back_shelf(Vector2(130, 118), Vector2(140, 45))   # Back left
	_draw_back_shelf(Vector2(450, 118), Vector2(140, 45))   # Back right

	# --- Door area ---
	# Doorframe
	draw_rect(Rect2(270, 1185, 180, 95), door_color)
	# Door panels
	draw_rect(Rect2(275, 1190, 80, 85), door_color.lightened(0.08))
	draw_rect(Rect2(360, 1190, 80, 85), door_color.lightened(0.08))
	# Door handle
	draw_circle(Vector2(352, 1235), 4, Color(0.8, 0.7, 0.4))
	# Doormat
	draw_rect(Rect2(285, 1175, 150, 12), Color(0.6, 0.5, 0.38))
	# "WELCOME" on mat
	# (text drawn by Label node)

	# --- Ad surfaces (picture frames) ---
	_draw_frame(Vector2(282, 12), Vector2(156, 98))  # Billboard
	_draw_frame(Vector2(6, 502), Vector2(30, 158))    # Poster left
	_draw_frame(Vector2(684, 502), Vector2(30, 158))  # Poster right

	# --- Window on back wall ---
	_draw_window(Vector2(560, 20), Vector2(90, 80))

	# --- Decorative details ---
	# Baseboard
	draw_rect(Rect2(42, 1270, 636, 10), trim_color.darkened(0.15))
	# Ceiling line
	draw_rect(Rect2(42, 0, 636, 3), trim_color.lightened(0.1))

	# --- Floor rug near counter ---
	_draw_rug(Vector2(260, 1020), Vector2(200, 100))

	# --- Warm ambient light from window ---
	var light_color = Color(1.0, 0.95, 0.8, 0.06)
	draw_rect(Rect2(480, 100, 200, 500), light_color)
	draw_rect(Rect2(500, 100, 160, 400), Color(1.0, 0.95, 0.8, 0.04))

	# --- Edge vignette for depth ---
	for i in 8:
		var alpha = 0.03 * (8 - i)
		draw_rect(Rect2(42, i * 2, 636, 2), Color(0, 0, 0, alpha))  # top
		draw_rect(Rect2(42, 1278 - i * 2, 636, 2), Color(0, 0, 0, alpha))  # bottom
		draw_rect(Rect2(42, 0, i * 2, 1280), Color(0, 0, 0, alpha * 0.5))  # left
		draw_rect(Rect2(678 - i * 2, 0, i * 2, 1280), Color(0, 0, 0, alpha * 0.5))  # right

func _draw_shelf_unit(pos: Vector2, size: Vector2) -> void:
	# Warm layered glow aura — inviting and interactive
	for i in 3:
		var expand = (3 - i) * 5
		draw_rect(Rect2(pos.x - expand, pos.y - expand, size.x + expand * 2, size.y + expand * 2), Color(1.0, 0.85, 0.5, 0.03 + i * 0.02))
	# Deep shadow (two layers for depth)
	draw_rect(Rect2(pos.x + 6, pos.y + 6, size.x, size.y), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(pos.x + 3, pos.y + 3, size.x, size.y), Color(0, 0, 0, 0.12))
	# Back panel — rich dark wood
	draw_rect(Rect2(pos, size), shelf_wood.darkened(0.25))
	# Inner panel — lighter for depth, warm backlight feel
	draw_rect(Rect2(pos.x + 6, pos.y + 3, size.x - 12, size.y - 3), shelf_wood.darkened(0.15))
	draw_rect(Rect2(pos.x + 10, pos.y + 8, size.x - 20, size.y - 8), Color(1.0, 0.9, 0.7, 0.04))
	# Shelf boards with iron brackets
	var shelf_count = 3
	var bracket_c = Color(0.22, 0.2, 0.18)
	for i in shelf_count:
		var sy = pos.y + (i + 1) * (size.y / (shelf_count + 1))
		DU.draw_wood_planks(self, Rect2(pos.x, sy - 5, size.x, 10), shelf_wood, 3, true)
		draw_rect(Rect2(pos.x + 2, sy - 5, size.x - 4, 2), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(pos.x + 2, sy + 3, size.x - 4, 3), Color(0, 0, 0, 0.12))
		# Iron L-brackets — left
		draw_rect(Rect2(pos.x + 14, sy + 5, 3, 12), bracket_c)
		draw_rect(Rect2(pos.x + 14, sy + 5, 10, 3), bracket_c)
		draw_rect(Rect2(pos.x + 14, sy + 14, 7, 3), bracket_c)
		# Iron L-brackets — right
		draw_rect(Rect2(pos.x + size.x - 17, sy + 5, 3, 12), bracket_c)
		draw_rect(Rect2(pos.x + size.x - 24, sy + 5, 10, 3), bracket_c)
		draw_rect(Rect2(pos.x + size.x - 21, sy + 14, 7, 3), bracket_c)
	# Side posts — thick carved wood
	draw_rect(Rect2(pos.x, pos.y, 8, size.y), shelf_wood.darkened(0.08))
	draw_rect(Rect2(pos.x, pos.y, 2, size.y), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(pos.x + 6, pos.y, 2, size.y), Color(0, 0, 0, 0.06))
	draw_rect(Rect2(pos.x + size.x - 8, pos.y, 8, size.y), shelf_wood.darkened(0.08))
	draw_rect(Rect2(pos.x + size.x - 2, pos.y, 2, size.y), Color(0, 0, 0, 0.1))
	draw_rect(Rect2(pos.x + size.x - 8, pos.y, 2, size.y), Color(1, 1, 1, 0.06))
	# Top crown — ornate with decorative notches
	draw_rect(Rect2(pos.x - 6, pos.y - 12, size.x + 12, 14), shelf_wood.lightened(0.05))
	draw_rect(Rect2(pos.x - 6, pos.y - 12, size.x + 12, 2), Color(1, 1, 1, 0.18))
	draw_rect(Rect2(pos.x - 4, pos.y - 3, size.x + 8, 3), trim_color.darkened(0.08))
	# Crown notches
	for n in 3:
		var nx = pos.x + 18 + n * ((size.x - 36) / 2.0)
		draw_rect(Rect2(nx, pos.y - 11, 10, 3), trim_color)
	# Bottom base — sturdy feet
	draw_rect(Rect2(pos.x - 3, pos.y + size.y, size.x + 6, 7), shelf_wood.darkened(0.12))
	draw_rect(Rect2(pos.x - 3, pos.y + size.y + 5, size.x + 6, 2), Color(0, 0, 0, 0.1))
	# Bold outer border
	draw_rect(Rect2(pos.x - 1, pos.y - 1, size.x + 2, 1), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y + size.y, size.x + 2, 1), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y, 1, size.y), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(pos.x + size.x, pos.y, 1, size.y), Color(0.12, 0.08, 0.05))
	# Decorative element on top — plant (left) or candle (right)
	var top_y = pos.y - 12
	if pos.x < 360:
		# Potted herb on left shelf
		draw_rect(Rect2(pos.x + size.x / 2 - 8, top_y - 14, 16, 14), Color(0.65, 0.4, 0.25))
		draw_rect(Rect2(pos.x + size.x / 2 - 10, top_y - 16, 20, 4), Color(0.58, 0.36, 0.2))
		draw_circle(Vector2(pos.x + size.x / 2 - 4, top_y - 22), 6, Color(0.35, 0.6, 0.3))
		draw_circle(Vector2(pos.x + size.x / 2 + 5, top_y - 20), 5, Color(0.4, 0.65, 0.32))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 27), 4, Color(0.32, 0.55, 0.28))
	else:
		# Candle on right shelf
		draw_rect(Rect2(pos.x + size.x / 2 - 4, top_y - 20, 8, 20), Color(0.95, 0.92, 0.85))
		draw_rect(Rect2(pos.x + size.x / 2 - 7, top_y - 2, 14, 4), Color(0.7, 0.55, 0.3))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 24), 4, Color(1.0, 0.8, 0.3, 0.8))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 25), 2.5, Color(1.0, 0.95, 0.7, 0.9))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 22), 12, Color(1.0, 0.85, 0.4, 0.06))
	# Items on shelves — varied, colorful, characterful
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x * 7 + pos.y)
	var item_colors = [
		Color(0.35, 0.2, 0.12),   # Coffee espresso
		Color(0.95, 0.55, 0.08),  # Spice saffron
		Color(0.62, 0.08, 0.18),  # Wine ruby
		Color(0.35, 0.42, 0.55),  # Tools slate blue
		Color(0.85, 0.65, 0.1),   # Spirits gold
	]
	var item_shapes = [0, 1, 1, 2, 1]
	for i in shelf_count:
		var sy = pos.y + (i + 1) * (size.y / (shelf_count + 1)) - 18
		var item_count = rng.randi_range(3, 5)
		var spacing = (size.x - 24.0) / item_count
		for j in item_count:
			var ix = pos.x + 12 + j * spacing + spacing / 2
			var ci = rng.randi() % item_colors.size()
			var c = item_colors[ci]
			var shape = item_shapes[ci]
			# Warm backlight glow behind each item
			draw_circle(Vector2(ix, sy - 4), 14, Color(1.0, 0.9, 0.7, 0.04))
			if shape == 0:
				draw_rect(Rect2(ix - 11, sy - 12, 22, 20), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 10, sy - 11, 20, 18), c)
				draw_rect(Rect2(ix - 6, sy - 17, 12, 7), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 5, sy - 16, 10, 5), c.lightened(0.2))
				draw_rect(Rect2(ix - 8, sy - 4, 16, 5), Color(1, 1, 0.9, 0.5))
				draw_rect(Rect2(ix - 4, sy - 16, 3, 2), Color(1, 1, 1, 0.3))
			elif shape == 1:
				draw_rect(Rect2(ix - 8, sy - 16, 16, 24), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 7, sy - 15, 14, 22), c)
				draw_rect(Rect2(ix - 4, sy - 22, 8, 8), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 3, sy - 21, 6, 6), c.lightened(0.15))
				draw_rect(Rect2(ix - 3, sy - 23, 6, 3), Color(0.7, 0.55, 0.35))
				draw_rect(Rect2(ix - 6, sy - 6, 12, 8), Color(1, 1, 0.92, 0.35))
			else:
				draw_circle(Vector2(ix, sy - 2), 11, Color(0.12, 0.08, 0.05))
				draw_circle(Vector2(ix, sy - 2), 10, c)
				draw_rect(Rect2(ix - 3, sy - 16, 6, 10), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 2, sy - 15, 4, 9), c.lightened(0.1))
				draw_rect(Rect2(ix - 4, sy - 18, 8, 4), Color(0.6, 0.5, 0.35))
			# Shine highlight
			draw_rect(Rect2(ix - 6, sy - 10, 3, 6), Color(1, 1, 1, 0.3))
			draw_rect(Rect2(ix - 5, sy - 8, 2, 3), Color(1, 1, 1, 0.18))

func _draw_back_shelf(pos: Vector2, size: Vector2) -> void:
	# Layered glow behind
	draw_rect(Rect2(pos.x - 6, pos.y - 6, size.x + 12, size.y + 12), Color(1.0, 0.85, 0.5, 0.05))
	draw_rect(Rect2(pos.x - 3, pos.y - 3, size.x + 6, size.y + 6), Color(1.0, 0.9, 0.6, 0.06))
	# Shadow
	draw_rect(Rect2(pos.x + 4, pos.y + 3, size.x, size.y), Color(0, 0, 0, 0.18))
	# Shelf board
	DU.draw_wood_planks(self, Rect2(pos, size), shelf_wood.darkened(0.05), 2, true)
	# Top highlight
	draw_rect(Rect2(pos.x, pos.y, size.x, 2), Color(1, 1, 1, 0.16))
	# Bottom shadow
	draw_rect(Rect2(pos.x, pos.y + size.y - 2, size.x, 2), Color(0, 0, 0, 0.12))
	# Border
	draw_rect(Rect2(pos.x - 1, pos.y - 1, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y + size.y, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	# Iron brackets underneath
	var bracket_c = Color(0.22, 0.2, 0.18)
	draw_rect(Rect2(pos.x + 15, pos.y + size.y, 3, 10), bracket_c)
	draw_rect(Rect2(pos.x + 15, pos.y + size.y + 7, 12, 3), bracket_c)
	draw_rect(Rect2(pos.x + size.x - 18, pos.y + size.y, 3, 10), bracket_c)
	draw_rect(Rect2(pos.x + size.x - 30, pos.y + size.y + 7, 12, 3), bracket_c)
	# Items — varied shapes: bottles, vases, lantern
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x)
	var colors = [Color(0.35, 0.2, 0.12), Color(0.62, 0.08, 0.18), Color(0.95, 0.55, 0.08), Color(0.85, 0.65, 0.1)]
	var spacing = size.x / 5.0
	for i in 4:
		var ix = pos.x + spacing * (i + 0.5)
		var c = colors[i % colors.size()]
		var cy = pos.y + size.y * 0.3
		# Backlight
		draw_circle(Vector2(ix, cy), 12, Color(1.0, 0.9, 0.7, 0.04))
		if i == 0:
			# Small vase with flowers
			draw_rect(Rect2(ix - 5, cy - 6, 10, 12), Color(0.12, 0.08, 0.05))
			draw_rect(Rect2(ix - 4, cy - 5, 8, 10), Color(0.45, 0.6, 0.7))
			draw_circle(Vector2(ix - 3, cy - 9), 3, Color(0.9, 0.4, 0.4))
			draw_circle(Vector2(ix + 2, cy - 10), 2.5, Color(0.95, 0.7, 0.3))
			draw_circle(Vector2(ix, cy - 12), 2, Color(0.9, 0.5, 0.6))
		elif i == 3:
			# Small lantern
			draw_rect(Rect2(ix - 5, cy - 8, 10, 14), Color(0.12, 0.08, 0.05))
			draw_rect(Rect2(ix - 4, cy - 7, 8, 12), Color(0.65, 0.55, 0.35))
			draw_rect(Rect2(ix - 3, cy - 5, 6, 8), Color(1.0, 0.85, 0.4, 0.5))
			draw_circle(Vector2(ix, cy - 1), 2, Color(1.0, 0.9, 0.5, 0.8))
			draw_rect(Rect2(ix - 2, cy - 10, 4, 3), Color(0.3, 0.28, 0.22))
		else:
			# Regular items
			draw_circle(Vector2(ix, cy), 12, Color(0.12, 0.08, 0.05))
			draw_circle(Vector2(ix, cy), 10, c)
		# Shine
		draw_rect(Rect2(ix - 4, cy - 6, 3, 4), Color(1, 1, 1, 0.28))

func _draw_frame(pos: Vector2, size: Vector2) -> void:
	# Outer frame
	draw_rect(Rect2(pos.x - 3, pos.y - 3, size.x + 6, size.y + 6), Color(0.45, 0.35, 0.25))
	# Inner frame
	draw_rect(Rect2(pos, size), Color(0.88, 0.85, 0.78))

func _draw_window(pos: Vector2, size: Vector2) -> void:
	# Frame
	draw_rect(Rect2(pos.x - 4, pos.y - 4, size.x + 8, size.y + 8), trim_color)
	# Glass
	draw_rect(Rect2(pos, size), Color(0.7, 0.82, 0.9, 0.6))
	# Cross bar
	draw_rect(Rect2(pos.x + size.x / 2 - 1.5, pos.y, 3, size.y), trim_color)
	draw_rect(Rect2(pos.x, pos.y + size.y / 2 - 1.5, size.x, 3), trim_color)
	# Light reflection
	draw_line(pos + Vector2(8, 8), pos + Vector2(20, 5), Color(1, 1, 1, 0.3), 2)

func _draw_rug(pos: Vector2, size: Vector2) -> void:
	# Oval rug with pattern
	var center = pos + size / 2
	DU.draw_ellipse(self, Rect2(pos, size), Color(0.6, 0.35, 0.3, 0.6))
	DU.draw_ellipse(self, Rect2(pos.x + 15, pos.y + 10, size.x - 30, size.y - 20), Color(0.65, 0.4, 0.32, 0.6))
	DU.draw_ellipse(self, Rect2(pos.x + 30, pos.y + 20, size.x - 60, size.y - 40), Color(0.7, 0.45, 0.35, 0.6))
