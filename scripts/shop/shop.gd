extends Node2D

## Shop - The player's shop. The core space of The Veil.
## Top-down 2D view. Player walks around, interacts with shelves,
## serves customers, solves puzzles, and encounters diegetic ad surfaces.

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var day_label: Label = $UI/DayLabel
@onready var coins_label: Label = $UI/CoinsLabel
@onready var inventory_panel: Control = $UI/InventoryPanel
@onready var sorting_puzzle: Control = $UI/SortingPuzzle
@onready var customer_manager: Node = $CustomerManager

# Shelf data: which items are on which shelf
var shelf_items: Dictionary = {
	"shelf_left": ["bread", "herbs", "tea"],
	"shelf_right": ["candle", "soap", "pottery"],
	"shelf_back_left": ["bread", "candle"],
	"shelf_back_right": ["herbs", "soap"],
}

# Track which shelf the player is near
var nearby_shelf: String = ""
const SHELF_INTERACT_DISTANCE: float = 120.0

# Shelf positions for distance check
var shelf_positions: Dictionary = {
	"shelf_left": Vector2(120, 300),
	"shelf_right": Vector2(600, 300),
	"shelf_back_left": Vector2(200, 140),
	"shelf_back_right": Vector2(520, 140),
}

# Counter tap zone
const COUNTER_POS: Vector2 = Vector2(360, 930)
const COUNTER_TAP_DISTANCE: float = 100.0

func _ready() -> void:
	_setup_collisions()
	_register_ad_surfaces()
	_update_hud()
	GameManager.game_state_changed.connect(_on_state_changed)
	GameManager.day_advanced.connect(_on_day_advanced)
	inventory_panel.item_selected.connect(_on_item_selected)
	sorting_puzzle.puzzle_completed.connect(_on_puzzle_completed)
	sorting_puzzle.puzzle_closed.connect(_on_puzzle_closed)
	customer_manager.init(self)
	customer_manager.order_filled.connect(_on_order_filled)
	customer_manager.day_complete.connect(_on_day_complete)
	Analytics.track_event("scene_entered", {"scene": "shop"})
	print("[Shop] Welcome to your shop. Day %d." % GameManager.current_day)

	# Start the day — customers begin arriving
	customer_manager.start_day()

func _process(_delta: float) -> void:
	_update_nearby_shelf()

func _update_nearby_shelf() -> void:
	nearby_shelf = ""
	var closest_dist = SHELF_INTERACT_DISTANCE
	for shelf_id in shelf_positions:
		var dist = player.global_position.distance_to(shelf_positions[shelf_id])
		if dist < closest_dist:
			closest_dist = dist
			nearby_shelf = shelf_id

func _input(event: InputEvent) -> void:
	if inventory_panel.is_open or sorting_puzzle.visible:
		return
	var tap_pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = get_canvas_transform().affine_inverse() * Vector2(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		tap_pos = get_canvas_transform().affine_inverse() * Vector2(event.position)
	else:
		return

	# Check counter tap first (to serve customer)
	if _check_counter_tap(tap_pos):
		return
	# Then check shelf tap
	_check_shelf_tap(tap_pos)

func _check_counter_tap(tap_pos: Vector2) -> bool:
	var dist_to_counter = tap_pos.distance_to(COUNTER_POS)
	var player_to_counter = player.global_position.distance_to(COUNTER_POS)
	if dist_to_counter < COUNTER_TAP_DISTANCE and player_to_counter < 150.0:
		var customer = customer_manager.get_current_customer()
		if customer != null and customer.state == "waiting":
			# Start the sorting puzzle with the customer's order
			var items: Array[String] = []
			items.assign(customer.requested_items)
			sorting_puzzle.start_puzzle("order_%d" % GameManager.current_day, items)
			return true
	return false

func _check_shelf_tap(tap_pos: Vector2) -> void:
	if nearby_shelf == "":
		return
	var shelf_pos = shelf_positions[nearby_shelf]
	var dist_to_shelf = tap_pos.distance_to(shelf_pos)
	if dist_to_shelf < SHELF_INTERACT_DISTANCE:
		inventory_panel.open_panel(nearby_shelf, shelf_items[nearby_shelf])

func _on_item_selected(item_id: String) -> void:
	print("[Shop] Browsing item: %s" % item_id)

func _on_puzzle_completed(_puzzle_id: String, _time_taken: float, _moves: int) -> void:
	var customer = customer_manager.get_current_customer()
	if customer:
		customer.complete_order()
		GameManager.complete_puzzle(_puzzle_id)
	sorting_puzzle.visible = false

func _on_puzzle_closed() -> void:
	pass

func _on_order_filled(reward: int) -> void:
	print("[Shop] Order filled! Earned %d coins." % reward)

func _on_day_complete() -> void:
	print("[Shop] All customers served! Day %d complete." % GameManager.current_day)
	GameManager.advance_day()
	# Restart with new customers after a pause
	var timer = get_tree().create_timer(3.0)
	timer.timeout.connect(func(): customer_manager.start_day())

func _setup_collisions() -> void:
	var player_shape = RectangleShape2D.new()
	player_shape.size = Vector2(32, 32)
	$Player/CollisionShape2D.shape = player_shape

	var shelf_side_shape = RectangleShape2D.new()
	shelf_side_shape.size = Vector2(160, 200)
	$ShelfLeft/CollisionShape2D.shape = shelf_side_shape
	$ShelfRight/CollisionShape2D.shape = shelf_side_shape

	var shelf_back_shape = RectangleShape2D.new()
	shelf_back_shape.size = Vector2(140, 40)
	$ShelfBackLeft/CollisionShape2D.shape = shelf_back_shape
	$ShelfBackRight/CollisionShape2D.shape = shelf_back_shape

	_add_wall_collision(Vector2(360, 60), Vector2(720, 120))
	_add_wall_collision(Vector2(20, 640), Vector2(40, 1280))
	_add_wall_collision(Vector2(700, 640), Vector2(40, 1280))
	_add_wall_collision(Vector2(360, 940), Vector2(320, 60))

func _add_wall_collision(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _register_ad_surfaces() -> void:
	AdManager.register_surface("shop_billboard_01", AdManager.SurfaceType.BILLBOARD, $AdBillboard)
	AdManager.register_surface("shop_poster_left", AdManager.SurfaceType.POSTER, $AdPosterLeft)
	AdManager.register_surface("shop_poster_right", AdManager.SurfaceType.POSTER, $AdPosterRight)

func _on_state_changed(key: String, _value: Variant) -> void:
	if key == "player_coins":
		_update_hud()

func _on_day_advanced(_day: int) -> void:
	_update_hud()

func _update_hud() -> void:
	day_label.text = "Day %d" % GameManager.current_day
	coins_label.text = "%d coins" % GameManager.player_coins
