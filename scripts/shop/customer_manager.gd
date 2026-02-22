extends Node

## CustomerManager - Spawns customers, manages the order queue,
## and triggers puzzles when a customer reaches the counter.

signal customer_waiting(customer_data: Dictionary)
signal order_filled(reward: int)
signal day_complete
signal day_progress(progress: float)

var customer_scene: PackedScene = preload("res://scenes/npcs/customer.tscn")
var current_customer: CharacterBody2D = null
var customers_served_today: int = 0
var base_customers_per_day: int = 3
var shop_node: Node2D = null
var _streak: int = 0

# Customer templates for early game
# puzzle_type: "sorting" = tap items in order, "recipe" = pick ingredients to craft, "memory" = remember items
var customer_pool: Array[Dictionary] = [
	{
		"name": "Mara",
		"color": Color(0.65, 0.8, 0.7),
		"items": ["coffee", "spices"],
		"reward": 10,
		"puzzle_type": "sorting",
		"patience": 22.0,
		"greeting": "Morning! I need a quick pick-me-up.",
		"thanks": "Perfect, just what I needed!",
		"impatient": "I'm running late...",
	},
	{
		"name": "Old Jin",
		"color": Color(0.75, 0.65, 0.55),
		"items": ["wine", "spices"],
		"reward": 14,
		"puzzle_type": "recipe",
		"recipe_id": "mulled_wine",
		"recipe_name": "Mulled Wine",
		"patience": 25.0,
		"greeting": "Ah, young one. Can you make something warm?",
		"thanks": "Mmm, reminds me of the old days.",
		"impatient": "These old bones can't wait forever...",
	},
	{
		"name": "Kess",
		"color": Color(0.8, 0.6, 0.7),
		"items": ["leather", "spices", "coffee"],
		"reward": 18,
		"puzzle_type": "sorting",
		"patience": 18.0,
		"greeting": "Hey! Got a big list today.",
		"thanks": "You're the best! See you tomorrow!",
		"impatient": "Come onnnn, I have places to be!",
	},
	{
		"name": "Davi",
		"color": Color(0.55, 0.65, 0.85),
		"items": ["spirits", "tools", "wine"],
		"reward": 22,
		"puzzle_type": "recipe",
		"recipe_id": "cocktail_kit",
		"recipe_name": "Cocktail Kit",
		"patience": 20.0,
		"greeting": "Hosting a party tonight. Help me out?",
		"thanks": "This is gonna be epic!",
		"impatient": "Guests are already arriving...",
	},
	{
		"name": "Renna",
		"color": Color(0.85, 0.75, 0.55),
		"items": ["coffee", "spices"],
		"reward": 10,
		"puzzle_type": "recipe",
		"recipe_id": "spiced_coffee",
		"recipe_name": "Spiced Coffee",
		"patience": 24.0,
		"greeting": "Hello there! Something cozy today.",
		"thanks": "Oh, this smells divine!",
		"impatient": "Taking a while, isn't it...",
	},
	{
		"name": "Fela",
		"color": Color(0.7, 0.6, 0.8),
		"items": ["spirits", "spices"],
		"reward": 16,
		"puzzle_type": "recipe",
		"recipe_id": "infused_spirits",
		"recipe_name": "Infused Spirits",
		"patience": 20.0,
		"greeting": "I heard you make the best infusions!",
		"thanks": "My friends will love this!",
		"impatient": "Maybe I'll try the other shop...",
	},
	{
		"name": "Tomas",
		"color": Color(0.6, 0.75, 0.65),
		"items": ["leather", "tools", "wine"],
		"reward": 25,
		"puzzle_type": "recipe",
		"recipe_id": "premium_bundle",
		"recipe_name": "Premium Bundle",
		"patience": 18.0,
		"greeting": "I need your finest selection.",
		"thanks": "Excellent quality as always.",
		"impatient": "I'm a busy man, you know.",
	},
	{
		"name": "Suki",
		"color": Color(0.75, 0.82, 0.6),
		"items": ["coffee", "wine"],
		"reward": 14,
		"puzzle_type": "memory",
		"patience": 22.0,
		"greeting": "Remember what I got last time?",
		"thanks": "You never forget! Love it!",
		"impatient": "Hmm, can't remember, huh?",
	},
	{
		"name": "Brick",
		"color": Color(0.65, 0.55, 0.5),
		"items": ["spirits", "leather", "tools"],
		"reward": 26,
		"puzzle_type": "memory",
		"patience": 15.0,
		"greeting": "Same as usual. You know the drill.",
		"thanks": "Solid. Real solid.",
		"impatient": "...",
	},
]

var _current_data: Dictionary = {}

func init(shop: Node2D) -> void:
	shop_node = shop

func start_day() -> void:
	customers_served_today = 0
	_streak = 0
	day_progress.emit(0.0)
	_spawn_next_customer()

func start_day_delayed(delay: float) -> void:
	customers_served_today = 0
	_streak = 0
	day_progress.emit(0.0)
	var timer = shop_node.get_tree().create_timer(delay)
	timer.timeout.connect(_spawn_next_customer)

func get_streak() -> int:
	return _streak

func _get_customers_for_today() -> int:
	# Scale: Day 1-3 = 3 customers, Day 4-6 = 4, Day 7+ = 5
	var day = GameManager.current_day
	var count: int
	if day <= 3:
		count = base_customers_per_day
	elif day <= 6:
		count = base_customers_per_day + 1
	else:
		count = base_customers_per_day + 2
	# Shop Sign upgrade: +1 customer
	var UpgradeShop = load("res://scripts/shop/upgrade_shop.gd")
	count += UpgradeShop.get_extra_customers()
	return count

func _spawn_next_customer() -> void:
	if customers_served_today >= _get_customers_for_today():
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
	# If reward is 0, customer left unhappy (patience ran out) — no coins, break streak
	if reward <= 0:
		_streak = 0
		order_filled.emit(0)
		return
	# Day bonus: +1 coin per day past Day 1
	var day_bonus = maxi(0, GameManager.current_day - 1)
	var total_reward = reward + day_bonus
	# Upgrade bonuses
	var UpgradeShop = load("res://scripts/shop/upgrade_shop.gd")
	total_reward += UpgradeShop.get_tip_bonus()
	if _current_data.get("puzzle_type", "") == "recipe":
		total_reward += UpgradeShop.get_recipe_bonus()
	total_reward = int(total_reward * UpgradeShop.get_reward_multiplier())
	# Patience bonus — fast service = bigger tip, slow = penalty
	if _customer.has_method("get_patience_bonus"):
		total_reward = int(total_reward * _customer.get_patience_bonus())
	# Stock level multiplier — full shelves = full reward, empty = half
	if shop_node and shop_node.shelf_stock:
		total_reward = int(total_reward * shop_node.shelf_stock.get_reward_multiplier())
	# Streak bonus
	_streak += 1
	if _streak >= 2:
		var streak_mult = 1.0 + (_streak - 1) * 0.1  # +10% per streak
		total_reward = int(total_reward * streak_mult)
	GameManager.add_coins(total_reward)
	order_filled.emit(total_reward)

func _on_customer_left(_customer: CharacterBody2D) -> void:
	current_customer = null
	customers_served_today += 1
	var total = _get_customers_for_today()
	day_progress.emit(float(customers_served_today) / float(total))
	# Small delay before next customer (bell upgrade speeds it up)
	var UpgradeShop = load("res://scripts/shop/upgrade_shop.gd")
	var delay = 2.0 if not UpgradeShop.has_upgrade("bell") else 1.0
	var timer = shop_node.get_tree().create_timer(delay)
	timer.timeout.connect(_spawn_next_customer)

func get_current_customer() -> CharacterBody2D:
	return current_customer

func get_puzzle_type() -> String:
	return _current_data.get("puzzle_type", "sorting")

func get_recipe_id() -> String:
	return _current_data.get("recipe_id", "")
