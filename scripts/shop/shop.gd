extends Node2D

## Shop - The player's shop. The core space of The Veil.
## ALL tap input is handled here. Taps either open interactions or move the player.

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var day_label: Label = $UI/DayLabel
@onready var coins_label: Label = $UI/CoinsLabel
@onready var inventory_panel: Control = $UI/InventoryPanel
@onready var sorting_puzzle: Control = $UI/SortingPuzzle
@onready var customer_manager: Node = $CustomerManager

# Shelf data
var shelf_items: Dictionary = {
	"shelf_left": ["bread", "herbs", "tea"],
	"shelf_right": ["candle", "soap", "pottery"],
	"shelf_back_left": ["bread", "candle"],
	"shelf_back_right": ["herbs", "soap"],
}

# Shelf positions and sizes for tap detection
var shelf_zones: Dictionary = {
	"shelf_left": Rect2(40, 200, 160, 200),
	"shelf_right": Rect2(520, 200, 160, 200),
	"shelf_back_left": Rect2(130, 120, 140, 40),
	"shelf_back_right": Rect2(450, 120, 140, 40),
}

# Counter zone for tap detection -- big generous area around the counter
var counter_zone: Rect2 = Rect2(140, 850, 440, 180)

# How close player needs to be to interact
const INTERACT_DISTANCE: float = 300.0

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
	customer_manager.start_day()

func _input(event: InputEvent) -> void:
	# Don't process taps if a panel is open
	if inventory_panel.is_open or sorting_puzzle.visible:
		return

	var tap_pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = get_canvas_transform().affine_inverse() * Vector2(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		tap_pos = get_canvas_transform().affine_inverse() * Vector2(event.position)
	else:
		return

	# Priority 1: Did they tap the counter? (and is player close enough?)
	if counter_zone.has_point(tap_pos):
		var dist = player.global_position.distance_to(counter_zone.get_center())
		if dist < INTERACT_DISTANCE:
			if _try_serve_customer():
				return
		# Not close enough — walk toward counter instead
		player.move_to(Vector2(360, 980))
		return

	# Priority 2: Did they tap a shelf? (and is player close enough?)
	for shelf_id in shelf_zones:
		var zone: Rect2 = shelf_zones[shelf_id]
		if zone.has_point(tap_pos):
			var dist = player.global_position.distance_to(zone.get_center())
			if dist < INTERACT_DISTANCE:
				inventory_panel.open_panel(shelf_id, shelf_items[shelf_id])
				return
			# Not close enough — walk toward shelf
			player.move_to(zone.get_center() + Vector2(0, 120))
			return

	# Priority 3: Nothing special tapped — just walk there
	player.move_to(tap_pos)

func _try_serve_customer() -> bool:
	var customer = customer_manager.get_current_customer()
	if customer != null and customer.state == "waiting":
		var items: Array[String] = []
		items.assign(customer.requested_items)
		sorting_puzzle.start_puzzle("order_%d" % GameManager.current_day, items)
		return true
	return false

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
	SaveManager.save_game()
	_show_day_summary()

func _show_day_summary() -> void:
	# Show a brief day-end summary before next day starts
	var summary = $UI/DaySummary
	summary.visible = true
	summary.get_node("DayText").text = "Day %d Complete" % (GameManager.current_day - 1)
	summary.get_node("CoinsText").text = "%d coins" % GameManager.player_coins
	summary.get_node("NextBtn").pressed.connect(func():
		summary.visible = false
		customer_manager.start_day()
	, CONNECT_ONE_SHOT)

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
