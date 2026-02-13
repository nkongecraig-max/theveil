extends Area2D

## ShelfInteraction - Detects when player is near a shelf.
## When player taps the shelf while in range, emits signal to open inventory panel.

signal shelf_opened(shelf_id: String, items: Array)

@export var shelf_id: String = "shelf_left"
@export var shelf_items: Array[String] = ["bread", "candle", "herbs"]

var player_in_range: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = false

func open_shelf() -> void:
	if player_in_range:
		shelf_opened.emit(shelf_id, shelf_items)
		Analytics.track_event("shelf_opened", {"shelf_id": shelf_id})
