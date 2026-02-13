extends Control

## SortingPuzzle - The first puzzle type in The Veil.
## Customer requests items in a specific order. Player drags items
## into the correct slots. Secretly teaches sorting/pattern recognition.

signal puzzle_completed(puzzle_id: String, time_taken: float, moves: int)
signal puzzle_failed(puzzle_id: String)
signal puzzle_closed

@onready var title_label: Label = $PanelBG/TitleLabel
@onready var instruction_label: Label = $PanelBG/InstructionLabel
@onready var slots_container: HBoxContainer = $PanelBG/SlotsContainer
@onready var items_container: HBoxContainer = $PanelBG/ItemsContainer
@onready var result_label: Label = $PanelBG/ResultLabel
@onready var close_btn: Button = $PanelBG/CloseBtn

var puzzle_id: String = ""
var target_order: Array[String] = []
var current_order: Array[String] = []
var available_items: Array[String] = []
var move_count: int = 0
var start_time: float = 0.0
var is_solved: bool = false

# Item display data
var item_colors: Dictionary = {
	"bread": Color(0.85, 0.72, 0.45),
	"candle": Color(0.95, 0.88, 0.55),
	"herbs": Color(0.45, 0.7, 0.4),
	"soap": Color(0.72, 0.62, 0.82),
	"tea": Color(0.6, 0.75, 0.5),
	"pottery": Color(0.75, 0.55, 0.4),
}

var item_names: Dictionary = {
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
	result_label.text = ""

func start_puzzle(id: String, requested_items: Array[String]) -> void:
	puzzle_id = id
	target_order = requested_items.duplicate()
	is_solved = false
	move_count = 0
	start_time = Time.get_unix_time_from_system()
	result_label.text = ""

	# Shuffle items for the puzzle
	available_items = requested_items.duplicate()
	available_items.shuffle()
	current_order = []

	title_label.text = "Customer Order"
	instruction_label.text = "Tap items in the right order: %s" % _format_order(target_order)

	_build_slots()
	_build_items()

	visible = true
	Analytics.track_event("puzzle_started", {"puzzle_id": id, "type": "sorting"})

func _format_order(order: Array[String]) -> String:
	var names: Array[String] = []
	for item_id in order:
		names.append(item_names.get(item_id, item_id))
	return ", ".join(names)

func _build_slots() -> void:
	for child in slots_container.get_children():
		child.queue_free()
	for i in target_order.size():
		var slot = ColorRect.new()
		slot.custom_minimum_size = Vector2(80, 80)
		slot.color = Color(0.8, 0.78, 0.75, 1)
		var label = Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchors_preset = Control.PRESET_FULL_RECT
		slot.add_child(label)
		slots_container.add_child(slot)

func _build_items() -> void:
	for child in items_container.get_children():
		child.queue_free()
	for item_id in available_items:
		if item_id in current_order:
			continue
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(80, 80)
		btn.text = item_names.get(item_id, item_id)
		var color = item_colors.get(item_id, Color.WHITE)
		var stylebox = StyleBoxFlat.new()
		stylebox.bg_color = color
		stylebox.corner_radius_top_left = 8
		stylebox.corner_radius_top_right = 8
		stylebox.corner_radius_bottom_left = 8
		stylebox.corner_radius_bottom_right = 8
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", stylebox)
		var captured_id = item_id
		btn.pressed.connect(func(): _on_item_picked(captured_id))
		items_container.add_child(btn)

func _on_item_picked(item_id: String) -> void:
	if is_solved:
		return
	move_count += 1
	current_order.append(item_id)

	# Update the slot visual
	var slot_index = current_order.size() - 1
	if slot_index < slots_container.get_child_count():
		var slot = slots_container.get_child(slot_index)
		slot.color = item_colors.get(item_id, Color.WHITE)
		slot.get_child(0).text = item_names.get(item_id, item_id)

	# Rebuild available items (remove picked one)
	_build_items()

	# Check if puzzle is complete
	if current_order.size() == target_order.size():
		_check_solution()

func _check_solution() -> void:
	var time_taken = Time.get_unix_time_from_system() - start_time
	if current_order == target_order:
		is_solved = true
		result_label.text = "Perfect! Order filled correctly."
		Analytics.track_event("puzzle_solved", {
			"puzzle_id": puzzle_id,
			"time": time_taken,
			"moves": move_count,
		})
		# Delay then emit signal
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): puzzle_completed.emit(puzzle_id, time_taken, move_count))
	else:
		result_label.text = "Wrong order. Try again!"
		Analytics.track_event("puzzle_failed", {"puzzle_id": puzzle_id, "moves": move_count})
		# Reset after a moment
		var timer = get_tree().create_timer(1.0)
		timer.timeout.connect(func():
			current_order = []
			result_label.text = ""
			_build_slots()
			_build_items()
		)

func _on_close() -> void:
	visible = false
	puzzle_closed.emit()
