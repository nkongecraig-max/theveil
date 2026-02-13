extends CharacterBody2D

## Player - Touch-controlled character for the shop.
## Movement is controlled by the shop script calling move_to().

const SPEED: float = 200.0

var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false

func _ready() -> void:
	target_position = global_position

func move_to(pos: Vector2) -> void:
	target_position = pos
	is_moving = true

func stop_moving() -> void:
	is_moving = false
	velocity = Vector2.ZERO

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
