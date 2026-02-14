extends Node2D

## ShopVisuals - Procedural drawing layer for the shop interior.
## Replaces all ColorRect placeholders with textured, hand-drawn style art.

const DU = preload("res://scripts/visual/draw_utils.gd")

# Palette
var floor_color := Color(0.82, 0.75, 0.65)
var wall_color := Color(0.78, 0.72, 0.68)
var wall_back_color := Color(0.72, 0.66, 0.62)
var counter_wood := Color(0.52, 0.38, 0.28)
var shelf_wood := Color(0.58, 0.48, 0.36)
var door_color := Color(0.45, 0.35, 0.25)
var trim_color := Color(0.65, 0.55, 0.42)

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

func _draw_shelf_unit(pos: Vector2, size: Vector2) -> void:
	# Shadow
	draw_rect(Rect2(pos.x + 4, pos.y + 4, size.x, size.y), Color(0, 0, 0, 0.12))
	# Back panel
	draw_rect(Rect2(pos, size), shelf_wood.darkened(0.15))
	# Shelf boards
	var shelf_count = 3
	for i in shelf_count:
		var sy = pos.y + (i + 1) * (size.y / (shelf_count + 1))
		DU.draw_wood_planks(self, Rect2(pos.x, sy - 3, size.x, 7), shelf_wood, 3, true)
	# Side trim
	draw_rect(Rect2(pos.x, pos.y, 5, size.y), shelf_wood.darkened(0.08))
	draw_rect(Rect2(pos.x + size.x - 5, pos.y, 5, size.y), shelf_wood.darkened(0.08))
	# Top crown
	draw_rect(Rect2(pos.x - 3, pos.y - 5, size.x + 6, 7), shelf_wood)
	draw_rect(Rect2(pos.x - 3, pos.y - 5, size.x + 6, 2), Color(1, 1, 1, 0.1))
	# Items on shelves (colored circles as goods)
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x * 7 + pos.y)
	var item_colors = [Color(0.82, 0.68, 0.38), Color(0.35, 0.6, 0.3), Color(0.92, 0.88, 0.55), Color(0.72, 0.58, 0.78), Color(0.7, 0.5, 0.35)]
	for i in shelf_count:
		var sy = pos.y + (i + 1) * (size.y / (shelf_count + 1)) - 14
		var item_count = rng.randi_range(2, 4)
		var spacing = size.x / (item_count + 1)
		for j in item_count:
			var ix = pos.x + (j + 1) * spacing
			var c = item_colors[rng.randi() % item_colors.size()]
			# Small jar/bottle shape
			draw_rect(Rect2(ix - 6, sy - 8, 12, 12), c)
			draw_rect(Rect2(ix - 3, sy - 12, 6, 5), c.lightened(0.15))

func _draw_back_shelf(pos: Vector2, size: Vector2) -> void:
	draw_rect(Rect2(pos.x + 2, pos.y + 2, size.x, size.y), Color(0, 0, 0, 0.1))
	DU.draw_wood_planks(self, Rect2(pos, size), shelf_wood.darkened(0.05), 2, true)
	draw_rect(Rect2(pos.x, pos.y, size.x, 2), Color(1, 1, 1, 0.1))
	# Small items
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x)
	var colors = [Color(0.82, 0.68, 0.38), Color(0.6, 0.75, 0.5), Color(0.92, 0.75, 0.4)]
	for i in 3:
		var ix = pos.x + 20 + i * 40
		var c = colors[i % colors.size()]
		draw_circle(Vector2(ix, pos.y + size.y * 0.5), 8, c)

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
