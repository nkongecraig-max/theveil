extends Node

## ScreenShake - Shakes the camera for impact moments.
## Attach to a Camera2D node. Call shake() for juicy feedback.

var _camera: Camera2D = null
var _shake_amount: float = 0.0
var _shake_decay: float = 8.0

func setup(camera: Camera2D) -> void:
	_camera = camera

func shake(amount: float = 8.0, decay: float = 8.0) -> void:
	_shake_amount = amount
	_shake_decay = decay

func _process(delta: float) -> void:
	if _camera == null or _shake_amount <= 0.1:
		if _camera:
			_camera.offset = Vector2.ZERO
		return
	_shake_amount = lerpf(_shake_amount, 0.0, _shake_decay * delta)
	_camera.offset = Vector2(
		randf_range(-_shake_amount, _shake_amount),
		randf_range(-_shake_amount, _shake_amount)
	)
