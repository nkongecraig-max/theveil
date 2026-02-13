extends Control

## Main Menu - The first thing the player sees.
## Intentionally minimal. The veil hasn't lifted yet.

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var new_game_btn: Button = %NewGameBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var settings_btn: Button = %SettingsBtn

func _ready() -> void:
	# Check if save exists to show/hide continue button
	continue_btn.visible = SaveManager.has_save()

	# Connect buttons
	new_game_btn.pressed.connect(_on_new_game)
	continue_btn.pressed.connect(_on_continue)
	settings_btn.pressed.connect(_on_settings)

	# Subtle entrance animation
	modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 1.5).set_ease(Tween.EASE_OUT)

func _on_new_game() -> void:
	if SaveManager.has_save():
		# TODO: Add "are you sure?" dialog
		pass
	SaveManager.delete_save()
	GameManager.go_to_scene("res://scenes/shop/shop.tscn")

func _on_continue() -> void:
	SaveManager.load_game()
	GameManager.go_to_scene("res://scenes/shop/shop.tscn")

func _on_settings() -> void:
	# TODO: Settings menu (sound, music, notifications)
	pass
