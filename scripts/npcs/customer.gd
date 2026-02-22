extends CharacterBody2D

## Customer - An NPC that walks into the shop, goes to the counter,
## makes a request, and waits for the player to fill the order.

signal arrived_at_counter(customer: CharacterBody2D)
signal order_completed(customer: CharacterBody2D, reward: int)
signal customer_left(customer: CharacterBody2D)

const DU = preload("res://scripts/visual/draw_utils.gd")

@onready var visual: ColorRect = $Visual
@onready var outline: ColorRect = $Outline
@onready var name_label: Label = $NameLabel
@onready var speech_label: Label = $SpeechBubble

const SPEED: float = 120.0
const MAX_PATIENCE: float = 20.0  # seconds before customer leaves

var customer_name: String = "Customer"
var customer_color: Color = Color(0.6, 0.7, 0.85)
var requested_items: Array[String] = []
var reward_coins: int = 10
var puzzle_type: String = "sorting"
var recipe_name: String = ""
var greeting_text: String = ""
var thanks_text: String = "Thanks!"
var impatient_text: String = "Too slow..."
var custom_patience: float = 0.0  # 0 = use default MAX_PATIENCE
var state: String = "entering"  # entering, waiting, leaving, done
var target_pos: Vector2 = Vector2.ZERO
var counter_pos: Vector2 = Vector2(360, 1000)
var exit_pos: Vector2 = Vector2(360, 1350)
var entry_pos: Vector2 = Vector2(360, 1350)
var patience: float = MAX_PATIENCE
var patience_ratio: float = 1.0  # 1.0 = full, 0.0 = gone
var _patience_pulse: float = 0.0
var _showed_impatient: bool = false

func setup(data: Dictionary) -> void:
	customer_name = data.get("name", "Customer")
	customer_color = data.get("color", Color(0.6, 0.7, 0.85))
	requested_items.assign(data.get("items", ["coffee"]))
	reward_coins = data.get("reward", 10)
	puzzle_type = data.get("puzzle_type", "sorting")
	recipe_name = data.get("recipe_name", "")
	greeting_text = data.get("greeting", "")
	thanks_text = data.get("thanks", "Thanks!")
	impatient_text = data.get("impatient", "Too slow...")
	custom_patience = data.get("patience", 0.0)

func _ready() -> void:
	# Hide old ColorRect placeholders
	visual.visible = false
	outline.visible = false
	# Add procedural character visual
	var cv = Node2D.new()
	cv.name = "CustomerArt"
	cv.set_script(load("res://scripts/visual/customer_visual.gd"))
	cv.scale = Vector2(1.5, 1.5)
	add_child(cv)
	cv.setup_appearance(customer_color, customer_name)
	name_label.text = customer_name
	speech_label.text = ""
	global_position = entry_pos
	target_pos = counter_pos
	state = "entering"

func _physics_process(delta: float) -> void:
	if state == "entering":
		_move_toward(counter_pos)
		if global_position.distance_to(counter_pos) < 10.0:
			state = "waiting"
			patience = custom_patience if custom_patience > 0 else MAX_PATIENCE
			_showed_impatient = false
			_show_request()
			arrived_at_counter.emit(self)
			AudioManager.play("customer_bell")
			print("[Customer] %s arrived at counter. State: waiting" % customer_name)
	elif state == "waiting":
		var max_p = custom_patience if custom_patience > 0 else MAX_PATIENCE
		patience -= delta
		patience_ratio = clampf(patience / max_p, 0.0, 1.0)
		_patience_pulse += delta
		queue_redraw()
		# Show impatient line when below 30%
		if patience_ratio < 0.3 and not _showed_impatient:
			_showed_impatient = true
			speech_label.text = impatient_text
			AudioManager.play("patience_tick")
		if patience <= 0.0:
			# Customer ran out of patience — leaves without buying
			speech_label.text = impatient_text
			state = "leaving"
			order_completed.emit(self, 0)
			print("[Customer] %s left — out of patience!" % customer_name)
	elif state == "leaving":
		_move_toward(exit_pos)
		if global_position.distance_to(exit_pos) < 10.0:
			state = "done"
			customer_left.emit(self)
			queue_free()

func _move_toward(target: Vector2) -> void:
	var direction = global_position.direction_to(target)
	velocity = direction * SPEED
	move_and_slide()

func _show_request() -> void:
	# Show greeting first, then request after a beat
	if greeting_text != "":
		speech_label.text = greeting_text
		queue_redraw()
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func():
			if state == "waiting":
				_show_order_text()
		)
	else:
		_show_order_text()

func _show_order_text() -> void:
	if puzzle_type == "recipe" and recipe_name != "":
		speech_label.text = "Can you make: %s?" % recipe_name
	elif puzzle_type == "memory":
		speech_label.text = "Remember my usual?"
	else:
		var item_names = []
		for item_id in requested_items:
			item_names.append(item_id.capitalize())
		speech_label.text = "I need: %s" % ", ".join(item_names)
	queue_redraw()

func complete_order() -> void:
	speech_label.text = thanks_text
	state = "leaving"
	order_completed.emit(self, reward_coins)
	queue_redraw()

func get_patience_bonus() -> float:
	## Returns a multiplier based on how quickly the player served them.
	## Fast service (>75% patience) = 1.25x tip bonus
	## Normal (50-75%) = 1.0x
	## Slow (25-50%) = 0.75x
	## Very slow (<25%) = 0.5x
	if patience_ratio > 0.75:
		return 1.25
	elif patience_ratio > 0.5:
		return 1.0
	elif patience_ratio > 0.25:
		return 0.75
	else:
		return 0.5

func fail_order() -> void:
	speech_label.text = "Hmm, not quite..."
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		state = "leaving"
	)

func _draw() -> void:
	# --- Name plate background (always visible) ---
	var np = Rect2(-55, -70, 110, 28)
	# Shadow
	draw_rect(Rect2(np.position.x + 2, np.position.y + 2, np.size.x, np.size.y), Color(0, 0, 0, 0.2))
	# Background
	DU.draw_rounded_panel(self, np, Color(0.12, 0.1, 0.15, 0.82), 5.0)
	# Color accent dot
	draw_circle(Vector2(-44, -56), 3.5, customer_color.lightened(0.15))

	# --- Speech bubble background (when text showing) ---
	if speech_label.text != "":
		var sb = Rect2(-125, 34, 250, 64)
		# Shadow
		draw_rect(Rect2(sb.position.x + 3, sb.position.y + 3, sb.size.x, sb.size.y), Color(0, 0, 0, 0.22))
		# Background
		DU.draw_rounded_panel(self, sb, Color(0.1, 0.08, 0.14, 0.92), 8.0)
		# Colored accent strip on left
		draw_rect(Rect2(sb.position.x + 3, sb.position.y + 8, 4, sb.size.y - 16), customer_color.lightened(0.15))
		# Top highlight
		draw_rect(Rect2(sb.position.x + 10, sb.position.y + 1, sb.size.x - 20, 1), Color(1, 1, 1, 0.08))
		# Tail pointing up to character
		var tail = PackedVector2Array([
			Vector2(-8, sb.position.y),
			Vector2(8, sb.position.y),
			Vector2(0, sb.position.y - 8),
		])
		draw_colored_polygon(tail, Color(0.1, 0.08, 0.14, 0.92))

	# --- Patience bar (only when waiting) ---
	if state != "waiting":
		return
	var bar_w := 64.0
	var bar_h := 8.0
	var bar_y := -80.0
	var bg_rect = Rect2(-bar_w / 2, bar_y, bar_w, bar_h)
	# Background
	draw_rect(Rect2(bg_rect.position.x + 1, bg_rect.position.y + 1, bg_rect.size.x, bg_rect.size.y), Color(0, 0, 0, 0.15))
	draw_rect(bg_rect, Color(0.15, 0.12, 0.1, 0.75))
	# Fill — color shifts green -> yellow -> orange -> red
	var fill_w = bar_w * patience_ratio
	var bar_color: Color
	if patience_ratio > 0.6:
		bar_color = Color(0.3, 0.85, 0.3)
	elif patience_ratio > 0.35:
		bar_color = Color(0.95, 0.75, 0.15)
	else:
		var pulse = (sin(_patience_pulse * 6.0) + 1.0) / 2.0
		bar_color = Color(0.95, 0.2 + 0.15 * pulse, 0.1)
	draw_rect(Rect2(-bar_w / 2, bar_y, fill_w, bar_h), bar_color)
	# Accessibility: diagonal stripe pattern when patience is low (colorblind support)
	if patience_ratio <= 0.35:
		var stripe_c = Color(0, 0, 0, 0.25)
		var stripe_step = 6
		for sx_i in int(fill_w / stripe_step) + 2:
			var sx_x = -bar_w / 2 + sx_i * stripe_step
			if sx_x < -bar_w / 2 + fill_w:
				draw_line(Vector2(sx_x, bar_y), Vector2(sx_x + bar_h, bar_y + bar_h), stripe_c, 1.0)
	elif patience_ratio <= 0.6:
		# Dots pattern for medium urgency
		var dot_step = 8
		for dx_i in int(fill_w / dot_step):
			var dx_x = -bar_w / 2 + dx_i * dot_step + 4
			draw_circle(Vector2(dx_x, bar_y + bar_h / 2), 1, Color(0, 0, 0, 0.15))
	# Border
	draw_rect(bg_rect, Color(0.3, 0.25, 0.2), false, 1.5)
	# Tick marks at 25%, 50%, 75%
	for tick in [0.25, 0.5, 0.75]:
		var tx = -bar_w / 2 + bar_w * tick
		draw_rect(Rect2(tx, bar_y, 1, bar_h), Color(0, 0, 0, 0.2))
