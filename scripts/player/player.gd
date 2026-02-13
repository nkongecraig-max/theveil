extends CharacterBody2D

## Player - Touch-controlled character for the shop.
## Tap anywhere to walk there. Simple, one-hand mobile play.

const SPEED: float = 200.0

var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

func _ready() -> void:
	target_position = global_position

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		target_position = get_canvas_transform().affine_inverse() * Vector2(event.position)
		is_moving = true
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		target_position = get_canvas_transform().affine_inverse() * Vector2(event.position)
		is_moving = true

func _physics_process(_delta: float) -> void:
	if not is_moving:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction = global_position.direction_to(target_position)
	var distance = global_position.distance_to(target_position)

	if distance < 5.0:
		is_moving = false
		velocity = Vector2.ZERO
	else:
		velocity = direction * SPEED

	move_and_slide()
