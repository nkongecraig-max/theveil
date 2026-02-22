extends Node2D

## ShopVisuals - Procedural drawing layer for the shop interior.
## Replaces all ColorRect placeholders with textured, hand-drawn style art.

const DU = preload("res://scripts/visual/draw_utils.gd")

# Palette — high contrast, warm cozy tones
var floor_color := Color(0.76, 0.68, 0.55)
var wall_color := Color(0.62, 0.55, 0.50)
var wall_back_color := Color(0.55, 0.48, 0.44)
var counter_wood := Color(0.48, 0.32, 0.20)
var shelf_wood := Color(0.52, 0.40, 0.28)
var door_color := Color(0.38, 0.28, 0.18)
var trim_color := Color(0.72, 0.60, 0.42)

func _draw() -> void:
	# --- Floor: stone tiles ---
	DU.draw_stone_floor(self, Rect2(0, 0, 720, 1280), floor_color, 64.0)

	# --- Back wall: brick ---
	DU.draw_brick_wall(self, Rect2(0, 0, 720, 130), wall_back_color, 45, 22)
	# Wall trim
	draw_rect(Rect2(0, 126, 720, 6), trim_color)

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
	# Outer glow — signals interactivity
	draw_rect(Rect2(pos.x - 6, pos.y - 8, size.x + 12, size.y + 14), Color(1.0, 0.9, 0.6, 0.08))
	draw_rect(Rect2(pos.x - 3, pos.y - 5, size.x + 6, size.y + 8), Color(1.0, 0.9, 0.6, 0.06))
	# Shadow
	draw_rect(Rect2(pos.x + 5, pos.y + 5, size.x, size.y), Color(0, 0, 0, 0.18))
	# Back panel — darker for contrast
	draw_rect(Rect2(pos, size), shelf_wood.darkened(0.22))
	# Inner panel lighter area for depth
	draw_rect(Rect2(pos.x + 6, pos.y + 4, size.x - 12, size.y - 4), shelf_wood.darkened(0.12))
	# Shelf boards — thicker, more prominent
	var shelf_count = 3
	for i in shelf_count:
		var sy = pos.y + (i + 1) * (size.y / (shelf_count + 1))
		DU.draw_wood_planks(self, Rect2(pos.x, sy - 5, size.x, 10), shelf_wood, 3, true)
		# Board edge highlight
		draw_rect(Rect2(pos.x + 2, sy - 5, size.x - 4, 2), Color(1, 1, 1, 0.12))
		# Board bottom shadow
		draw_rect(Rect2(pos.x + 2, sy + 3, size.x - 4, 2), Color(0, 0, 0, 0.1))
	# Side trim — thicker, beveled look
	draw_rect(Rect2(pos.x, pos.y, 7, size.y), shelf_wood.darkened(0.1))
	draw_rect(Rect2(pos.x, pos.y, 2, size.y), Color(1, 1, 1, 0.08))
	draw_rect(Rect2(pos.x + size.x - 7, pos.y, 7, size.y), shelf_wood.darkened(0.1))
	draw_rect(Rect2(pos.x + size.x - 2, pos.y, 2, size.y), Color(0, 0, 0, 0.08))
	# Top crown — more ornate
	draw_rect(Rect2(pos.x - 5, pos.y - 8, size.x + 10, 10), shelf_wood.lightened(0.05))
	draw_rect(Rect2(pos.x - 5, pos.y - 8, size.x + 10, 2), Color(1, 1, 1, 0.15))
	draw_rect(Rect2(pos.x - 3, pos.y - 3, size.x + 6, 2), trim_color.darkened(0.1))
	# Bold outer border
	draw_rect(Rect2(pos.x - 1, pos.y - 1, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y + size.y, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y, 1, size.y), Color(0.15, 0.1, 0.05))
	draw_rect(Rect2(pos.x + size.x, pos.y, 1, size.y), Color(0.15, 0.1, 0.05))
	# Items on shelves — BIGGER, bolder, distinct shapes
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x * 7 + pos.y)
	var item_colors = [
		Color(0.35, 0.2, 0.12),   # Coffee espresso
		Color(0.95, 0.55, 0.08),  # Spice saffron
		Color(0.62, 0.08, 0.18),  # Wine ruby
		Color(0.35, 0.42, 0.55),  # Tools slate blue
		Color(0.85, 0.65, 0.1),   # Spirits gold
	]
	var item_shapes = [0, 1, 1, 2, 1]  # 0=jar(coffee), 1=bottle(wine/spirits), 2=box(tools)
	for i in shelf_count:
		var sy = pos.y + (i + 1) * (size.y / (shelf_count + 1)) - 18
		var item_count = rng.randi_range(3, 4)
		var spacing = size.x / (item_count + 1)
		for j in item_count:
			var ix = pos.x + (j + 1) * spacing
			var ci = rng.randi() % item_colors.size()
			var c = item_colors[ci]
			var shape = item_shapes[ci]
			if shape == 0:
				# Wide jar — 20x18 body
				draw_rect(Rect2(ix - 11, sy - 12, 22, 20), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 10, sy - 11, 20, 18), c)
				draw_rect(Rect2(ix - 6, sy - 17, 12, 7), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 5, sy - 16, 10, 5), c.lightened(0.2))
				# Label band
				draw_rect(Rect2(ix - 8, sy - 4, 16, 5), Color(1, 1, 0.9, 0.5))
			elif shape == 1:
				# Tall bottle — 14x22 body
				draw_rect(Rect2(ix - 8, sy - 16, 16, 24), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 7, sy - 15, 14, 22), c)
				draw_rect(Rect2(ix - 4, sy - 22, 8, 8), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 3, sy - 21, 6, 6), c.lightened(0.15))
				# Cork
				draw_rect(Rect2(ix - 3, sy - 23, 6, 3), Color(0.7, 0.55, 0.35))
			else:
				# Round flask — circle body
				draw_circle(Vector2(ix, sy - 2), 11, Color(0.12, 0.08, 0.05))
				draw_circle(Vector2(ix, sy - 2), 10, c)
				draw_rect(Rect2(ix - 3, sy - 16, 6, 10), Color(0.12, 0.08, 0.05))
				draw_rect(Rect2(ix - 2, sy - 15, 4, 9), c.lightened(0.1))
				# Stopper
				draw_rect(Rect2(ix - 4, sy - 18, 8, 4), Color(0.6, 0.5, 0.35))
			# Shine highlight on all items
			draw_rect(Rect2(ix - 6, sy - 10, 3, 6), Color(1, 1, 1, 0.25))
			draw_rect(Rect2(ix - 5, sy - 8, 2, 3), Color(1, 1, 1, 0.15))

func _draw_back_shelf(pos: Vector2, size: Vector2) -> void:
	# Glow behind for interactivity
	draw_rect(Rect2(pos.x - 4, pos.y - 4, size.x + 8, size.y + 8), Color(1.0, 0.9, 0.6, 0.07))
	# Shadow
	draw_rect(Rect2(pos.x + 3, pos.y + 3, size.x, size.y), Color(0, 0, 0, 0.15))
	# Shelf board
	DU.draw_wood_planks(self, Rect2(pos, size), shelf_wood.darkened(0.05), 2, true)
	# Top highlight
	draw_rect(Rect2(pos.x, pos.y, size.x, 2), Color(1, 1, 1, 0.14))
	# Bottom shadow
	draw_rect(Rect2(pos.x, pos.y + size.y - 2, size.x, 2), Color(0, 0, 0, 0.1))
	# Border
	draw_rect(Rect2(pos.x - 1, pos.y - 1, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y + size.y, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	# Bigger items with distinct shapes
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x)
	var colors = [Color(0.35, 0.2, 0.12), Color(0.62, 0.08, 0.18), Color(0.95, 0.55, 0.08), Color(0.85, 0.65, 0.1)]
	var spacing = size.x / 5
	for i in 4:
		var ix = pos.x + spacing * (i + 0.5)
		var c = colors[i % colors.size()]
		var cy = pos.y + size.y * 0.35
		# Item outline + fill — bigger (radius 10)
		draw_circle(Vector2(ix, cy), 12, Color(0.12, 0.08, 0.05))
		draw_circle(Vector2(ix, cy), 10, c)
		# Shine
		draw_rect(Rect2(ix - 4, cy - 6, 3, 4), Color(1, 1, 1, 0.25))

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
