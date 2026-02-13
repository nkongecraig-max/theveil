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
	card.custom_minimum_size = Vector2(0, 100)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	# Color swatch
	var swatch = ColorRect.new()
	swatch.custom_minimum_size = Vector2(60, 60)
	swatch.color = Color(item["color"][0], item["color"][1], item["color"][2])
	hbox.add_child(swatch)

	# Info
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = item["name"]
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = item["description"]
	desc_label.add_theme_font_size_override("font_size", 22)
	desc_label.modulate.a = 0.7
	vbox.add_child(desc_label)

	hbox.add_child(vbox)

	# Price
	var price_label = Label.new()
	price_label.text = "%d c" % item["price"]
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	price_label.custom_minimum_size = Vector2(50, 0)
	hbox.add_child(price_label)

	card.add_child(hbox)

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
