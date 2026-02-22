extends Node2D

## PlayerVisual - Draws the player character procedurally.
## Replaces the ColorRect placeholder with a cute character.

const DU = preload("res://scripts/visual/draw_utils.gd")

var body_color := Color(0.45, 0.35, 0.75)
var hair_color := Color(0.2, 0.15, 0.3)
var facing_left := false
var is_walking := false
var walk_cycle: float = 0.0
var idle_time: float = 0.0

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
	# Idle breathing bob — gentle up/down
	var idle_bob = sin(idle_time * 1.8) * 1.2 if not is_walking else 0.0
	var bob = sin(walk_cycle) * 2.0 if is_walking else idle_bob
	var lean = sin(walk_cycle * 0.5) * 1.5 if is_walking else 0.0

	# Shadow
	DU.draw_ellipse(self, Rect2(-16, 16 + bob, 32, 10), Color(0, 0, 0, 0.18))

	var sx = -1.0 if facing_left else 1.0

	# Legs
	var leg_spread = sin(walk_cycle) * 3.0 if is_walking else 0.0
	draw_rect(Rect2(-8 - leg_spread, 10 + bob, 7, 10), Color(0.35, 0.3, 0.45))
	draw_rect(Rect2(1 + leg_spread, 10 + bob, 7, 10), Color(0.35, 0.3, 0.45))
	# Shoes
	draw_rect(Rect2(-9 - leg_spread, 18 + bob, 9, 5), Color(0.3, 0.22, 0.18))
	draw_rect(Rect2(0 + leg_spread, 18 + bob, 9, 5), Color(0.3, 0.22, 0.18))

	# Body outline
	draw_rect(Rect2(-12 + lean, -7 + bob, 24, 20), Color(0.12, 0.1, 0.08))
	# Body / shirt
	draw_rect(Rect2(-11 + lean, -6 + bob, 22, 18), body_color)
	# Shirt collar
	draw_rect(Rect2(-6 + lean, -8 + bob, 12, 4), body_color.lightened(0.12))
	# Apron (shopkeeper!)
	draw_rect(Rect2(-9 + lean, 0 + bob, 18, 12), Color(0.9, 0.85, 0.75))
	draw_rect(Rect2(-4 + lean, -2 + bob, 8, 3), Color(0.9, 0.85, 0.75))
	# Apron pocket
	draw_rect(Rect2(-3 + lean, 4 + bob, 6, 5), Color(0.85, 0.8, 0.7))

	# Arms
	var arm_swing = sin(walk_cycle) * 5.0 if is_walking else 0.0
	draw_rect(Rect2(-14 + lean, -4 + bob - arm_swing, 5, 14), body_color.darkened(0.05))
	draw_rect(Rect2(9 + lean, -4 + bob + arm_swing, 5, 14), body_color.darkened(0.05))
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
	# Eyes — blink every ~3 seconds when idle, or based on walk cycle
	var blink_timer = idle_time if not is_walking else walk_cycle
	var blink = fmod(blink_timer, 3.2) < 0.12
	if blink:
		draw_line(Vector2(-4 * sx + lean, -17 + bob), Vector2(-2 * sx + lean, -17 + bob), Color(0.15, 0.12, 0.1), 1.5)
		draw_line(Vector2(4 * sx + lean, -17 + bob), Vector2(2 * sx + lean, -17 + bob), Color(0.15, 0.12, 0.1), 1.5)
	else:
		# Eye whites
		draw_circle(Vector2(-4 * sx + lean, -17 + bob), 3, Color(1, 1, 1))
		draw_circle(Vector2(4 * sx + lean, -17 + bob), 3, Color(1, 1, 1))
		# Pupils
		draw_circle(Vector2(-4 * sx + lean, -17 + bob), 2, Color(0.12, 0.1, 0.08))
		draw_circle(Vector2(4 * sx + lean, -17 + bob), 2, Color(0.12, 0.1, 0.08))
		# Eye shine
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
