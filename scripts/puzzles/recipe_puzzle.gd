extends Control

## RecipePuzzle - The second puzzle type in The Veil.
## Customer requests a product. Player picks the correct ingredients
## to craft it. Secretly teaches pattern matching and logical deduction.

signal puzzle_completed(puzzle_id: String, time_taken: float, moves: int)
signal puzzle_failed(puzzle_id: String)
signal puzzle_closed

@onready var title_label: Label = $PanelBG/TitleLabel
@onready var recipe_label: Label = $PanelBG/RecipeLabel
@onready var result_container: HBoxContainer = $PanelBG/ResultContainer
@onready var ingredients_container: HBoxContainer = $PanelBG/IngredientsContainer
@onready var craft_btn: Button = $PanelBG/CraftBtn
@onready var result_label: Label = $PanelBG/ResultLabel
@onready var close_btn: Button = $PanelBG/CloseBtn

var puzzle_id: String = ""
var target_recipe: String = ""
var required_ingredients: Array[String] = []
var selected_ingredients: Array[String] = []
var all_ingredients: Array[String] = []
var move_count: int = 0
var start_time: float = 0.0
var is_solved: bool = false

# Recipes: product -> required ingredients
var recipes: Dictionary = {
	"herbal_soap": {
		"name": "Herbal Soap",
		"ingredients": ["soap", "herbs"],
		"color": Color(0.55, 0.72, 0.55),
	},
	"scented_candle": {
		"name": "Scented Candle",
		"ingredients": ["candle", "herbs"],
		"color": Color(0.9, 0.85, 0.5),
	},
	"bread_basket": {
		"name": "Bread Basket",
		"ingredients": ["bread", "bread"],
		"color": Color(0.85, 0.72, 0.45),
	},
	"tea_set": {
		"name": "Tea Set",
		"ingredients": ["tea", "pottery"],
		"color": Color(0.6, 0.75, 0.55),
	},
	"gift_bundle": {
		"name": "Gift Bundle",
		"ingredients": ["soap", "candle", "tea"],
		"color": Color(0.78, 0.65, 0.82),
	},
	"herb_tea": {
		"name": "Herb Tea",
		"ingredients": ["tea", "herbs"],
		"color": Color(0.5, 0.72, 0.45),
	},
}

var ingredient_colors: Dictionary = {
	"bread": Color(0.85, 0.72, 0.45),
	"candle": Color(0.95, 0.88, 0.55),
	"herbs": Color(0.45, 0.7, 0.4),
	"soap": Color(0.72, 0.62, 0.82),
	"tea": Color(0.6, 0.75, 0.5),
	"pottery": Color(0.75, 0.55, 0.4),
}

var ingredient_names: Dictionary = {
	"bread": "Bread",
	"candle": "Candle",
	"herbs": "Herbs",
	"soap": "Soap",
	"tea": "Tea",
	"pottery": "Bowl",
}

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)
	craft_btn.pressed.connect(_on_craft)
	result_label.text = ""
	craft_btn.visible = false

func start_puzzle(id: String, recipe_id: String) -> void:
	puzzle_id = id
	is_solved = false
	move_count = 0
	start_time = Time.get_unix_time_from_system()
	result_label.text = ""
	selected_ingredients = []

	if not recipes.has(recipe_id):
		recipe_id = recipes.keys()[randi() % recipes.size()]

	target_recipe = recipe_id
	var recipe = recipes[recipe_id]
	required_ingredients = []
	required_ingredients.assign(recipe["ingredients"])

	title_label.text = "Craft: %s" % recipe["name"]
	recipe_label.text = "Pick the right ingredients to make this product"

	# Build the available ingredient pool: the correct ones + some decoys
	all_ingredients = required_ingredients.duplicate()
	var decoys: Array[String] = []
	for ing_id in ingredient_names.keys():
		if ing_id not in required_ingredients and decoys.size() < 2:
			decoys.append(ing_id)
	all_ingredients.append_array(decoys)
	all_ingredients.shuffle()

	_build_result_slots()
	_build_ingredients()
	_update_craft_btn()

	visible = true

	# Slide-in animation
	$PanelBG.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($PanelBG, "modulate:a", 1.0, 0.3)

	Analytics.track_event("puzzle_started", {"puzzle_id": id, "type": "recipe"})

func _build_result_slots() -> void:
	for child in result_container.get_children():
		child.queue_free()
	for i in required_ingredients.size():
		var slot = ColorRect.new()
		slot.custom_minimum_size = Vector2(100, 100)
		slot.color = Color(0.82, 0.8, 0.77, 1)
		# Border
		var border = ColorRect.new()
		border.custom_minimum_size = Vector2(100, 100)
		border.color = Color(0.6, 0.58, 0.55)
		border.anchors_preset = Control.PRESET_FULL_RECT
		border.size = Vector2(100, 100)
		slot.add_child(border)
		# Inner
		var inner = ColorRect.new()
		inner.position = Vector2(3, 3)
		inner.size = Vector2(94, 94)
		inner.color = Color(0.88, 0.86, 0.83)
		slot.add_child(inner)
		# "?" label
		var label = Label.new()
		label.text = "?"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchors_preset = Control.PRESET_FULL_RECT
		label.modulate.a = 0.4
		slot.add_child(label)
		result_container.add_child(slot)

func _build_ingredients() -> void:
	for child in ingredients_container.get_children():
		child.queue_free()
	for ing_id in all_ingredients:
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 80)
		btn.text = ingredient_names.get(ing_id, ing_id)

		var color = ingredient_colors.get(ing_id, Color.WHITE)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = color
		stylebox.corner_radius_top_left = 10
		stylebox.corner_radius_top_right = 10
		stylebox.corner_radius_bottom_left = 10
		stylebox.corner_radius_bottom_right = 10
		stylebox.content_margin_left = 8.0
		stylebox.content_margin_right = 8.0
		stylebox.content_margin_top = 8.0
		stylebox.content_margin_bottom = 8.0

		var pressed_style = stylebox.duplicate()
		pressed_style.bg_color = color.darkened(0.2)

		# Selected state -- bright outline
		var selected_style = stylebox.duplicate()
		selected_style.border_width_left = 3
		selected_style.border_width_right = 3
		selected_style.border_width_top = 3
		selected_style.border_width_bottom = 3
		selected_style.border_color = Color.WHITE

		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		var captured_id = ing_id
		var captured_btn = btn
		btn.pressed.connect(func(): _on_ingredient_tapped(captured_id, captured_btn))
		ingredients_container.add_child(btn)

		# Pop-in animation
		btn.scale = Vector2(0.5, 0.5)
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_ingredient_tapped(ing_id: String, btn: Button) -> void:
	if is_solved:
		return
	move_count += 1

	# Toggle selection
	if ing_id in selected_ingredients:
		selected_ingredients.erase(ing_id)
		# Remove white border
		var color = ingredient_colors.get(ing_id, Color.WHITE)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = color
		stylebox.corner_radius_top_left = 10
		stylebox.corner_radius_top_right = 10
		stylebox.corner_radius_bottom_left = 10
		stylebox.corner_radius_bottom_right = 10
		stylebox.content_margin_left = 8.0
		stylebox.content_margin_right = 8.0
		stylebox.content_margin_top = 8.0
		stylebox.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		# Bounce down
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.05)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		if selected_ingredients.size() >= required_ingredients.size():
			# Already picked enough -- flash warning
			result_label.text = "Too many! Tap one to deselect."
			result_label.modulate = Color(0.9, 0.7, 0.3)
			return
		selected_ingredients.append(ing_id)
		# Add white border
		var color = ingredient_colors.get(ing_id, Color.WHITE)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = color
		stylebox.corner_radius_top_left = 10
		stylebox.corner_radius_top_right = 10
		stylebox.corner_radius_bottom_left = 10
		stylebox.corner_radius_bottom_right = 10
		stylebox.content_margin_left = 8.0
		stylebox.content_margin_right = 8.0
		stylebox.content_margin_top = 8.0
		stylebox.content_margin_bottom = 8.0
		stylebox.border_width_left = 3
		stylebox.border_width_right = 3
		stylebox.border_width_top = 3
		stylebox.border_width_bottom = 3
		stylebox.border_color = Color.WHITE
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		# Bounce up
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.08)
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.08)

	_update_result_slots()
	_update_craft_btn()
	result_label.text = ""
	result_label.modulate = Color.WHITE

func _update_result_slots() -> void:
	for i in result_container.get_child_count():
		var slot = result_container.get_child(i)
		if i < selected_ingredients.size():
			var ing_id = selected_ingredients[i]
			var color = ingredient_colors.get(ing_id, Color.WHITE)
			slot.color = color
			slot.get_child(1).color = color
			slot.get_child(2).text = ingredient_names.get(ing_id, ing_id)
			slot.get_child(2).modulate.a = 1.0
		else:
			slot.color = Color(0.82, 0.8, 0.77, 1)
			slot.get_child(1).color = Color(0.88, 0.86, 0.83)
			slot.get_child(2).text = "?"
			slot.get_child(2).modulate.a = 0.4

func _update_craft_btn() -> void:
	craft_btn.visible = selected_ingredients.size() == required_ingredients.size()

func _on_craft() -> void:
	if is_solved:
		return
	var time_taken = Time.get_unix_time_from_system() - start_time

	# Check if selected ingredients match required (order doesn't matter)
	var selected_sorted = selected_ingredients.duplicate()
	selected_sorted.sort()
	var required_sorted = required_ingredients.duplicate()
	required_sorted.sort()

	if selected_sorted == required_sorted:
		is_solved = true
		result_label.text = "Perfect craft!"
		result_label.modulate = Color(0.2, 0.7, 0.3)
		# Flash all slots green
		for slot in result_container.get_children():
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.6, 1.0, 0.6), 0.3)
			tween.tween_property(slot, "modulate", Color.WHITE, 0.3)
		# Flash craft button
		var recipe_color = recipes[target_recipe]["color"]
		var btn_style = StyleBoxFlat.new()
		btn_style.bg_color = recipe_color
		btn_style.corner_radius_top_left = 8
		btn_style.corner_radius_top_right = 8
		btn_style.corner_radius_bottom_left = 8
		btn_style.corner_radius_bottom_right = 8
		craft_btn.add_theme_stylebox_override("normal", btn_style)
		craft_btn.text = "Done!"
		Analytics.track_event("puzzle_solved", {
			"puzzle_id": puzzle_id,
			"time": time_taken,
			"moves": move_count,
		})
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): puzzle_completed.emit(puzzle_id, time_taken, move_count))
	else:
		result_label.text = "Wrong ingredients!"
		result_label.modulate = Color(0.9, 0.3, 0.3)
		# Flash slots red
		for slot in result_container.get_children():
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(1.0, 0.5, 0.5), 0.2)
			tween.tween_property(slot, "modulate", Color.WHITE, 0.2)
		Analytics.track_event("puzzle_failed", {"puzzle_id": puzzle_id, "moves": move_count})
		# Reset after a moment
		var timer = get_tree().create_timer(1.2)
		timer.timeout.connect(func():
			selected_ingredients = []
			result_label.text = ""
			result_label.modulate = Color.WHITE
			_update_result_slots()
			_update_craft_btn()
			# Re-deselect all buttons visually
			_build_ingredients()
		)

func _on_close() -> void:
	var tween = create_tween()
	tween.tween_property($PanelBG, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		puzzle_closed.emit()
	)
