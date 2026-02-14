extends Control

## Main Menu - The first thing the player sees.
## Intentionally minimal. The veil hasn't lifted yet.

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var new_game_btn: Button = %NewGameBtn
@onready var continue_btn: Button = %ContinueBtn
@onready var settings_btn: Button = %SettingsBtn

func _ready() -> void:
	# Add atmospheric background
	var bg_node = Control.new()
	bg_node.name = "MenuBG"
	bg_node.set_script(load("res://scripts/visual/menu_background.gd"))
	add_child(bg_node)
	move_child(bg_node, 0)
	$Background.visible = false
	# Style the title
	title_label.add_theme_color_override("font_color", Color(0.85, 0.8, 0.95))
	subtitle_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.7))

	continue_btn.visible = SaveManager.has_save()
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
