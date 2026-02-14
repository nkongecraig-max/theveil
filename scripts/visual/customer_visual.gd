extends Node2D

## CustomerVisual - Draws customer NPC characters procedurally.
## Each customer gets unique appearance based on their color + name.

const DU = preload("res://scripts/visual/draw_utils.gd")

var body_color := Color(0.6, 0.75, 0.65)
var hair_color := Color(0.3, 0.25, 0.2)
var hair_style: int = 0  # 0=short, 1=long, 2=bun, 3=spiky
var accessory: int = 0   # 0=none, 1=hat, 2=scarf, 3=glasses
var is_walking := false
var walk_cycle: float = 0.0
var facing_left := false

func setup_appearance(color: Color, customer_name: String) -> void:
	body_color = color
	# Derive hair + style from name hash
	var h = customer_name.hash()
	hair_style = absi(h) % 4
	accessory = absi(h >> 4) % 4
	hair_color = Color(
		fmod(abs(sin(float(h) * 0.1)), 0.5) + 0.15,
		fmod(abs(cos(float(h) * 0.2)), 0.4) + 0.1,
		fmod(abs(sin(float(h) * 0.3)), 0.3) + 0.08,
	)

func _process(delta: float) -> void:
	var parent = get_parent()
	if parent and parent is CharacterBody2D and parent.velocity.length() > 10:
		is_walking = true
		if parent.velocity.x < -5:
			facing_left = true
		elif parent.velocity.x > 5:
			facing_left = false
		walk_cycle += delta * 7.0
	else:
		is_walking = false
	queue_redraw()

func _draw() -> void:
	var bob = sin(walk_cycle) * 1.5 if is_walking else 0.0

	# Shadow
	DU.draw_ellipse(self, Rect2(-14, 16 + bob, 28, 8), Color(0, 0, 0, 0.15))

	var sx = -1.0 if facing_left else 1.0

	# Legs
	var leg_anim = sin(walk_cycle) * 2.5 if is_walking else 0.0
	draw_rect(Rect2(-7 - leg_anim, 10 + bob, 6, 9), body_color.darkened(0.25))
	draw_rect(Rect2(1 + leg_anim, 10 + bob, 6, 9), body_color.darkened(0.25))
	# Shoes
	draw_rect(Rect2(-8 - leg_anim, 17 + bob, 8, 5), Color(0.35, 0.28, 0.22))
	draw_rect(Rect2(0 + leg_anim, 17 + bob, 8, 5), Color(0.35, 0.28, 0.22))

	# Body
	draw_rect(Rect2(-10, -5 + bob, 20, 17), body_color)
	# Shirt detail/pattern
	draw_rect(Rect2(-10, -5 + bob, 20, 3), body_color.lightened(0.08))
	draw_rect(Rect2(-2, -2 + bob, 4, 10), body_color.lightened(0.05))

	# Arms
	var arm_swing = sin(walk_cycle) * 4.0 if is_walking else 0.0
	draw_rect(Rect2(-13, -3 + bob - arm_swing, 5, 12), body_color.darkened(0.08))
	draw_rect(Rect2(8, -3 + bob + arm_swing, 5, 12), body_color.darkened(0.08))
	# Hands
	draw_circle(Vector2(-10.5, 10 + bob - arm_swing), 2.5, Color(0.82, 0.68, 0.55))
	draw_circle(Vector2(10.5, 10 + bob + arm_swing), 2.5, Color(0.82, 0.68, 0.55))

	# Head
	var skin = Color(0.82, 0.68, 0.55)
	draw_circle(Vector2(0, -14 + bob), 10, skin)

	# Hair by style
	match hair_style:
		0:  # Short
			draw_arc(Vector2(0, -18 + bob), 9, deg_to_rad(180), deg_to_rad(370), 12, hair_color, 4)
		1:  # Long
			draw_arc(Vector2(0, -18 + bob), 9, deg_to_rad(150), deg_to_rad(390), 12, hair_color, 5)
			draw_rect(Rect2(-10, -20 + bob, 4, 16), hair_color)
			draw_rect(Rect2(6, -20 + bob, 4, 16), hair_color)
		2:  # Bun
			draw_arc(Vector2(0, -18 + bob), 9, deg_to_rad(180), deg_to_rad(360), 12, hair_color, 4)
			draw_circle(Vector2(0, -25 + bob), 5, hair_color)
		3:  # Spiky
			for i in 5:
				var angle = deg_to_rad(200 + i * 35)
				var spike_pos = Vector2(cos(angle) * 10, sin(angle) * 10 - 14 + bob)
				var spike_end = Vector2(cos(angle) * 15, sin(angle) * 15 - 14 + bob)
				draw_line(spike_pos, spike_end, hair_color, 3)

	# Eyes
	draw_circle(Vector2(-3.5 * sx, -15 + bob), 1.8, Color(0.15, 0.12, 0.1))
	draw_circle(Vector2(3.5 * sx, -15 + bob), 1.8, Color(0.15, 0.12, 0.1))
	draw_circle(Vector2(-3 * sx, -15.5 + bob), 0.7, Color(1, 1, 1, 0.6))
	draw_circle(Vector2(4 * sx, -15.5 + bob), 0.7, Color(1, 1, 1, 0.6))

	# Mouth
	draw_arc(Vector2(0, -10 + bob), 2.5, deg_to_rad(10), deg_to_rad(170), 6, Color(0.55, 0.3, 0.25), 1.0)

	# Accessory
	match accessory:
		1:  # Hat
			draw_rect(Rect2(-12, -26 + bob, 24, 4), body_color.darkened(0.2))
			draw_rect(Rect2(-8, -34 + bob, 16, 10), body_color.darkened(0.15))
		2:  # Scarf
			draw_rect(Rect2(-11, -6 + bob, 22, 5), Color(0.8, 0.3, 0.3))
			draw_rect(Rect2(8, -4 + bob, 5, 12), Color(0.8, 0.3, 0.3))
		3:  # Glasses
			draw_circle(Vector2(-4, -15 + bob), 4, Color(0.3, 0.3, 0.3))
			draw_circle(Vector2(4, -15 + bob), 4, Color(0.3, 0.3, 0.3))
			draw_circle(Vector2(-4, -15 + bob), 3, Color(0.7, 0.8, 0.9, 0.3))
			draw_circle(Vector2(4, -15 + bob), 3, Color(0.7, 0.8, 0.9, 0.3))
			draw_line(Vector2(-8, -15 + bob), Vector2(-4, -15 + bob), Color(0.3, 0.3, 0.3), 1)
			draw_line(Vector2(4, -15 + bob), Vector2(8, -15 + bob), Color(0.3, 0.3, 0.3), 1)
			draw_line(Vector2(0, -15 + bob), Vector2(0, -15 + bob), Color(0.3, 0.3, 0.3), 1)
