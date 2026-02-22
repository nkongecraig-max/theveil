extends Node2D

## PlayerVisual - Draws the player character procedurally.
## Outfit and details evolve with player level.

const DU = preload("res://scripts/visual/draw_utils.gd")

var body_color := Color(0.45, 0.35, 0.75)
var hair_color := Color(0.2, 0.15, 0.3)
var facing_left := false
var is_walking := false
var walk_cycle: float = 0.0
var idle_time: float = 0.0
var player_level: int = 1

func set_level(level: int) -> void:
	player_level = level
	# No queue_redraw needed — _process does it every frame

func _process(delta: float) -> void:
	var parent = get_parent()
	if parent and parent.velocity.length() > 10:
		is_walking = true
		idle_time = 0.0
		if parent.velocity.x < -5:
			facing_left = true
		elif parent.velocity.x > 5:
			facing_left = false
		walk_cycle += delta * 8.0
	else:
		is_walking = false
		walk_cycle = 0.0
		idle_time += delta
	queue_redraw()

func _draw() -> void:
	var p = clampf((player_level - 1) / 9.0, 0.0, 1.0)

	# Idle breathing bob
	var idle_bob = sin(idle_time * 1.8) * 1.2 if not is_walking else 0.0
	var bob = sin(walk_cycle) * 2.0 if is_walking else idle_bob
	var lean = sin(walk_cycle * 0.5) * 1.5 if is_walking else 0.0

	# Shadow
	DU.draw_ellipse(self, Rect2(-16, 16 + bob, 32, 10), Color(0, 0, 0, 0.18))

	var sx = -1.0 if facing_left else 1.0

	# --- Evolving colors ---
	var shirt_c = body_color.lerp(Color(0.38, 0.28, 0.65), p)  # Deeper purple
	var pants_c = Color(0.35, 0.3, 0.45).lerp(Color(0.28, 0.24, 0.38), p)
	var shoe_c = Color(0.3, 0.22, 0.18).lerp(Color(0.38, 0.26, 0.18), p)
	var apron_c = Color(0.9, 0.85, 0.75).lerp(Color(0.95, 0.9, 0.7), p)
	var apron_pocket_c = Color(0.85, 0.8, 0.7).lerp(Color(0.9, 0.85, 0.65), p)

	# Legs
	var leg_spread = sin(walk_cycle) * 3.0 if is_walking else 0.0
	draw_rect(Rect2(-8 - leg_spread, 10 + bob, 7, 10), pants_c)
	draw_rect(Rect2(1 + leg_spread, 10 + bob, 7, 10), pants_c)
	# Shoes
	draw_rect(Rect2(-9 - leg_spread, 18 + bob, 9, 5), shoe_c)
	draw_rect(Rect2(0 + leg_spread, 18 + bob, 9, 5), shoe_c)
	# Level 5+: Polished shoe highlight
	if player_level >= 5:
		draw_rect(Rect2(-8 - leg_spread, 18 + bob, 4, 2), Color(1, 1, 1, 0.15))
		draw_rect(Rect2(1 + leg_spread, 18 + bob, 4, 2), Color(1, 1, 1, 0.15))

	# Body outline
	draw_rect(Rect2(-12 + lean, -7 + bob, 24, 20), Color(0.12, 0.1, 0.08))
	# Body / shirt
	draw_rect(Rect2(-11 + lean, -6 + bob, 22, 18), shirt_c)
	# Level 7+: Shirt stitching detail
	if player_level >= 7:
		draw_rect(Rect2(-11 + lean, 2 + bob, 22, 1), shirt_c.lightened(0.1))
	# Shirt collar
	draw_rect(Rect2(-6 + lean, -8 + bob, 12, 4), shirt_c.lightened(0.12))
	# Level 8+: Collar gets a subtle gold trim
	if player_level >= 8:
		draw_rect(Rect2(-6 + lean, -8 + bob, 12, 1), Color(0.85, 0.7, 0.35, 0.5))

	# Apron
	draw_rect(Rect2(-9 + lean, 0 + bob, 18, 12), apron_c)
	draw_rect(Rect2(-4 + lean, -2 + bob, 8, 3), apron_c)
	# Level 4+: Apron gets a colored trim on the edge
	if player_level >= 4:
		var trim_c = Color(0.75, 0.55, 0.3, 0.6).lerp(Color(0.85, 0.65, 0.3, 0.8), p)
		draw_rect(Rect2(-9 + lean, 11 + bob, 18, 1), trim_c)
	# Level 9+: Full gold-trimmed apron edges
	if player_level >= 9:
		var gold = Color(0.9, 0.75, 0.3, 0.5)
		draw_rect(Rect2(-9 + lean, 0 + bob, 1, 12), gold)
		draw_rect(Rect2(8 + lean, 0 + bob, 1, 12), gold)

	# Apron pocket
	draw_rect(Rect2(-3 + lean, 4 + bob, 6, 5), apron_pocket_c)

	# Text on apron — evolves with level
	var font = ThemeDB.fallback_font
	if font:
		var fsize = 6
		var shop_text = "SHOP"
		if player_level >= 6:
			shop_text = "MASTER"
			fsize = 5
		elif player_level >= 3:
			shop_text = "PRO"
		var tw = font.get_string_size(shop_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize)
		var text_c = Color(0.55, 0.45, 0.35, 0.7).lerp(Color(0.65, 0.5, 0.25, 0.85), p)
		draw_string(font, Vector2(-tw.x / 2 + lean, -1 + bob), shop_text, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, text_c)

	# Level 3+: Small badge/pin on apron strap
	if player_level >= 3:
		var badge_c = Color(0.85, 0.7, 0.3).lerp(Color(0.95, 0.8, 0.35), p)
		draw_circle(Vector2(-3 + lean, -1 + bob), 2, badge_c)
		if player_level >= 6:
			draw_circle(Vector2(-3 + lean, -1 + bob), 1, Color(1, 1, 0.9, 0.6))

	# Arms
	var arm_swing = sin(walk_cycle) * 5.0 if is_walking else 0.0
	draw_rect(Rect2(-14 + lean, -4 + bob - arm_swing, 5, 14), shirt_c.darkened(0.05))
	draw_rect(Rect2(9 + lean, -4 + bob + arm_swing, 5, 14), shirt_c.darkened(0.05))
	# Hands
	draw_circle(Vector2(-11.5 + lean, 11 + bob - arm_swing), 3, Color(0.85, 0.72, 0.58))
	draw_circle(Vector2(11.5 + lean, 11 + bob + arm_swing), 3, Color(0.85, 0.72, 0.58))

	# Head outline + head
	draw_circle(Vector2(lean, -16 + bob), 12, Color(0.12, 0.1, 0.08))
	draw_circle(Vector2(lean, -16 + bob), 11, Color(0.88, 0.75, 0.6))
	# Hair
	draw_arc(Vector2(lean, -20 + bob), 10, deg_to_rad(180), deg_to_rad(380), 14, hair_color, 5)
	# Side hair
	draw_rect(Rect2(-11 + lean, -22 + bob, 4, 10), hair_color)
	draw_rect(Rect2(7 + lean, -22 + bob, 4, 10), hair_color)

	# Face
	var blink_timer = idle_time if not is_walking else walk_cycle
	var blink = fmod(blink_timer, 3.2) < 0.12
	if blink:
		draw_line(Vector2(-4 * sx + lean, -17 + bob), Vector2(-2 * sx + lean, -17 + bob), Color(0.15, 0.12, 0.1), 1.5)
		draw_line(Vector2(4 * sx + lean, -17 + bob), Vector2(2 * sx + lean, -17 + bob), Color(0.15, 0.12, 0.1), 1.5)
	else:
		draw_circle(Vector2(-4 * sx + lean, -17 + bob), 3, Color(1, 1, 1))
		draw_circle(Vector2(4 * sx + lean, -17 + bob), 3, Color(1, 1, 1))
		draw_circle(Vector2(-4 * sx + lean, -17 + bob), 2, Color(0.12, 0.1, 0.08))
		draw_circle(Vector2(4 * sx + lean, -17 + bob), 2, Color(0.12, 0.1, 0.08))
		draw_circle(Vector2(-3.5 * sx + lean, -17.8 + bob), 1.0, Color(1, 1, 1, 0.9))
		draw_circle(Vector2(4.5 * sx + lean, -17.8 + bob), 1.0, Color(1, 1, 1, 0.9))

	# Nose
	draw_circle(Vector2(lean, -14 + bob), 1.2, Color(0.78, 0.65, 0.52))

	# Mouth
	if is_walking:
		draw_arc(Vector2(lean, -11 + bob), 3, deg_to_rad(20), deg_to_rad(160), 6, Color(0.6, 0.35, 0.3), 1.2)
	else:
		draw_arc(Vector2(lean, -11.5 + bob), 2.5, deg_to_rad(10), deg_to_rad(170), 6, Color(0.6, 0.35, 0.3), 1.2)

	# Cheek blush
	DU.draw_ellipse(self, Rect2(-9 + lean, -15 + bob, 5, 3), Color(0.9, 0.6, 0.55, 0.25))
	DU.draw_ellipse(self, Rect2(4 + lean, -15 + bob, 5, 3), Color(0.9, 0.6, 0.55, 0.25))

	# Level 10+: Subtle golden aura around the character
	if player_level >= 10:
		draw_circle(Vector2(lean, 0 + bob), 28, Color(1.0, 0.9, 0.5, 0.04))
		draw_circle(Vector2(lean, -5 + bob), 22, Color(1.0, 0.85, 0.4, 0.05))
