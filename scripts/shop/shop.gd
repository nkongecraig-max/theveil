extends Node2D

## Shop - The player's shop. The core space of The Veil.
## Top-down 2D view. Player walks around, interacts with shelves,
## serves customers, and encounters diegetic ad surfaces.

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var day_label: Label = $UI/DayLabel
@onready var coins_label: Label = $UI/CoinsLabel

func _ready() -> void:
	_setup_collisions()
	_register_ad_surfaces()
	_update_hud()
	GameManager.game_state_changed.connect(_on_state_changed)
	GameManager.day_advanced.connect(_on_day_advanced)
	Analytics.track_event("scene_entered", {"scene": "shop"})
	print("[Shop] Welcome to your shop. Day %d." % GameManager.current_day)

func _setup_collisions() -> void:
	# Player collision
	var player_shape = RectangleShape2D.new()
	player_shape.size = Vector2(32, 32)
	$Player/CollisionShape2D.shape = player_shape

	# Shelf collisions
	var shelf_side_shape = RectangleShape2D.new()
	shelf_side_shape.size = Vector2(160, 200)
	$ShelfLeft/CollisionShape2D.shape = shelf_side_shape
	$ShelfRight/CollisionShape2D.shape = shelf_side_shape

	var shelf_back_shape = RectangleShape2D.new()
	shelf_back_shape.size = Vector2(140, 40)
	$ShelfBackLeft/CollisionShape2D.shape = shelf_back_shape
	$ShelfBackRight/CollisionShape2D.shape = shelf_back_shape

	# Wall collisions (StaticBody2D created at runtime)
	_add_wall_collision(Vector2(360, 60), Vector2(720, 120))   # Back wall
	_add_wall_collision(Vector2(20, 640), Vector2(40, 1280))   # Left wall
	_add_wall_collision(Vector2(700, 640), Vector2(40, 1280))  # Right wall
	_add_wall_collision(Vector2(360, 940), Vector2(320, 60))   # Counter

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
	# Register all ad surfaces with the AdManager
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
