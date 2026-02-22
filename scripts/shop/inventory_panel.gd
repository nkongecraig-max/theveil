extends Control

## InventoryPanel - Slide-up panel showing shelf items.
## Displays items as colored cards with name and price.
## Player can tap items to stock/restock the shelf.

signal item_selected(item_id: String)

@onready var panel_bg: ColorRect = $PanelBG
@onready var title_label: Label = $PanelBG/TitleLabel
@onready var item_container: VBoxContainer = $PanelBG/ScrollContainer/ItemContainer
@onready var close_btn: Button = $PanelBG/CloseBtn

var item_database: Dictionary = {}
var is_open: bool = false

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_panel)
	_load_item_database()
	# Fix layout: force ScrollContainer to use anchors so it scales with panel
	var scroll = $PanelBG/ScrollContainer
	scroll.layout_mode = 1
	scroll.anchor_left = 0.0
	scroll.anchor_top = 0.0
	scroll.anchor_right = 1.0
	scroll.anchor_bottom = 1.0
	scroll.offset_left = 10
	scroll.offset_top = 60
	scroll.offset_right = -10
	scroll.offset_bottom = -10
	scroll.clip_contents = true
	# Fix CloseBtn position with anchors
	close_btn.layout_mode = 1
	close_btn.anchor_left = 1.0
	close_btn.anchor_right = 1.0
	close_btn.offset_left = -120
	close_btn.offset_top = 6
	close_btn.offset_right = -10
	close_btn.offset_bottom = 54

func _load_item_database() -> void:
	var file = FileAccess.open("res://data/items/starter_items.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		if json.parse(file.get_as_text()) == OK:
			for item in json.data.get("items", []):
				item_database[item["id"]] = item
		file.close()

func open_panel(shelf_id: String, item_ids: Array) -> void:
	if is_open:
		return
	is_open = true
	title_label.text = shelf_id.replace("_", " ").to_upper()

	# Clear old items
	for child in item_container.get_children():
		child.queue_free()

	# Add item cards
	for item_id in item_ids:
		if item_id in item_database:
			var item = item_database[item_id]
			_add_item_card(item)

	visible = true
	# Slide up animation
	panel_bg.position.y = 400.0
	var tween = create_tween()
	tween.tween_property(panel_bg, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func close_panel() -> void:
	if not is_open:
		return
	var tween = create_tween()
	tween.tween_property(panel_bg, "position:y", 400.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(func(): visible = false; is_open = false)

func _add_item_card(item: Dictionary) -> void:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 90)
	card.clip_contents = true

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_bottom", 6)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)

	# Color swatch with border
	var swatch_wrap = Control.new()
	swatch_wrap.custom_minimum_size = Vector2(56, 56)
	var swatch_border = ColorRect.new()
	swatch_border.position = Vector2(0, 0)
	swatch_border.size = Vector2(56, 56)
	swatch_border.color = Color(0.2, 0.15, 0.1)
	swatch_wrap.add_child(swatch_border)
	var swatch = ColorRect.new()
	swatch.position = Vector2(2, 2)
	swatch.size = Vector2(52, 52)
	swatch.color = Color(item["color"][0], item["color"][1], item["color"][2])
	swatch_wrap.add_child(swatch)
	hbox.add_child(swatch_wrap)

	# Info column
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)

	var name_label = Label.new()
	name_label.text = item["name"]
	name_label.add_theme_font_size_override("font_size", 28)
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item["description"]
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.modulate.a = 0.6
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	hbox.add_child(vbox)

	# Price — bold, right-aligned
	var price_label = Label.new()
	price_label.text = "%d c" % item["price"]
	price_label.add_theme_font_size_override("font_size", 28)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	price_label.custom_minimum_size = Vector2(60, 0)
	hbox.add_child(price_label)

	margin.add_child(hbox)
	card.add_child(margin)

	# Make tappable
	var btn = Button.new()
	btn.flat = true
	btn.anchors_preset = Control.PRESET_FULL_RECT
	btn.mouse_filter = Control.MOUSE_FILTER_STOP
	var item_id = item["id"]
	btn.pressed.connect(func(): _on_item_tapped(item_id))
	card.add_child(btn)

	item_container.add_child(card)

func _on_item_tapped(item_id: String) -> void:
	item_selected.emit(item_id)
	Analytics.track_event("item_selected", {"item_id": item_id})
