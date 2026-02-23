extends Node

## CustomerManager - Spawns customers, manages the order queue,
## and triggers puzzles when a customer reaches the counter.

signal customer_waiting(customer_data: Dictionary)
signal order_filled(reward: int)
signal day_complete
signal day_progress(progress: float)
signal vip_arrived(customer_data: Dictionary)
signal vip_succeeded(bonus: int)
signal vip_failed

var customer_scene: PackedScene = preload("res://scenes/npcs/customer.tscn")
var current_customer: CharacterBody2D = null
var customers_served_today: int = 0
var base_customers_per_day: int = 3
var shop_node: Node2D = null
var _streak: int = 0

# VIP system
var is_vip_active := false
var vip_coin_boost_remaining: int = 0  # How many boosted customers remain
const VIP_BOOST_MULTIPLIER: float = 3.0
const VIP_BOOST_CUSTOMERS: int = 3
var _vip_attempted_today := false  # Only one VIP chance per day
var customers_failed_today: int = 0

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
	{
		"name": "Amina",
		"color": Color(0.85, 0.55, 0.45),
		"items": ["spices", "coffee", "leather"],
		"reward": 20,
		"puzzle_type": "recipe",
		"recipe_id": "spice_blend",
		"recipe_name": "Spice Blend",
		"patience": 21.0,
		"greeting": "Salaam! I need something fragrant for tonight's feast.",
		"thanks": "Ah, beautiful! My grandmother would approve.",
		"impatient": "The guests will arrive before the food is ready...",
	},
	{
		"name": "Yuki",
		"color": Color(0.88, 0.85, 0.92),
		"items": ["coffee", "spices"],
		"reward": 12,
		"puzzle_type": "memory",
		"patience": 23.0,
		"greeting": "Good day. The same blend as always, please.",
		"thanks": "Exactly right. You have a good memory.",
		"impatient": "I suppose patience is a virtue I lack today.",
	},
	{
		"name": "Kofi",
		"color": Color(0.6, 0.78, 0.55),
		"items": ["coffee", "tools"],
		"reward": 14,
		"puzzle_type": "sorting",
		"patience": 19.0,
		"greeting": "Eii! Let me grab a few things before work.",
		"thanks": "Sharp! You dey move fast, I like that.",
		"impatient": "Chale, the foreman no go wait for me oh...",
	},
	{
		"name": "Sofia",
		"color": Color(0.9, 0.7, 0.6),
		"items": ["wine", "spices", "coffee"],
		"reward": 24,
		"puzzle_type": "recipe",
		"recipe_id": "herbal_tea",
		"recipe_name": "Herbal Tea",
		"patience": 22.0,
		"greeting": "Hola! I'm looking for something calming after a long day.",
		"thanks": "Maravilloso! This is exactly what I needed.",
		"impatient": "Ay, my nerves can't take much more waiting...",
	},
	{
		"name": "Rashid",
		"color": Color(0.55, 0.6, 0.75),
		"items": ["leather", "tools", "spices"],
		"reward": 22,
		"puzzle_type": "recipe",
		"recipe_id": "leather_care_kit",
		"recipe_name": "Leather Care Kit",
		"patience": 17.0,
		"greeting": "I need a proper kit to restore my father's satchel.",
		"thanks": "This will do nicely. Fine craftsmanship deserves fine care.",
		"impatient": "The leather won't condition itself, friend.",
	},
	{
		"name": "Mei-Ling",
		"color": Color(0.78, 0.65, 0.82),
		"items": ["spirits", "wine"],
		"reward": 16,
		"puzzle_type": "memory",
		"patience": 20.0,
		"greeting": "Hi! My uncle sent me — he said you'd know his order.",
		"thanks": "He was right, you do remember everything!",
		"impatient": "Uncle's going to be so disappointed...",
	},
	{
		"name": "Dmitri",
		"color": Color(0.58, 0.7, 0.72),
		"items": ["spirits", "tools", "leather"],
		"reward": 26,
		"puzzle_type": "sorting",
		"patience": 16.0,
		"greeting": "Good. I have a list. Let's be efficient.",
		"thanks": "Precisely what I asked for. Respect.",
		"impatient": "In my country we do not wait this long.",
	},
	{
		"name": "Nneka",
		"color": Color(0.82, 0.62, 0.5),
		"items": ["spices", "coffee", "wine"],
		"reward": 20,
		"puzzle_type": "recipe",
		"recipe_id": "gift_basket",
		"recipe_name": "Gift Basket",
		"patience": 23.0,
		"greeting": "I'm putting together something special for my sister's wedding!",
		"thanks": "She is going to cry happy tears! Thank you!",
		"impatient": "The ceremony is tomorrow, please hurry...",
	},
	{
		"name": "Priya",
		"color": Color(0.92, 0.78, 0.55),
		"items": ["spices", "coffee"],
		"reward": 12,
		"puzzle_type": "recipe",
		"recipe_id": "spiced_coffee",
		"recipe_name": "Spiced Coffee",
		"patience": 24.0,
		"greeting": "Namaste! Something with cardamom and warmth, please.",
		"thanks": "Mmm, this takes me right back home. Dhanyavaad!",
		"impatient": "I was promised quick service here...",
	},
	{
		"name": "Luca",
		"color": Color(0.68, 0.72, 0.58),
		"items": ["wine", "leather"],
		"reward": 18,
		"puzzle_type": "memory",
		"patience": 19.0,
		"greeting": "Ciao! You should know what I want by now, no?",
		"thanks": "Perfetto! You never disappoint, my friend.",
		"impatient": "Mamma mia, even the gondolas are faster than this...",
	},
	{
		"name": "Fatou",
		"color": Color(0.7, 0.55, 0.65),
		"items": ["spices", "spirits", "tools"],
		"reward": 24,
		"puzzle_type": "sorting",
		"patience": 15.0,
		"greeting": "I need everything on this list and I need it now!",
		"thanks": "Fast hands! You earned every coin of that.",
		"impatient": "The market closes in ten minutes!",
	},
]

var _current_data: Dictionary = {}

func init(shop: Node2D) -> void:
	shop_node = shop

func start_day() -> void:
	customers_served_today = 0
	customers_failed_today = 0
	_streak = 0
	is_vip_active = false
	_vip_attempted_today = false
	day_progress.emit(0.0)
	_spawn_next_customer()

func start_day_delayed(delay: float) -> void:
	customers_served_today = 0
	customers_failed_today = 0
	_streak = 0
	is_vip_active = false
	_vip_attempted_today = false
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
	var data = customer_pool[randi() % customer_pool.size()].duplicate()

	# VIP chance: ~20% from Day 3+ if no VIP yet today, and served at least 1
	is_vip_active = false
	if not _vip_attempted_today and GameManager.current_day >= 3 and customers_served_today >= 1:
		if randi() % 100 < 20:
			is_vip_active = true
			_vip_attempted_today = true
			data["is_vip"] = true
			data["reward"] = int(data["reward"] * 2.0)  # Double base reward
			data["patience"] = data["patience"] * 0.75   # Less patience — pressure!
			data["greeting"] = "VIP: " + data["greeting"]

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
	if is_vip_active:
		vip_arrived.emit(data)

func _on_customer_arrived(_customer: CharacterBody2D) -> void:
	# Customer is at the counter -- puzzle time
	pass

func _on_order_completed(_customer: CharacterBody2D, reward: int) -> void:
	# If reward is 0, customer left unhappy (patience ran out) — no coins, break streak
	if reward <= 0:
		_streak = 0
		customers_failed_today += 1
		# VIP failure — lose the opportunity
		if is_vip_active:
			is_vip_active = false
			vip_failed.emit()
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
	# VIP coin boost from previous VIP success
	if vip_coin_boost_remaining > 0:
		total_reward = int(total_reward * VIP_BOOST_MULTIPLIER)
		vip_coin_boost_remaining -= 1
	# Streak bonus
	_streak += 1
	if _streak >= 2:
		var streak_mult = 1.0 + (_streak - 1) * 0.1  # +10% per streak
		total_reward = int(total_reward * streak_mult)
	# VIP success — activate coin boost for next customers
	if is_vip_active:
		is_vip_active = false
		vip_coin_boost_remaining = VIP_BOOST_CUSTOMERS
		vip_succeeded.emit(total_reward)
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
