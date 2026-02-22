extends Node2D

## ShopVisuals - Procedural drawing layer for the shop interior.
## Colors and decorations evolve gradually with player level.
## Level 1 = humble start, Level 10+ = warm premium boutique.

const DU = preload("res://scripts/visual/draw_utils.gd")

# --- Level-driven progression ---
var shop_level: int = 1

# Base palette (Level 1 — humble, cool-ish)
var _base_floor := Color(0.68, 0.52, 0.36)
var _base_wall := Color(0.62, 0.55, 0.50)
var _base_wall_back := Color(0.55, 0.48, 0.44)
var _base_counter := Color(0.48, 0.32, 0.20)
var _base_shelf := Color(0.52, 0.40, 0.28)
var _base_door := Color(0.38, 0.28, 0.18)
var _base_trim := Color(0.72, 0.60, 0.42)

# Premium palette (Level 10 — rich, warm, inviting)
var _prem_floor := Color(0.76, 0.58, 0.40)
var _prem_wall := Color(0.68, 0.60, 0.54)
var _prem_wall_back := Color(0.62, 0.54, 0.48)
var _prem_counter := Color(0.56, 0.38, 0.22)
var _prem_shelf := Color(0.60, 0.46, 0.32)
var _prem_door := Color(0.46, 0.34, 0.22)
var _prem_trim := Color(0.84, 0.70, 0.38)

func set_level(level: int) -> void:
	shop_level = level
	queue_redraw()

## Progress 0.0 (level 1) to 1.0 (level 10+)
func _p() -> float:
	return clampf((shop_level - 1) / 9.0, 0.0, 1.0)

func _draw() -> void:
	var p = _p()
	# Lerp all working colors based on level progress
	var floor_c = _base_floor.lerp(_prem_floor, p)
	var wall_c = _base_wall.lerp(_prem_wall, p)
	var wall_back_c = _base_wall_back.lerp(_prem_wall_back, p)
	var counter_c = _base_counter.lerp(_prem_counter, p)
	var shelf_c = _base_shelf.lerp(_prem_shelf, p)
	var door_c = _base_door.lerp(_prem_door, p)
	var trim_c = _base_trim.lerp(_prem_trim, p)

	# --- Floor: warm parquet wood ---
	DU.draw_parquet_floor(self, Rect2(0, 0, 720, 1280), floor_c, 48.0)

	# --- Back wall: brick ---
	DU.draw_brick_wall(self, Rect2(0, 0, 720, 130), wall_back_c, 45, 22)
	# Wall trim
	draw_rect(Rect2(0, 126, 720, 6), trim_c)

	# --- Decorative tile border along back wall base ---
	var tile_a = Color(0.52, 0.42, 0.32).lerp(Color(0.58, 0.48, 0.36), p)
	var tile_b = Color(0.6, 0.5, 0.4).lerp(Color(0.66, 0.56, 0.44), p)
	var diamond_c = Color(0.45, 0.35, 0.25).lerp(Color(0.55, 0.42, 0.28), p)
	for i in int(636.0 / 20.0):
		var tx = 42 + i * 20
		var alt = i % 2 == 0
		draw_rect(Rect2(tx, 132, 19, 14), tile_a if alt else tile_b)
		if alt:
			var cx = tx + 10
			var cy = 139.0
			var d = 4.0
			var diamond = PackedVector2Array([Vector2(cx, cy - d), Vector2(cx + d, cy), Vector2(cx, cy + d), Vector2(cx - d, cy)])
			draw_colored_polygon(diamond, diamond_c)

	# --- Side walls ---
	DU.draw_brick_wall(self, Rect2(0, 0, 42, 1280), wall_c, 42, 22)
	DU.draw_brick_wall(self, Rect2(678, 0, 42, 1280), wall_c, 42, 22)
	# Wall trim strips
	draw_rect(Rect2(40, 0, 3, 1280), trim_c.darkened(0.1))
	draw_rect(Rect2(677, 0, 3, 1280), trim_c.darkened(0.1))

	# --- Counter: wood planks ---
	DU.draw_wood_planks(self, Rect2(190, 895, 340, 70), counter_c, 4, true)
	DU.draw_wood_planks(self, Rect2(190, 960, 340, 25), counter_c.darkened(0.15), 6, false)
	draw_rect(Rect2(188, 893, 344, 3), trim_c)
	draw_rect(Rect2(188, 893, 3, 95), trim_c.darkened(0.1))
	draw_rect(Rect2(529, 893, 3, 95), trim_c.darkened(0.1))

	# --- Shelves ---
	_draw_shelf_unit(Vector2(42, 195), Vector2(158, 210), shelf_c, trim_c)
	_draw_shelf_unit(Vector2(520, 195), Vector2(158, 210), shelf_c, trim_c)
	_draw_back_shelf(Vector2(130, 118), Vector2(140, 45), shelf_c)
	_draw_back_shelf(Vector2(450, 118), Vector2(140, 45), shelf_c)

	# --- Door area ---
	draw_rect(Rect2(270, 1185, 180, 95), door_c)
	draw_rect(Rect2(275, 1190, 80, 85), door_c.lightened(0.08))
	draw_rect(Rect2(360, 1190, 80, 85), door_c.lightened(0.08))
	# Door handle — gets shinier with level
	var handle_size = 4.0 + p * 2.0
	var handle_c = Color(0.8, 0.7, 0.4).lerp(Color(0.92, 0.82, 0.45), p)
	draw_circle(Vector2(352, 1235), handle_size, handle_c)
	if shop_level >= 6:
		draw_circle(Vector2(352, 1235), handle_size - 1.5, Color(1, 1, 0.9, 0.3))
	# Doormat
	draw_rect(Rect2(285, 1175, 150, 12), Color(0.6, 0.5, 0.38).lerp(Color(0.65, 0.52, 0.35), p))

	# --- Ad surfaces (picture frames) ---
	_draw_frame(Vector2(282, 12), Vector2(156, 98), trim_c)
	_draw_frame(Vector2(6, 502), Vector2(30, 158), trim_c)
	_draw_frame(Vector2(684, 502), Vector2(30, 158), trim_c)

	# --- Window on back wall ---
	_draw_window(Vector2(560, 20), Vector2(90, 80), trim_c)

	# --- Decorative details ---
	# Baseboard — gets thicker/fancier
	var bb_h = 10.0 + p * 4.0
	draw_rect(Rect2(42, 1280 - bb_h, 636, bb_h), trim_c.darkened(0.15))
	if shop_level >= 5:
		draw_rect(Rect2(42, 1280 - bb_h, 636, 2), trim_c.lightened(0.08))
	# Ceiling line
	draw_rect(Rect2(42, 0, 636, 3), trim_c.lightened(0.1))

	# --- Floor rug near counter ---
	_draw_rug(Vector2(260, 1020), Vector2(200, 100))

	# --- Warm ambient light from window ---
	var light_alpha = 0.06 + p * 0.04
	draw_rect(Rect2(480, 100, 200, 500), Color(1.0, 0.95, 0.8, light_alpha))
	draw_rect(Rect2(500, 100, 160, 400), Color(1.0, 0.95, 0.8, light_alpha * 0.7))

	# --- Edge vignette for depth ---
	for i in 8:
		var alpha = 0.03 * (8 - i)
		draw_rect(Rect2(42, i * 2, 636, 2), Color(0, 0, 0, alpha))
		draw_rect(Rect2(42, 1278 - i * 2, 636, 2), Color(0, 0, 0, alpha))
		draw_rect(Rect2(42, 0, i * 2, 1280), Color(0, 0, 0, alpha * 0.5))
		draw_rect(Rect2(678 - i * 2, 0, i * 2, 1280), Color(0, 0, 0, alpha * 0.5))

	# =============================================
	# MILESTONE DECORATIONS — unlocked by level
	# =============================================

	# Level 2: Small hanging plant basket near window
	if shop_level >= 2:
		var hx = 510.0
		var hy = 108.0
		draw_rect(Rect2(hx, hy, 2, 12), Color(0.4, 0.35, 0.28))  # rope
		draw_rect(Rect2(hx - 8, hy + 10, 18, 12), Color(0.55, 0.38, 0.24))  # basket
		draw_rect(Rect2(hx - 6, hy + 8, 14, 3), Color(0.5, 0.35, 0.2))  # rim
		draw_circle(Vector2(hx - 2, hy + 4), 5, Color(0.35, 0.58, 0.3))
		draw_circle(Vector2(hx + 5, hy + 2), 4, Color(0.38, 0.62, 0.32))
		draw_circle(Vector2(hx + 1, hy - 1), 3, Color(0.32, 0.55, 0.28))

	# Level 3: Wall clock on back wall
	if shop_level >= 3:
		var cx_clk = 200.0
		var cy_clk = 60.0
		draw_circle(Vector2(cx_clk, cy_clk), 18, Color(0.35, 0.28, 0.2))
		draw_circle(Vector2(cx_clk, cy_clk), 16, Color(0.92, 0.88, 0.8))
		draw_circle(Vector2(cx_clk, cy_clk), 14, Color(0.95, 0.92, 0.85))
		# Hour marks
		for h in 12:
			var angle = deg_to_rad(h * 30.0 - 90.0)
			var mark_start = Vector2(cx_clk + cos(angle) * 11, cy_clk + sin(angle) * 11)
			var mark_end = Vector2(cx_clk + cos(angle) * 13, cy_clk + sin(angle) * 13)
			draw_line(mark_start, mark_end, Color(0.3, 0.25, 0.2), 1.0)
		# Hands
		draw_line(Vector2(cx_clk, cy_clk), Vector2(cx_clk + 5, cy_clk - 7), Color(0.15, 0.12, 0.1), 1.5)
		draw_line(Vector2(cx_clk, cy_clk), Vector2(cx_clk - 3, cy_clk + 4), Color(0.15, 0.12, 0.1), 1.0)
		draw_circle(Vector2(cx_clk, cy_clk), 2, Color(0.8, 0.65, 0.3))

	# Level 4: Entrance floor runner rug
	if shop_level >= 4:
		var runner_c = Color(0.55, 0.3, 0.28, 0.45).lerp(Color(0.6, 0.35, 0.3, 0.55), p)
		draw_rect(Rect2(310, 1090, 100, 85), runner_c)
		draw_rect(Rect2(318, 1098, 84, 69), runner_c.lightened(0.08))
		draw_rect(Rect2(326, 1106, 68, 53), runner_c.lightened(0.15))
		# Fringe
		for f in 5:
			draw_rect(Rect2(318 + f * 18, 1088, 8, 4), runner_c.darkened(0.1))
			draw_rect(Rect2(318 + f * 18, 1175, 8, 4), runner_c.darkened(0.1))

	# Level 5: Wall sconces (small light fixtures on side walls)
	if shop_level >= 5:
		for side in [46, 672]:
			for sy in [350, 700]:
				var sconce_c = Color(0.7, 0.58, 0.35).lerp(Color(0.82, 0.68, 0.38), p)
				draw_rect(Rect2(side - 3, sy, 8, 5), sconce_c)
				draw_rect(Rect2(side - 1, sy - 8, 4, 10), sconce_c.darkened(0.1))
				# Warm glow
				draw_circle(Vector2(side + 1, sy - 4), 12, Color(1.0, 0.9, 0.6, 0.06 + p * 0.03))
				draw_circle(Vector2(side + 1, sy - 6), 4, Color(1.0, 0.85, 0.4, 0.3))

	# Level 6: Flower arrangement on counter
	if shop_level >= 6:
		var fx = 490.0
		var fy = 888.0
		# Small vase
		draw_rect(Rect2(fx - 6, fy - 12, 12, 14), Color(0.45, 0.6, 0.7))
		draw_rect(Rect2(fx - 4, fy - 14, 8, 4), Color(0.42, 0.55, 0.65))
		# Flowers
		draw_circle(Vector2(fx - 4, fy - 18), 4, Color(0.9, 0.45, 0.4))
		draw_circle(Vector2(fx + 3, fy - 20), 3.5, Color(0.95, 0.75, 0.3))
		draw_circle(Vector2(fx, fy - 24), 3, Color(0.85, 0.5, 0.6))
		draw_circle(Vector2(fx - 2, fy - 22), 2, Color(0.4, 0.65, 0.35))

	# Level 7: Window curtains
	if shop_level >= 7:
		var wx = 560.0
		var wy = 20.0
		var ww = 90.0
		var wh = 80.0
		# Curtain rod
		draw_rect(Rect2(wx - 10, wy - 8, ww + 20, 3), Color(0.5, 0.4, 0.3))
		draw_circle(Vector2(wx - 10, wy - 6), 3, Color(0.6, 0.48, 0.32))
		draw_circle(Vector2(wx + ww + 10, wy - 6), 3, Color(0.6, 0.48, 0.32))
		# Left drape
		var drape_c = Color(0.6, 0.32, 0.28, 0.7).lerp(Color(0.65, 0.35, 0.3, 0.8), p)
		draw_rect(Rect2(wx - 8, wy - 5, 18, wh + 10), drape_c)
		draw_rect(Rect2(wx - 6, wy - 3, 14, wh + 6), drape_c.lightened(0.06))
		# Right drape
		draw_rect(Rect2(wx + ww - 10, wy - 5, 18, wh + 10), drape_c)
		draw_rect(Rect2(wx + ww - 8, wy - 3, 14, wh + 6), drape_c.lightened(0.06))

	# Level 8: Premium rug gets larger + richer pattern
	if shop_level >= 8:
		_draw_rug(Vector2(100, 600), Vector2(160, 80))

	# Level 9: Ceiling crown molding
	if shop_level >= 9:
		var crown_c = trim_c.lightened(0.05)
		draw_rect(Rect2(42, 0, 636, 6), crown_c)
		draw_rect(Rect2(42, 6, 636, 2), crown_c.darkened(0.08))
		draw_rect(Rect2(42, 8, 636, 1), Color(0, 0, 0, 0.06))
		# Dentil molding — small repeated blocks
		for d in int(636.0 / 14.0):
			draw_rect(Rect2(44 + d * 14, 2, 8, 4), crown_c.lightened(0.06))

func _draw_shelf_unit(pos: Vector2, size: Vector2, sc: Color, tc: Color) -> void:
	# Warm layered glow aura
	for i in 3:
		var expand = (3 - i) * 5
		draw_rect(Rect2(pos.x - expand, pos.y - expand, size.x + expand * 2, size.y + expand * 2), Color(1.0, 0.85, 0.5, 0.03 + i * 0.02))
	# Deep shadow
	draw_rect(Rect2(pos.x + 6, pos.y + 6, size.x, size.y), Color(0, 0, 0, 0.22))
	draw_rect(Rect2(pos.x + 3, pos.y + 3, size.x, size.y), Color(0, 0, 0, 0.12))
	# Back panel
	draw_rect(Rect2(pos, size), sc.darkened(0.25))
	# Inner panel
	draw_rect(Rect2(pos.x + 6, pos.y + 3, size.x - 12, size.y - 3), sc.darkened(0.15))
	draw_rect(Rect2(pos.x + 10, pos.y + 8, size.x - 20, size.y - 8), Color(1.0, 0.9, 0.7, 0.04))
	# Shelf boards
	var shelf_count = 3
	for i in shelf_count:
		var sy = pos.y + (i + 1) * (size.y / (shelf_count + 1))
		DU.draw_wood_planks(self, Rect2(pos.x, sy - 5, size.x, 10), sc, 3, true)
		draw_rect(Rect2(pos.x + 2, sy - 5, size.x - 4, 2), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(pos.x + 2, sy + 3, size.x - 4, 3), Color(0, 0, 0, 0.12))
	# Side posts
	draw_rect(Rect2(pos.x, pos.y, 8, size.y), sc.darkened(0.08))
	draw_rect(Rect2(pos.x, pos.y, 2, size.y), Color(1, 1, 1, 0.1))
	draw_rect(Rect2(pos.x + 6, pos.y, 2, size.y), Color(0, 0, 0, 0.06))
	draw_rect(Rect2(pos.x + size.x - 8, pos.y, 8, size.y), sc.darkened(0.08))
	draw_rect(Rect2(pos.x + size.x - 2, pos.y, 2, size.y), Color(0, 0, 0, 0.1))
	draw_rect(Rect2(pos.x + size.x - 8, pos.y, 2, size.y), Color(1, 1, 1, 0.06))
	# Top crown
	draw_rect(Rect2(pos.x - 6, pos.y - 12, size.x + 12, 14), sc.lightened(0.05))
	draw_rect(Rect2(pos.x - 6, pos.y - 12, size.x + 12, 2), Color(1, 1, 1, 0.18))
	draw_rect(Rect2(pos.x - 4, pos.y - 3, size.x + 8, 3), tc.darkened(0.08))
	# Crown notches
	for n in 3:
		var nx = pos.x + 18 + n * ((size.x - 36) / 2.0)
		draw_rect(Rect2(nx, pos.y - 11, 10, 3), tc)
	# Bottom base
	draw_rect(Rect2(pos.x - 3, pos.y + size.y, size.x + 6, 7), sc.darkened(0.12))
	draw_rect(Rect2(pos.x - 3, pos.y + size.y + 5, size.x + 6, 2), Color(0, 0, 0, 0.1))
	# Bold outer border
	draw_rect(Rect2(pos.x - 1, pos.y - 1, size.x + 2, 1), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y + size.y, size.x + 2, 1), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y, 1, size.y), Color(0.12, 0.08, 0.05))
	draw_rect(Rect2(pos.x + size.x, pos.y, 1, size.y), Color(0.12, 0.08, 0.05))
	# Decorative element on top — plant (left) or candle (right)
	var top_y = pos.y - 12
	if pos.x < 360:
		draw_rect(Rect2(pos.x + size.x / 2 - 8, top_y - 14, 16, 14), Color(0.65, 0.4, 0.25))
		draw_rect(Rect2(pos.x + size.x / 2 - 10, top_y - 16, 20, 4), Color(0.58, 0.36, 0.2))
		draw_circle(Vector2(pos.x + size.x / 2 - 4, top_y - 22), 6, Color(0.35, 0.6, 0.3))
		draw_circle(Vector2(pos.x + size.x / 2 + 5, top_y - 20), 5, Color(0.4, 0.65, 0.32))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 27), 4, Color(0.32, 0.55, 0.28))
	else:
		draw_rect(Rect2(pos.x + size.x / 2 - 4, top_y - 20, 8, 20), Color(0.95, 0.92, 0.85))
		draw_rect(Rect2(pos.x + size.x / 2 - 7, top_y - 2, 14, 4), Color(0.7, 0.55, 0.3))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 24), 4, Color(1.0, 0.8, 0.3, 0.8))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 25), 2.5, Color(1.0, 0.95, 0.7, 0.9))
		draw_circle(Vector2(pos.x + size.x / 2, top_y - 22), 12, Color(1.0, 0.85, 0.4, 0.06))
	# Items on shelves
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x * 7 + pos.y)
	var item_colors = [
		Color(0.35, 0.2, 0.12),
		Color(0.95, 0.55, 0.08),
		Color(0.62, 0.08, 0.18),
		Color(0.35, 0.42, 0.55),
		Color(0.85, 0.65, 0.1),
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
			draw_rect(Rect2(ix - 6, sy - 10, 3, 6), Color(1, 1, 1, 0.3))
			draw_rect(Rect2(ix - 5, sy - 8, 2, 3), Color(1, 1, 1, 0.18))

func _draw_back_shelf(pos: Vector2, size: Vector2, sc: Color) -> void:
	draw_rect(Rect2(pos.x - 6, pos.y - 6, size.x + 12, size.y + 12), Color(1.0, 0.85, 0.5, 0.05))
	draw_rect(Rect2(pos.x - 3, pos.y - 3, size.x + 6, size.y + 6), Color(1.0, 0.9, 0.6, 0.06))
	draw_rect(Rect2(pos.x + 4, pos.y + 3, size.x, size.y), Color(0, 0, 0, 0.18))
	DU.draw_wood_planks(self, Rect2(pos, size), sc.darkened(0.05), 2, true)
	draw_rect(Rect2(pos.x, pos.y, size.x, 2), Color(1, 1, 1, 0.16))
	draw_rect(Rect2(pos.x, pos.y + size.y - 2, size.x, 2), Color(0, 0, 0, 0.12))
	draw_rect(Rect2(pos.x - 1, pos.y - 1, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	draw_rect(Rect2(pos.x - 1, pos.y + size.y, size.x + 2, 1), Color(0.15, 0.1, 0.05))
	# Small support pegs
	draw_rect(Rect2(pos.x + 15, pos.y + size.y, 3, 6), Color(0.3, 0.25, 0.2))
	draw_rect(Rect2(pos.x + size.x - 18, pos.y + size.y, 3, 6), Color(0.3, 0.25, 0.2))
	# Items
	var rng = RandomNumberGenerator.new()
	rng.seed = int(pos.x)
	var colors = [Color(0.35, 0.2, 0.12), Color(0.62, 0.08, 0.18), Color(0.95, 0.55, 0.08), Color(0.85, 0.65, 0.1)]
	var spacing = size.x / 5.0
	for i in 4:
		var ix = pos.x + spacing * (i + 0.5)
		var c = colors[i % colors.size()]
		var cy = pos.y + size.y * 0.3
		draw_circle(Vector2(ix, cy), 12, Color(1.0, 0.9, 0.7, 0.04))
		if i == 0:
			draw_rect(Rect2(ix - 5, cy - 6, 10, 12), Color(0.12, 0.08, 0.05))
			draw_rect(Rect2(ix - 4, cy - 5, 8, 10), Color(0.45, 0.6, 0.7))
			draw_circle(Vector2(ix - 3, cy - 9), 3, Color(0.9, 0.4, 0.4))
			draw_circle(Vector2(ix + 2, cy - 10), 2.5, Color(0.95, 0.7, 0.3))
			draw_circle(Vector2(ix, cy - 12), 2, Color(0.9, 0.5, 0.6))
		elif i == 3:
			draw_rect(Rect2(ix - 5, cy - 8, 10, 14), Color(0.12, 0.08, 0.05))
			draw_rect(Rect2(ix - 4, cy - 7, 8, 12), Color(0.65, 0.55, 0.35))
			draw_rect(Rect2(ix - 3, cy - 5, 6, 8), Color(1.0, 0.85, 0.4, 0.5))
			draw_circle(Vector2(ix, cy - 1), 2, Color(1.0, 0.9, 0.5, 0.8))
			draw_rect(Rect2(ix - 2, cy - 10, 4, 3), Color(0.3, 0.28, 0.22))
		else:
			draw_circle(Vector2(ix, cy), 12, Color(0.12, 0.08, 0.05))
			draw_circle(Vector2(ix, cy), 10, c)
		draw_rect(Rect2(ix - 4, cy - 6, 3, 4), Color(1, 1, 1, 0.28))

func _draw_frame(pos: Vector2, size: Vector2, tc: Color) -> void:
	var frame_c = Color(0.45, 0.35, 0.25).lerp(tc.darkened(0.15), _p())
	draw_rect(Rect2(pos.x - 3, pos.y - 3, size.x + 6, size.y + 6), frame_c)
	draw_rect(Rect2(pos, size), Color(0.88, 0.85, 0.78))
	# Level 4+: inner mat border for fancier frames
	if shop_level >= 4:
		draw_rect(Rect2(pos.x + 3, pos.y + 3, size.x - 6, size.y - 6), Color(0.82, 0.78, 0.72))

func _draw_window(pos: Vector2, size: Vector2, tc: Color) -> void:
	draw_rect(Rect2(pos.x - 4, pos.y - 4, size.x + 8, size.y + 8), tc)
	draw_rect(Rect2(pos, size), Color(0.7, 0.82, 0.9, 0.6))
	draw_rect(Rect2(pos.x + size.x / 2 - 1.5, pos.y, 3, size.y), tc)
	draw_rect(Rect2(pos.x, pos.y + size.y / 2 - 1.5, size.x, 3), tc)
	draw_line(pos + Vector2(8, 8), pos + Vector2(20, 5), Color(1, 1, 1, 0.3), 2)

func _draw_rug(pos: Vector2, size: Vector2) -> void:
	var p = _p()
	var rug_outer = Color(0.6, 0.35, 0.3, 0.6).lerp(Color(0.65, 0.38, 0.32, 0.7), p)
	var rug_mid = Color(0.65, 0.4, 0.32, 0.6).lerp(Color(0.7, 0.42, 0.35, 0.7), p)
	var rug_inner = Color(0.7, 0.45, 0.35, 0.6).lerp(Color(0.75, 0.48, 0.38, 0.7), p)
	DU.draw_ellipse(self, Rect2(pos, size), rug_outer)
	DU.draw_ellipse(self, Rect2(pos.x + 15, pos.y + 10, size.x - 30, size.y - 20), rug_mid)
	DU.draw_ellipse(self, Rect2(pos.x + 30, pos.y + 20, size.x - 60, size.y - 40), rug_inner)
