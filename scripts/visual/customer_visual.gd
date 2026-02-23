extends Node2D

## CustomerVisual - Draws customer NPC characters procedurally.
## Each customer gets a unique appearance based on their shirt color + name hash.
## Diversity system: body types, skin tones, hair styles, clothing patterns,
## accessories, and accessibility features (wheelchair, cane, service dog).

const DU = preload("res://scripts/visual/draw_utils.gd")

# -- Skin tone palette (6 diverse tones) --
const SKIN_TONES: Array[Color] = [
	Color(0.93, 0.80, 0.68),  # Light
	Color(0.85, 0.68, 0.55),  # Medium light
	Color(0.72, 0.55, 0.42),  # Medium
	Color(0.55, 0.40, 0.30),  # Medium dark
	Color(0.40, 0.28, 0.20),  # Dark
	Color(0.30, 0.22, 0.16),  # Deep
]

# -- Body type enum --
enum BodyType { SLIM, AVERAGE, STOCKY, TALL }

# -- Appearance vars --
var body_color := Color(0.6, 0.75, 0.65)   # Shirt color (passed in via setup)
var skin_color := Color(0.85, 0.68, 0.55)   # Derived from hash
var hair_color := Color(0.3, 0.25, 0.2)
var hair_style: int = 0       # 0..7
var accessory: int = 0        # 0..5
var body_type: int = BodyType.AVERAGE
var clothing_style: int = 0   # 0=solid, 1=v-neck, 2=h-stripe, 3=collar

# -- Accessibility features --
var has_wheelchair := false
var has_cane := false
var has_service_dog := false

# -- Animation / state --
var is_walking := false
var walk_cycle: float = 0.0
var facing_left := false
var customer_name: String = ""

# -- Accessory color (derived from hash for scarf, hat, etc.) --
var accessory_color := Color(0.8, 0.3, 0.3)

# -- Service dog colors --
var dog_body_color := Color(0.6, 0.45, 0.3)
var dog_vest_color := Color(0.2, 0.4, 0.8)


func setup_appearance(color: Color, cname: String) -> void:
	body_color = color  # This is the shirt color
	customer_name = cname

	var h = cname.hash()
	var bits = absi(h)

	# Body type from bits 0-1
	body_type = bits % 4

	# Skin tone from bits 2-4
	skin_color = SKIN_TONES[(bits >> 2) % SKIN_TONES.size()]

	# Hair style from bits 5-7 (8 styles)
	hair_style = (bits >> 5) % 8

	# Accessory from bits 8-10 (6 options)
	accessory = (bits >> 8) % 6

	# Clothing style from bits 11-12
	clothing_style = (bits >> 11) % 4

	# Hair color — derived procedurally from hash
	hair_color = Color(
		fmod(abs(sin(float(h) * 0.1)), 0.5) + 0.15,
		fmod(abs(cos(float(h) * 0.2)), 0.4) + 0.1,
		fmod(abs(sin(float(h) * 0.3)), 0.3) + 0.08,
	)

	# Accessory color — warm random tint
	accessory_color = Color(
		fmod(abs(cos(float(h) * 0.4)), 0.5) + 0.35,
		fmod(abs(sin(float(h) * 0.5)), 0.5) + 0.15,
		fmod(abs(cos(float(h) * 0.6)), 0.5) + 0.1,
	)

	# Accessibility features — use higher hash bits
	# ~10% wheelchair (bits 13-16 range), ~10% cane, ~8% service dog
	var wheel_bits = (bits >> 13) % 100
	has_wheelchair = wheel_bits < 10

	var cane_bits = (bits >> 17) % 100
	has_cane = cane_bits < 10 and not has_wheelchair  # Don't combine wheelchair + cane

	var dog_bits = (bits >> 21) % 100
	has_service_dog = dog_bits < 8

	# Service dog colors
	var dog_hue = (bits >> 25) % 4
	match dog_hue:
		0: dog_body_color = Color(0.6, 0.45, 0.3)    # Brown
		1: dog_body_color = Color(0.25, 0.22, 0.18)   # Black
		2: dog_body_color = Color(0.85, 0.78, 0.65)   # Golden
		3: dog_body_color = Color(0.5, 0.5, 0.48)     # Grey


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
	var sx = -1.0 if facing_left else 1.0

	# -- Body dimensions based on body type --
	var bw: float   # body width (half-width used for centering)
	var bh: float   # body (torso) height
	var leg_h: float
	var head_r: float
	var overall_scale: float = 1.0

	match body_type:
		BodyType.SLIM:
			bw = 16.0
			bh = 18.0
			leg_h = 10.0
			head_r = 10.0
		BodyType.AVERAGE:
			bw = 20.0
			bh = 17.0
			leg_h = 9.0
			head_r = 10.0
		BodyType.STOCKY:
			bw = 24.0
			bh = 17.0
			leg_h = 7.0
			head_r = 10.0
		BodyType.TALL:
			bw = 20.0
			bh = 19.0
			leg_h = 11.0
			head_r = 11.0
			overall_scale = 1.08
		_:
			bw = 20.0
			bh = 17.0
			leg_h = 9.0
			head_r = 10.0

	var hw = bw / 2.0  # half-width
	var body_top = -6.0 * overall_scale
	var body_bottom = body_top + bh
	var leg_top = body_bottom
	var shoe_h = 5.0

	# -- Shadow --
	var shadow_w = bw + 8.0
	DU.draw_ellipse(self, Rect2(-shadow_w / 2.0, leg_top + leg_h + shoe_h - 2 + bob, shadow_w, 8), Color(0, 0, 0, 0.15))

	# -- Wheelchair (drawn behind character if applicable) --
	if has_wheelchair:
		_draw_wheelchair(bob, hw, body_bottom, overall_scale)
	else:
		# -- Legs (only if not in wheelchair) --
		var leg_anim = sin(walk_cycle) * 2.5 if is_walking else 0.0
		var leg_w = 6.0
		var leg_gap = 1.0
		# Left leg
		draw_rect(Rect2(-hw / 2.0 - leg_w / 2.0 - leg_anim, leg_top + bob, leg_w, leg_h), body_color.darkened(0.25))
		# Right leg
		draw_rect(Rect2(hw / 2.0 - leg_w / 2.0 + leg_anim, leg_top + bob, leg_w, leg_h), body_color.darkened(0.25))
		# Shoes
		var shoe_color = Color(0.35, 0.28, 0.22)
		draw_rect(Rect2(-hw / 2.0 - leg_w / 2.0 - 1 - leg_anim, leg_top + leg_h + bob, leg_w + 2, shoe_h), shoe_color)
		draw_rect(Rect2(hw / 2.0 - leg_w / 2.0 - 1 + leg_anim, leg_top + leg_h + bob, leg_w + 2, shoe_h), shoe_color)

	# -- Body outline --
	draw_rect(Rect2(-hw - 1, body_top - 1 + bob, bw + 2, bh + 2), Color(0.12, 0.1, 0.08))
	# -- Body (shirt) --
	draw_rect(Rect2(-hw, body_top + bob, bw, bh), body_color)

	# -- Clothing style details --
	_draw_clothing(bob, hw, bw, bh, body_top)

	# -- Name on shirt --
	var font = ThemeDB.fallback_font
	if font and customer_name != "":
		var fsize = 7
		var tw = font.get_string_size(customer_name, HORIZONTAL_ALIGNMENT_CENTER, -1, fsize)
		var tx = -tw.x / 2
		var ty = body_top + bh - 3 + bob
		draw_string(font, Vector2(tx, ty), customer_name, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, body_color.darkened(0.35))

	# -- Arms --
	var arm_w = 5.0
	var arm_h = 12.0 * overall_scale
	var arm_swing = sin(walk_cycle) * 4.0 if is_walking else 0.0
	draw_rect(Rect2(-hw - arm_w + 2, body_top + 3 + bob - arm_swing, arm_w, arm_h), body_color.darkened(0.08))
	draw_rect(Rect2(hw - 2, body_top + 3 + bob + arm_swing, arm_w, arm_h), body_color.darkened(0.08))
	# Hands (skin colored)
	var hand_r = 2.5
	draw_circle(Vector2(-hw - arm_w / 2.0 + 2, body_top + 3 + arm_h + bob - arm_swing), hand_r, skin_color)
	draw_circle(Vector2(hw + arm_w / 2.0 - 2, body_top + 3 + arm_h + bob + arm_swing), hand_r, skin_color)

	# -- Head --
	var head_y = body_top - head_r - 4 + bob
	# Head outline
	draw_circle(Vector2(0, head_y), head_r + 1, Color(0.12, 0.1, 0.08))
	# Head fill (skin tone)
	draw_circle(Vector2(0, head_y), head_r, skin_color)

	# -- Hair --
	_draw_hair(bob, head_y, head_r, sx)

	# -- Eyes (whites, pupils, shine) --
	var eye_y = head_y - 1
	draw_circle(Vector2(-3.5 * sx, eye_y), 2.8, Color(1, 1, 1))
	draw_circle(Vector2(3.5 * sx, eye_y), 2.8, Color(1, 1, 1))
	draw_circle(Vector2(-3.5 * sx, eye_y), 1.8, Color(0.12, 0.1, 0.08))
	draw_circle(Vector2(3.5 * sx, eye_y), 1.8, Color(0.12, 0.1, 0.08))
	draw_circle(Vector2(-3.0 * sx, eye_y - 0.5), 0.9, Color(1, 1, 1, 0.9))
	draw_circle(Vector2(4.0 * sx, eye_y - 0.5), 0.9, Color(1, 1, 1, 0.9))

	# -- Mouth --
	var mouth_y = head_y + head_r * 0.4
	draw_arc(Vector2(0, mouth_y), 2.5, deg_to_rad(10), deg_to_rad(170), 6, Color(0.55, 0.3, 0.25), 1.0)

	# -- Accessory --
	_draw_accessory(bob, head_y, head_r, hw, body_top, sx)

	# -- Cane (drawn in front, to the side) --
	if has_cane and not has_wheelchair:
		_draw_cane(bob, leg_top, leg_h, shoe_h, hw, sx)

	# -- Service dog (drawn to the side) --
	if has_service_dog:
		_draw_service_dog(bob, leg_top + leg_h + shoe_h, hw, sx)


# ============================================================
# CLOTHING PATTERNS
# ============================================================
func _draw_clothing(bob: float, hw: float, bw: float, bh: float, body_top: float) -> void:
	match clothing_style:
		0:
			# Solid — subtle shoulder highlight
			draw_rect(Rect2(-hw, body_top + bob, bw, 3), body_color.lightened(0.08))
			draw_rect(Rect2(-2, body_top + 3 + bob, 4, bh - 6), body_color.lightened(0.05))
		1:
			# V-neck line
			draw_rect(Rect2(-hw, body_top + bob, bw, 3), body_color.lightened(0.08))
			var neck_top = Vector2(0, body_top + bob)
			var neck_left = Vector2(-4, body_top + 7 + bob)
			var neck_right = Vector2(4, body_top + 7 + bob)
			draw_line(neck_top, neck_left, skin_color.darkened(0.05), 2.0)
			draw_line(neck_top, neck_right, skin_color.darkened(0.05), 2.0)
			# Small skin triangle for v-neck opening
			draw_colored_polygon(PackedVector2Array([neck_top, neck_left, neck_right]), skin_color.darkened(0.02))
		2:
			# Horizontal stripe
			var stripe_color = body_color.lightened(0.2)
			var stripe_h = 3.0
			var y = body_top + 2 + bob
			while y < body_top + bh - 2 + bob:
				draw_rect(Rect2(-hw, y, bw, stripe_h), stripe_color)
				y += stripe_h * 2
		3:
			# Collar
			draw_rect(Rect2(-hw, body_top + bob, bw, 3), body_color.lightened(0.08))
			# Collar flaps
			var collar_color = body_color.lightened(0.15)
			var collar_pts_l = PackedVector2Array([
				Vector2(-5, body_top + bob),
				Vector2(-2, body_top + bob),
				Vector2(-4, body_top + 6 + bob),
				Vector2(-7, body_top + 4 + bob),
			])
			var collar_pts_r = PackedVector2Array([
				Vector2(2, body_top + bob),
				Vector2(5, body_top + bob),
				Vector2(7, body_top + 4 + bob),
				Vector2(4, body_top + 6 + bob),
			])
			draw_colored_polygon(collar_pts_l, collar_color)
			draw_colored_polygon(collar_pts_r, collar_color)
			# Button line
			for i in 3:
				var by = body_top + 6 + i * 4 + bob
				draw_circle(Vector2(0, by), 1.0, body_color.darkened(0.2))


# ============================================================
# HAIR STYLES (8 total)
# ============================================================
func _draw_hair(bob: float, head_y: float, head_r: float, sx: float) -> void:
	var hr = head_r
	match hair_style:
		0:
			# Short crop
			draw_arc(Vector2(0, head_y - 4), hr - 1, deg_to_rad(180), deg_to_rad(370), 12, hair_color, 4)
		1:
			# Long straight
			draw_arc(Vector2(0, head_y - 4), hr - 1, deg_to_rad(150), deg_to_rad(390), 12, hair_color, 5)
			draw_rect(Rect2(-hr, head_y - 6, 4, 16), hair_color)
			draw_rect(Rect2(hr - 4, head_y - 6, 4, 16), hair_color)
		2:
			# Bun
			draw_arc(Vector2(0, head_y - 4), hr - 1, deg_to_rad(180), deg_to_rad(360), 12, hair_color, 4)
			draw_circle(Vector2(0, head_y - hr - 3), 5, hair_color)
		3:
			# Spiky / locs
			for i in 7:
				var angle = deg_to_rad(170 + i * 30)
				var spike_base = Vector2(cos(angle) * (hr - 1), sin(angle) * (hr - 1) + head_y - 4)
				var spike_tip = Vector2(cos(angle) * (hr + 5), sin(angle) * (hr + 5) + head_y - 4)
				draw_line(spike_base, spike_tip, hair_color, 3)
		4:
			# Afro — big round hair behind head
			draw_circle(Vector2(0, head_y - 2), hr + 6, hair_color)
			# Re-draw head on top so face shows
			draw_circle(Vector2(0, head_y), hr, skin_color)
		5:
			# Braids — top hair + two braid strands
			draw_arc(Vector2(0, head_y - 4), hr - 1, deg_to_rad(160), deg_to_rad(380), 12, hair_color, 5)
			# Left braid
			for i in 5:
				var by = head_y - 2 + i * 4
				var bx_off = -hr + 1 + (i % 2) * 2
				draw_circle(Vector2(bx_off, by), 2.5, hair_color)
			# Right braid
			for i in 5:
				var by = head_y - 2 + i * 4
				var bx_off = hr - 1 - (i % 2) * 2
				draw_circle(Vector2(bx_off, by), 2.5, hair_color)
		6:
			# Hijab / headwrap
			var wrap_color = hair_color.lightened(0.15)
			# Wrap covers top and sides of head
			draw_circle(Vector2(0, head_y - 1), hr + 3, wrap_color)
			# Drape below
			draw_rect(Rect2(-hr - 2, head_y + 2, (hr + 2) * 2, 10), wrap_color)
			# Re-draw face area
			var face_pts = PackedVector2Array([
				Vector2(-hr + 3, head_y - 4),
				Vector2(hr - 3, head_y - 4),
				Vector2(hr - 2, head_y + hr - 4),
				Vector2(-hr + 2, head_y + hr - 4),
			])
			draw_colored_polygon(face_pts, skin_color)
		7:
			# Bald / shaved — just a very subtle shadow on top of head
			draw_arc(Vector2(0, head_y - 3), hr - 1, deg_to_rad(190), deg_to_rad(350), 12, skin_color.darkened(0.06), 2)


# ============================================================
# ACCESSORIES (6 options)
# ============================================================
func _draw_accessory(bob: float, head_y: float, head_r: float, hw: float, body_top: float, sx: float) -> void:
	match accessory:
		0:
			pass  # None
		1:
			# Hat
			draw_rect(Rect2(-head_r - 2, head_y - head_r - 2, (head_r + 2) * 2, 4), accessory_color.darkened(0.2))
			draw_rect(Rect2(-head_r + 2, head_y - head_r - 10, (head_r - 2) * 2, 10), accessory_color.darkened(0.15))
		2:
			# Scarf
			draw_rect(Rect2(-hw, body_top + bob, hw * 2, 5), accessory_color)
			draw_rect(Rect2(hw - 3, body_top + 2 + bob, 5, 12), accessory_color)
		3:
			# Glasses
			var glass_frame = Color(0.3, 0.3, 0.3)
			var glass_lens = Color(0.7, 0.8, 0.9, 0.3)
			var ey = head_y - 1
			draw_circle(Vector2(-4, ey), 4, glass_frame)
			draw_circle(Vector2(4, ey), 4, glass_frame)
			draw_circle(Vector2(-4, ey), 3, glass_lens)
			draw_circle(Vector2(4, ey), 3, glass_lens)
			draw_line(Vector2(-8, ey), Vector2(-4, ey), glass_frame, 1)
			draw_line(Vector2(4, ey), Vector2(8, ey), glass_frame, 1)
			draw_line(Vector2(-1, ey), Vector2(1, ey), glass_frame, 1)
		4:
			# Earrings — small circles on each side of head
			var ear_y = head_y + 2
			var earring_color = Color(0.85, 0.72, 0.3)  # Gold
			draw_circle(Vector2(-head_r - 1, ear_y), 2.0, earring_color)
			draw_circle(Vector2(head_r + 1, ear_y), 2.0, earring_color)
			# Inner shine
			draw_circle(Vector2(-head_r - 1, ear_y - 0.5), 0.8, Color(1, 0.95, 0.7))
			draw_circle(Vector2(head_r + 1, ear_y - 0.5), 0.8, Color(1, 0.95, 0.7))
		5:
			# Necklace — small arc at neckline
			var neck_y = body_top + 2 + bob
			draw_arc(Vector2(0, neck_y), 6, deg_to_rad(10), deg_to_rad(170), 8, Color(0.85, 0.72, 0.3), 1.5)
			# Pendant
			draw_circle(Vector2(0, neck_y + 5), 2.0, Color(0.85, 0.72, 0.3))
			draw_circle(Vector2(0, neck_y + 5), 1.0, Color(0.6, 0.15, 0.15))


# ============================================================
# WHEELCHAIR
# ============================================================
func _draw_wheelchair(bob: float, hw: float, body_bottom: float, scale: float) -> void:
	var chair_color = Color(0.35, 0.35, 0.4)
	var wheel_r = 9.0
	var seat_y = body_bottom + bob
	var wheel_y = seat_y + 6

	# -- Wheels --
	# Left wheel
	draw_circle(Vector2(-hw + 2, wheel_y), wheel_r, chair_color)
	draw_circle(Vector2(-hw + 2, wheel_y), wheel_r - 2, Color(0.55, 0.55, 0.6))
	draw_circle(Vector2(-hw + 2, wheel_y), 2.0, chair_color)
	# Right wheel
	draw_circle(Vector2(hw - 2, wheel_y), wheel_r, chair_color)
	draw_circle(Vector2(hw - 2, wheel_y), wheel_r - 2, Color(0.55, 0.55, 0.6))
	draw_circle(Vector2(hw - 2, wheel_y), 2.0, chair_color)
	# Small front caster wheels
	draw_circle(Vector2(-hw + 12, wheel_y + 5), 3.0, chair_color)
	draw_circle(Vector2(hw - 12, wheel_y + 5), 3.0, chair_color)

	# -- Seat frame --
	draw_rect(Rect2(-hw + 4, seat_y - 2, hw * 2 - 8, 4), chair_color)
	# Back rest
	draw_rect(Rect2(-hw + 2, seat_y - 14, 3, 14), chair_color)
	# Armrests
	draw_rect(Rect2(-hw + 2, seat_y - 4, hw * 2 - 4, 2), Color(0.3, 0.3, 0.35))

	# -- Wheel spokes (simplified) --
	for w_x in [Vector2(-hw + 2, wheel_y), Vector2(hw - 2, wheel_y)]:
		for i in 4:
			var angle = i * PI / 4.0
			var spoke_end = w_x + Vector2(cos(angle) * (wheel_r - 2), sin(angle) * (wheel_r - 2))
			draw_line(w_x, spoke_end, chair_color.lightened(0.1), 1.0)


# ============================================================
# CANE
# ============================================================
func _draw_cane(bob: float, leg_top: float, leg_h: float, shoe_h: float, hw: float, sx: float) -> void:
	var cane_color = Color(0.45, 0.3, 0.18)
	var cane_x = (hw + 8) * sx
	var cane_top = leg_top - 6 + bob
	var cane_bottom = leg_top + leg_h + shoe_h + bob
	var cane_length = cane_bottom - cane_top

	# Cane shaft
	draw_line(Vector2(cane_x, cane_top), Vector2(cane_x, cane_bottom), cane_color, 2.0)
	# Handle (curved top)
	draw_arc(Vector2(cane_x - 4 * sx, cane_top), 4, deg_to_rad(-90) if sx > 0 else deg_to_rad(90), deg_to_rad(90) if sx > 0 else deg_to_rad(270), 6, cane_color, 2.0)
	# Rubber tip
	draw_rect(Rect2(cane_x - 1.5, cane_bottom - 2, 3, 3), Color(0.25, 0.25, 0.25))


# ============================================================
# SERVICE DOG
# ============================================================
func _draw_service_dog(bob: float, ground_y: float, hw: float, sx: float) -> void:
	# Dog is positioned to the right of the character (or left if facing_left)
	var dog_x = (hw + 14) * sx
	var dog_ground = ground_y + bob

	# Dog body — simple rectangle ~15px wide
	var dog_w = 15.0
	var dog_h = 8.0
	var dog_body_x = dog_x - dog_w / 2.0

	# Shadow
	DU.draw_ellipse(self, Rect2(dog_body_x - 1, dog_ground - 1, dog_w + 2, 4), Color(0, 0, 0, 0.1))

	# Legs (4 small rectangles)
	var leg_color = dog_body_color.darkened(0.1)
	draw_rect(Rect2(dog_body_x + 1, dog_ground - 5, 2, 5), leg_color)
	draw_rect(Rect2(dog_body_x + 4, dog_ground - 5, 2, 5), leg_color)
	draw_rect(Rect2(dog_body_x + dog_w - 6, dog_ground - 5, 2, 5), leg_color)
	draw_rect(Rect2(dog_body_x + dog_w - 3, dog_ground - 5, 2, 5), leg_color)

	# Body
	draw_rect(Rect2(dog_body_x, dog_ground - 5 - dog_h, dog_w, dog_h), dog_body_color)

	# Head — small square extending forward
	var head_dir = sx
	var head_x = dog_body_x + (dog_w if head_dir > 0 else -6)
	var head_y = dog_ground - 5 - dog_h + 1
	draw_rect(Rect2(head_x, head_y, 6, 6), dog_body_color.lightened(0.05))

	# Ears
	draw_rect(Rect2(head_x + 1, head_y - 2, 2, 3), dog_body_color.darkened(0.1))
	draw_rect(Rect2(head_x + 3, head_y - 2, 2, 3), dog_body_color.darkened(0.1))

	# Eye
	var eye_x = head_x + (4 if head_dir > 0 else 2)
	draw_circle(Vector2(eye_x, head_y + 2.5), 1.0, Color(0.12, 0.1, 0.08))

	# Nose
	var nose_x = head_x + (5.5 if head_dir > 0 else 0.5)
	draw_circle(Vector2(nose_x, head_y + 4), 0.8, Color(0.15, 0.12, 0.1))

	# Service vest — different color rectangle on the dog's back
	var vest_x = dog_body_x + 2
	var vest_y = dog_ground - 5 - dog_h + 1
	var vest_w = dog_w - 4
	var vest_h = dog_h - 2
	draw_rect(Rect2(vest_x, vest_y, vest_w, vest_h), dog_vest_color)
	# Small cross or marking on vest
	draw_rect(Rect2(vest_x + vest_w / 2.0 - 1, vest_y + 1, 2, vest_h - 2), Color(1, 1, 1, 0.8))
	draw_rect(Rect2(vest_x + 1, vest_y + vest_h / 2.0 - 1, vest_w - 2, 2), Color(1, 1, 1, 0.8))

	# Tail — small angled line
	var tail_x = dog_body_x + (0 if head_dir > 0 else dog_w)
	var tail_base = Vector2(tail_x, dog_ground - 5 - dog_h + 2)
	var tail_tip = Vector2(tail_x - 4 * head_dir, dog_ground - 5 - dog_h - 3)
	draw_line(tail_base, tail_tip, dog_body_color.darkened(0.05), 2.0)
