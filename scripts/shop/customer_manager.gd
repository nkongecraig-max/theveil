extends Node

## CustomerManager - Spawns customers, manages the order queue,
## and triggers puzzles when a customer reaches the counter.

signal customer_waiting(customer_data: Dictionary)
signal order_filled(reward: int)
signal day_complete

var customer_scene: PackedScene = preload("res://scenes/npcs/customer.tscn")
var current_customer: CharacterBody2D = null
var customers_served_today: int = 0
var customers_per_day: int = 3
var shop_node: Node2D = null

# Customer templates for early game
# puzzle_type: "sorting" = tap items in order, "recipe" = pick ingredients to craft
var customer_pool: Array[Dictionary] = [
	{
		"name": "Mara",
		"color": Color(0.65, 0.8, 0.7),
		"items": ["bread", "herbs"],
		"reward": 8,
		"puzzle_type": "sorting",
	},
	{
		"name": "Old Jin",
		"color": Color(0.75, 0.65, 0.55),
		"items": ["tea", "candle"],
		"reward": 10,
		"puzzle_type": "recipe",
		"recipe_id": "herb_tea",
		"recipe_name": "Herb Tea",
	},
	{
		"name": "Kess",
		"color": Color(0.8, 0.6, 0.7),
		"items": ["soap", "herbs", "bread"],
		"reward": 15,
		"puzzle_type": "sorting",
	},
	{
		"name": "Davi",
		"color": Color(0.55, 0.65, 0.85),
		"items": ["pottery", "candle", "tea"],
		"reward": 18,
		"puzzle_type": "recipe",
		"recipe_id": "tea_set",
		"recipe_name": "Tea Set",
	},
	{
		"name": "Renna",
		"color": Color(0.85, 0.75, 0.55),
		"items": ["bread", "soap"],
		"reward": 7,
		"puzzle_type": "recipe",
		"recipe_id": "herbal_soap",
		"recipe_name": "Herbal Soap",
	},
	{
		"name": "Fela",
		"color": Color(0.7, 0.6, 0.8),
		"items": ["candle", "herbs"],
		"reward": 12,
		"puzzle_type": "recipe",
		"recipe_id": "scented_candle",
		"recipe_name": "Scented Candle",
	},
	{
		"name": "Tomas",
		"color": Color(0.6, 0.75, 0.65),
		"items": ["soap", "candle", "tea"],
		"reward": 20,
		"puzzle_type": "recipe",
		"recipe_id": "gift_bundle",
		"recipe_name": "Gift Bundle",
	},
]

var _current_data: Dictionary = {}

func init(shop: Node2D) -> void:
	shop_node = shop

func start_day() -> void:
	customers_served_today = 0
	_spawn_next_customer()

func _spawn_next_customer() -> void:
	if customers_served_today >= customers_per_day:
		day_complete.emit()
		return
	if current_customer != null:
		return

	# Pick a random customer
	var data = customer_pool[randi() % customer_pool.size()]
	_current_data = data
	var customer = customer_scene.instantiate()
	customer.setup(data)
	shop_node.add_child(customer)
	current_customer = customer

	# Set up collision shape for the customer
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	customer.get_node("CollisionShape2D").shape = shape
	# Customers don't collide with walls -- they walk freely to the counter
	customer.collision_layer = 0
	customer.collision_mask = 0

	customer.arrived_at_counter.connect(_on_customer_arrived)
	customer.order_completed.connect(_on_order_completed)
	customer.customer_left.connect(_on_customer_left)

	customer_waiting.emit(data)

func _on_customer_arrived(_customer: CharacterBody2D) -> void:
	# Customer is at the counter -- puzzle time
	pass

func _on_order_completed(_customer: CharacterBody2D, reward: int) -> void:
	GameManager.add_coins(reward)
	order_filled.emit(reward)

func _on_customer_left(_customer: CharacterBody2D) -> void:
	current_customer = null
	customers_served_today += 1
	# Small delay before next customer
	var timer = shop_node.get_tree().create_timer(2.0)
	timer.timeout.connect(_spawn_next_customer)

func get_current_customer() -> CharacterBody2D:
	return current_customer

func get_puzzle_type() -> String:
	return _current_data.get("puzzle_type", "sorting")

func get_recipe_id() -> String:
	return _current_data.get("recipe_id", "")
