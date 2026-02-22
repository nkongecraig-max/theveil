extends Control

## MemoryPuzzle - The third puzzle type in The Veil.
## Customer shows items briefly, then hides them. Player must tap
## to recall which items were shown. Secretly teaches memory skills.

signal puzzle_completed(puzzle_id: String, time_taken: float, moves: int)
signal puzzle_failed(puzzle_id: String)
signal puzzle_closed

@onready var title_label: Label = $PanelBG/TitleLabel
@onready var instruction_label: Label = $PanelBG/InstructionLabel
@onready var grid_container: GridContainer = $PanelBG/GridContainer
@onready var result_label: Label = $PanelBG/ResultLabel
@onready var close_btn: Button = $PanelBG/CloseBtn

var puzzle_id: String = ""
var target_items: Array[String] = []
var all_items: Array[String] = []
var selected_items: Array[String] = []
var move_count: int = 0
var start_time: float = 0.0
var is_solved: bool = false
var is_reveal_phase: bool = true

var item_colors: Dictionary = {
	"coffee": Color(0.35, 0.2, 0.12),
	"tools": Color(0.35, 0.42, 0.55),
	"spices": Color(0.95, 0.55, 0.08),
	"leather": Color(0.65, 0.4, 0.18),
	"wine": Color(0.62, 0.08, 0.18),
	"spirits": Color(0.85, 0.65, 0.1),
}

var item_names: Dictionary = {
	"coffee": "Coffee",
	"tools": "Tools",
	"spices": "Spices",
	"leather": "Leather",
	"wine": "Wine",
	"spirits": "Spirits",
}

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(_on_close)
	result_label.text = ""

func start_puzzle(id: String, items_to_remember: Array[String]) -> void:
	puzzle_id = id
	is_solved = false
	is_reveal_phase = true
	move_count = 0
	start_time = Time.get_unix_time_from_system()
	result_label.text = ""
	selected_items = []

	target_items = items_to_remember.duplicate()

	# Build pool: target items + decoys to fill a grid
	all_items = target_items.duplicate()
	var decoys: Array[String] = []
	for item_id in item_names.keys():
		if item_id not in target_items and decoys.size() < 3:
			decoys.append(item_id)
	all_items.append_array(decoys)
	all_items.shuffle()

	title_label.text = "Memory Check"
	instruction_label.text = "Remember these items..."

	_build_grid_revealed()

	visible = true

	# Slide-in animation
	$PanelBG.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($PanelBG, "modulate:a", 1.0, 0.3)

	Analytics.track_event("puzzle_started", {"puzzle_id": id, "type": "memory"})

	# Show items for a few seconds, then hide
	var reveal_time = 2.0 + (target_items.size() * 0.5)
	# Display Case upgrade gives extra reveal time
	var UpgradeShop = load("res://scripts/shop/upgrade_shop.gd")
	reveal_time += UpgradeShop.get_memory_bonus_time()
	var timer = get_tree().create_timer(reveal_time)
	timer.timeout.connect(_hide_items)

func _build_grid_revealed() -> void:
	for child in grid_container.get_children():
		child.queue_free()
	grid_container.columns = 3

	for item_id in all_items:
		var card = _create_card(item_id)
		var is_target = item_id in target_items
		if is_target:
			# Show revealed -- colored with name
			var color = item_colors.get(item_id, Color.WHITE)
			card.get_node("Inner").color = color
			card.get_node("Label").text = item_names.get(item_id, item_id)
			card.get_node("Label").modulate.a = 1.0
			# Glow effect for targets
			card.get_node("Border").color = Color(0.3, 0.8, 0.4)
		else:
			# Decoys start face-down
			card.get_node("Inner").color = Color(0.75, 0.73, 0.7)
			card.get_node("Label").text = "?"
			card.get_node("Label").modulate.a = 0.3
		grid_container.add_child(card)

func _hide_items() -> void:
	if is_solved or not visible:
		return
	is_reveal_phase = false
	instruction_label.text = "Tap the items you saw!"

	# Flip all cards face-down
	for card in grid_container.get_children():
		card.get_node("Inner").color = Color(0.75, 0.73, 0.7)
		card.get_node("Border").color = Color(0.6, 0.58, 0.55)
		card.get_node("Label").text = "?"
		card.get_node("Label").modulate.a = 0.3
		# Flip animation
		var tween = create_tween()
		tween.tween_property(card, "scale:x", 0.0, 0.1)
		tween.tween_property(card, "scale:x", 1.0, 0.1)

func _create_card(item_id: String) -> Control:
	var card = Control.new()
	card.custom_minimum_size = Vector2(130, 110)

	# Border
	var border = ColorRect.new()
	border.name = "Border"
	border.position = Vector2(0, 0)
	border.size = Vector2(130, 110)
	border.color = Color(0.6, 0.58, 0.55)
	card.add_child(border)

	# Inner
	var inner = ColorRect.new()
	inner.name = "Inner"
	inner.position = Vector2(3, 3)
	inner.size = Vector2(124, 104)
	inner.color = Color(0.75, 0.73, 0.7)
	card.add_child(inner)

	# Label
	var label = Label.new()
	label.name = "Label"
	label.text = "?"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(0, 0)
	label.size = Vector2(130, 110)
	label.modulate.a = 0.3
	card.add_child(label)

	# Tap button
	var btn = Button.new()
	btn.flat = true
	btn.position = Vector2(0, 0)
	btn.size = Vector2(130, 110)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var captured_id = item_id
	var captured_card = card
	btn.pressed.connect(func(): _on_card_tapped(captured_id, captured_card))
	card.add_child(btn)

	card.pivot_offset = Vector2(65, 55)
	return card

func _on_card_tapped(item_id: String, card: Control) -> void:
	if is_solved or is_reveal_phase:
		return
	move_count += 1

	# Toggle selection
	if item_id in selected_items:
		selected_items.erase(item_id)
		card.get_node("Inner").color = Color(0.75, 0.73, 0.7)
		card.get_node("Border").color = Color(0.6, 0.58, 0.55)
		card.get_node("Label").text = "?"
		card.get_node("Label").modulate.a = 0.3
		# Bounce
		var tween = create_tween()
		tween.tween_property(card, "scale", Vector2(0.9, 0.9), 0.05)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.1)
	else:
		selected_items.append(item_id)
		var color = item_colors.get(item_id, Color.WHITE)
		card.get_node("Inner").color = color
		card.get_node("Border").color = Color.WHITE
		card.get_node("Label").text = item_names.get(item_id, item_id)
		card.get_node("Label").modulate.a = 1.0
		# Bounce
		var tween = create_tween()
		tween.tween_property(card, "scale", Vector2(1.1, 1.1), 0.08)
		tween.tween_property(card, "scale", Vector2(1.0, 1.0), 0.08)

	# Auto-check when player has selected the right count
	if selected_items.size() == target_items.size():
		_check_solution()

func _check_solution() -> void:
	var time_taken = Time.get_unix_time_from_system() - start_time

	var selected_sorted = selected_items.duplicate()
	selected_sorted.sort()
	var target_sorted = target_items.duplicate()
	target_sorted.sort()

	if selected_sorted == target_sorted:
		is_solved = true
		result_label.text = "Perfect memory!"
		result_label.modulate = Color(0.2, 0.7, 0.3)
		# Flash all cards
		for card in grid_container.get_children():
			var tween = create_tween()
			tween.tween_property(card, "modulate", Color(0.6, 1.0, 0.6), 0.3)
			tween.tween_property(card, "modulate", Color.WHITE, 0.3)
		Analytics.track_event("puzzle_solved", {
			"puzzle_id": puzzle_id,
			"time": time_taken,
			"moves": move_count,
		})
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): puzzle_completed.emit(puzzle_id, time_taken, move_count))
	else:
		result_label.text = "Not quite right!"
		result_label.modulate = Color(0.9, 0.3, 0.3)
		# Flash red
		for card in grid_container.get_children():
			var tween = create_tween()
			tween.tween_property(card, "modulate", Color(1.0, 0.5, 0.5), 0.2)
			tween.tween_property(card, "modulate", Color.WHITE, 0.2)
		Analytics.track_event("puzzle_failed", {"puzzle_id": puzzle_id, "moves": move_count})
		# Reset
		var timer = get_tree().create_timer(1.2)
		timer.timeout.connect(func():
			selected_items = []
			result_label.text = ""
			result_label.modulate = Color.WHITE
			# Re-hide all
			_hide_items()
		)

func _on_close() -> void:
	var tween = create_tween()
	tween.tween_property($PanelBG, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		puzzle_closed.emit()
	)
