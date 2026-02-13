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
var customer_pool: Array[Dictionary] = [
	{
		"name": "Mara",
		"color": Color(0.65, 0.8, 0.7),
		"items": ["bread", "herbs"],
		"reward": 8,
	},
	{
		"name": "Old Jin",
		"color": Color(0.75, 0.65, 0.55),
		"items": ["tea", "candle"],
		"reward": 10,
	},
	{
		"name": "Kess",
		"color": Color(0.8, 0.6, 0.7),
		"items": ["soap", "herbs", "bread"],
		"reward": 15,
	},
	{
		"name": "Davi",
		"color": Color(0.55, 0.65, 0.85),
		"items": ["pottery", "candle", "tea"],
		"reward": 18,
	},
	{
		"name": "Renna",
		"color": Color(0.85, 0.75, 0.55),
		"items": ["bread", "soap"],
		"reward": 7,
	},
]

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
	var customer = customer_scene.instantiate()
	customer.setup(data)
	shop_node.add_child(customer)
	current_customer = customer

	# Set up collision shape for the customer
	var shape = RectangleShape2D.new()
	shape.size = Vector2(32, 32)
	customer.get_node("CollisionShape2D").shape = shape

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
