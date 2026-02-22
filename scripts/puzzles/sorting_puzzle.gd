extends Control

## SortingPuzzle - The first puzzle type in The Veil.
## Customer requests items in a specific order. Player taps items
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

var item_colors: Dictionary = {
	"coffee": Color(0.4, 0.28, 0.18),
	"tools": Color(0.5, 0.52, 0.55),
	"spices": Color(0.85, 0.45, 0.15),
	"leather": Color(0.6, 0.38, 0.2),
	"wine": Color(0.55, 0.15, 0.22),
	"spirits": Color(0.75, 0.55, 0.2),
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

func start_puzzle(id: String, requested_items: Array[String]) -> void:
	puzzle_id = id
	target_order = requested_items.duplicate()
	is_solved = false
	move_count = 0
	start_time = Time.get_unix_time_from_system()
	result_label.text = ""

	available_items = requested_items.duplicate()
	available_items.shuffle()
	current_order = []

	title_label.text = "Customer Order"
	instruction_label.text = "Tap items in order: %s" % _format_order(target_order)

	_build_slots()
	_build_items()

	visible = true

	# Slide-in animation
	$PanelBG.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property($PanelBG, "modulate:a", 1.0, 0.3)

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
		slot.custom_minimum_size = Vector2(100, 100)
		slot.color = Color(0.82, 0.8, 0.77, 1)
		# Slot border
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
		# Number label
		var label = Label.new()
		label.text = str(i + 1)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.anchors_preset = Control.PRESET_FULL_RECT
		label.modulate.a = 0.4
		slot.add_child(label)
		slots_container.add_child(slot)

func _build_items() -> void:
	for child in items_container.get_children():
		child.queue_free()
	for item_id in available_items:
		if item_id in current_order:
			continue
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(120, 80)
		btn.text = item_names.get(item_id, item_id)
		var color = item_colors.get(item_id, Color.WHITE)
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
		# Pressed state slightly darker
		var pressed_style = stylebox.duplicate()
		pressed_style.bg_color = color.darkened(0.2)
		btn.add_theme_stylebox_override("normal", stylebox)
		btn.add_theme_stylebox_override("hover", stylebox)
		btn.add_theme_stylebox_override("pressed", pressed_style)
		var captured_id = item_id
		btn.pressed.connect(func(): _on_item_picked(captured_id))
		items_container.add_child(btn)
		# Pop-in animation for each item
		btn.scale = Vector2(0.5, 0.5)
		btn.pivot_offset = btn.custom_minimum_size / 2.0
		var tween = create_tween()
		tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _on_item_picked(item_id: String) -> void:
	if is_solved:
		return
	move_count += 1
	current_order.append(item_id)

	# Update the slot visual with animation
	var slot_index = current_order.size() - 1
	if slot_index < slots_container.get_child_count():
		var slot = slots_container.get_child(slot_index)
		var color = item_colors.get(item_id, Color.WHITE)
		# Flash the slot
		slot.color = color
		# Update label
		slot.get_child(2).text = item_names.get(item_id, item_id)
		slot.get_child(2).modulate.a = 1.0
		# Update inner color
		slot.get_child(1).color = color
		# Scale bounce
		var tween = create_tween()
		tween.tween_property(slot, "scale", Vector2(1.15, 1.15), 0.1)
		tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1)

	_build_items()

	if current_order.size() == target_order.size():
		_check_solution()

func _check_solution() -> void:
	var time_taken = Time.get_unix_time_from_system() - start_time
	if current_order == target_order:
		is_solved = true
		result_label.text = "Order filled!"
		result_label.modulate = Color(0.2, 0.7, 0.3)
		# Flash all slots green
		for slot in slots_container.get_children():
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(0.6, 1.0, 0.6), 0.3)
			tween.tween_property(slot, "modulate", Color.WHITE, 0.3)
		Analytics.track_event("puzzle_solved", {
			"puzzle_id": puzzle_id,
			"time": time_taken,
			"moves": move_count,
		})
		var timer = get_tree().create_timer(1.5)
		timer.timeout.connect(func(): puzzle_completed.emit(puzzle_id, time_taken, move_count))
	else:
		result_label.text = "Wrong order!"
		result_label.modulate = Color(0.9, 0.3, 0.3)
		# Flash slots red
		for slot in slots_container.get_children():
			var tween = create_tween()
			tween.tween_property(slot, "modulate", Color(1.0, 0.5, 0.5), 0.2)
			tween.tween_property(slot, "modulate", Color.WHITE, 0.2)
		Analytics.track_event("puzzle_failed", {"puzzle_id": puzzle_id, "moves": move_count})
		var timer = get_tree().create_timer(1.2)
		timer.timeout.connect(func():
			current_order = []
			result_label.text = ""
			result_label.modulate = Color.WHITE
			_build_slots()
			_build_items()
		)

func _on_close() -> void:
	var tween = create_tween()
	tween.tween_property($PanelBG, "modulate:a", 0.0, 0.2)
	tween.tween_callback(func():
		visible = false
		puzzle_closed.emit()
	)
