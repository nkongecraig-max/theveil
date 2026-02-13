extends CharacterBody2D

## Customer - An NPC that walks into the shop, goes to the counter,
## makes a request, and waits for the player to fill the order.

signal arrived_at_counter(customer: CharacterBody2D)
signal order_completed(customer: CharacterBody2D, reward: int)
signal customer_left(customer: CharacterBody2D)

@onready var visual: ColorRect = $Visual
@onready var outline: ColorRect = $Outline
@onready var name_label: Label = $NameLabel
@onready var speech_label: Label = $SpeechBubble

const SPEED: float = 120.0

var customer_name: String = "Customer"
var customer_color: Color = Color(0.6, 0.7, 0.85)
var requested_items: Array[String] = []
var reward_coins: int = 10
var puzzle_type: String = "sorting"
var recipe_name: String = ""
var state: String = "entering"  # entering, waiting, leaving, done
var target_pos: Vector2 = Vector2.ZERO
var counter_pos: Vector2 = Vector2(360, 1000)
var exit_pos: Vector2 = Vector2(360, 1350)
var entry_pos: Vector2 = Vector2(360, 1350)

func setup(data: Dictionary) -> void:
	customer_name = data.get("name", "Customer")
	customer_color = data.get("color", Color(0.6, 0.7, 0.85))
	requested_items.assign(data.get("items", ["bread"]))
	reward_coins = data.get("reward", 10)
	puzzle_type = data.get("puzzle_type", "sorting")
	recipe_name = data.get("recipe_name", "")

func _ready() -> void:
	visual.color = customer_color
	name_label.text = customer_name
	speech_label.text = ""
	global_position = entry_pos
	target_pos = counter_pos
	state = "entering"

func _physics_process(_delta: float) -> void:
	if state == "entering":
		_move_toward(counter_pos)
		if global_position.distance_to(counter_pos) < 10.0:
			state = "waiting"
			_show_request()
			arrived_at_counter.emit(self)
			print("[Customer] %s arrived at counter. State: waiting" % customer_name)
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
	if puzzle_type == "recipe" and recipe_name != "":
		speech_label.text = "Can you make: %s?" % recipe_name
	else:
		var item_names = []
		for item_id in requested_items:
			item_names.append(item_id.capitalize())
		speech_label.text = "I need: %s" % ", ".join(item_names)

func complete_order() -> void:
	speech_label.text = "Thanks!"
	state = "leaving"
	order_completed.emit(self, reward_coins)

func fail_order() -> void:
	speech_label.text = "Hmm, not quite..."
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		state = "leaving"
	)
