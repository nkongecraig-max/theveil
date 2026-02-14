extends Control

## UpgradeShop - Panel where players spend coins on shop improvements.
## Opens from the day summary screen or a dedicated tap zone.
## Purchased upgrades are tracked in GameManager.shop_upgrades.
## UI is built in code to avoid tscn parsing issues.

signal upgrade_purchased(upgrade_id: String)
signal panel_closed()

var panel_bg: ColorRect
var title_label: Label
var coins_display: Label
var item_container: VBoxContainer
var close_btn: Button

var is_open: bool = false

# All available upgrades
var upgrade_catalog: Array[Dictionary] = [
	{
		"id": "better_counter",
		"name": "Oak Counter",
		"desc": "A sturdy counter. Customers tip 2 extra coins.",
		"cost": 25,
		"color": Color(0.55, 0.4, 0.25),
	},
	{
		"id": "shop_sign",
		"name": "Shop Sign",
		"desc": "Hang a sign outside. +1 customer per day.",
		"cost": 30,
		"color": Color(0.8, 0.65, 0.3),
	},
	{
		"id": "lantern",
		"name": "Warm Lantern",
		"desc": "Cozy lighting. Puzzle time limits are more forgiving.",
		"cost": 20,
		"color": Color(0.9, 0.75, 0.4),
	},
	{
		"id": "herb_garden",
		"name": "Herb Garden",
		"desc": "Grow your own herbs. Recipe puzzles give +3 bonus.",
		"cost": 40,
		"color": Color(0.4, 0.7, 0.35),
	},
	{
		"id": "display_case",
		"name": "Display Case",
		"desc": "Show off goods. Memory puzzles reveal 1 extra second.",
		"cost": 35,
		"color": Color(0.6, 0.75, 0.85),
	},
	{
		"id": "bell",
		"name": "Service Bell",
		"desc": "Ding! Customers arrive faster between orders.",
		"cost": 50,
		"color": Color(0.85, 0.8, 0.3),
	},
	{
		"id": "premium_shelves",
		"name": "Premium Shelves",
		"desc": "Fine wood shelving. All rewards +20%.",
		"cost": 75,
		"color": Color(0.5, 0.35, 0.2),
	},
	{
		"id": "garden_expansion",
		"name": "Garden Expansion",
		"desc": "Bigger garden. Unlocks rare recipe ingredients.",
		"cost": 60,
		"color": Color(0.3, 0.6, 0.3),
	},
]

func _ready() -> void:
	_build_ui()
	visible = false
	close_btn.pressed.connect(close_panel)

func _build_ui() -> void:
	# Dimmer
	var dimmer = ColorRect.new()
	dimmer.set_anchors_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.06, 0.05, 0.08, 0.75)
	dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dimmer)

	# Panel background
	panel_bg = ColorRect.new()
	panel_bg.position = Vector2(40, 120)
	panel_bg.size = Vector2(640, 1040)
	panel_bg.color = Color(0.94, 0.92, 0.88)
	add_child(panel_bg)

	# Title
	title_label = Label.new()
	title_label.text = "Shop Upgrades"
	title_label.add_theme_font_size_override("font_size", 36)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.position = Vector2(20, 16)
	title_label.size = Vector2(600, 54)
	panel_bg.add_child(title_label)

	# Coins display
	coins_display = Label.new()
	coins_display.text = "0 coins available"
	coins_display.add_theme_font_size_override("font_size", 24)
	coins_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	coins_display.position = Vector2(20, 72)
	coins_display.size = Vector2(600, 33)
	panel_bg.add_child(coins_display)

	# Scroll container
	var scroll = ScrollContainer.new()
	scroll.position = Vector2(16, 115)
	scroll.size = Vector2(608, 820)
	panel_bg.add_child(scroll)

	# Item container inside scroll
	item_container = VBoxContainer.new()
	item_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_container.add_theme_constant_override("separation", 8)
	scroll.add_child(item_container)

	# Close button
	close_btn = Button.new()
	close_btn.text = "Close"
	close_btn.add_theme_font_size_override("font_size", 28)
	close_btn.position = Vector2(200, 950)
	close_btn.size = Vector2(240, 60)
	panel_bg.add_child(close_btn)

func open_panel() -> void:
	if is_open:
		return
	is_open = true
	_refresh_list()
	_update_coins_display()
	visible = true
	# Slide up
	panel_bg.position.y = 1300.0
	var tween = create_tween()
	tween.tween_property(panel_bg, "position:y", 120.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func close_panel() -> void:
	if not is_open:
		return
	var tween = create_tween()
	tween.tween_property(panel_bg, "position:y", 1300.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(func():
		visible = false
		is_open = false
		panel_closed.emit()
	)

func _update_coins_display() -> void:
	coins_display.text = "%d coins available" % GameManager.player_coins

func _refresh_list() -> void:
	for child in item_container.get_children():
		child.queue_free()
	for upgrade in upgrade_catalog:
		_add_upgrade_card(upgrade)

func _add_upgrade_card(upgrade: Dictionary) -> void:
	var owned = upgrade["id"] in GameManager.shop_upgrades
	var can_afford = GameManager.player_coins >= upgrade["cost"]

	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 110)

	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)

	# Icon swatch
	var swatch = ColorRect.new()
	swatch.custom_minimum_size = Vector2(60, 60)
	swatch.color = upgrade["color"]
	if owned:
		swatch.color = upgrade["color"].lightened(0.3)
	hbox.add_child(swatch)

	# Info column
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label = Label.new()
	name_label.text = upgrade["name"]
	if owned:
		name_label.text += "  [OWNED]"
		name_label.modulate = Color(0.5, 0.8, 0.5)
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.text = upgrade["desc"]
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.modulate.a = 0.7
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	hbox.add_child(vbox)

	# Buy button / price
	var buy_btn = Button.new()
	buy_btn.custom_minimum_size = Vector2(120, 60)
	if owned:
		buy_btn.text = "Owned"
		buy_btn.disabled = true
	elif can_afford:
		buy_btn.text = "%d c" % upgrade["cost"]
		var uid = upgrade["id"]
		buy_btn.pressed.connect(func(): _buy_upgrade(uid))
	else:
		buy_btn.text = "%d c" % upgrade["cost"]
		buy_btn.disabled = true
	buy_btn.add_theme_font_size_override("font_size", 24)
	hbox.add_child(buy_btn)

	card.add_child(hbox)
	item_container.add_child(card)

func _buy_upgrade(upgrade_id: String) -> void:
	var upgrade_data: Dictionary = {}
	for u in upgrade_catalog:
		if u["id"] == upgrade_id:
			upgrade_data = u
			break
	if upgrade_data.is_empty():
		return
	if not GameManager.spend_coins(upgrade_data["cost"]):
		return

	GameManager.shop_upgrades.append(upgrade_id)
	upgrade_purchased.emit(upgrade_id)
	Analytics.track_event("upgrade_purchased", {"id": upgrade_id, "cost": upgrade_data["cost"]})
	print("[UpgradeShop] Purchased: %s for %d coins" % [upgrade_data["name"], upgrade_data["cost"]])

	_refresh_list()
	_update_coins_display()
	_show_purchase_flash()

func _show_purchase_flash() -> void:
	var flash = ColorRect.new()
	flash.color = Color(0.4, 0.8, 0.4, 0.3)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.4)
	tween.tween_callback(func(): flash.queue_free())

# -- Upgrade effect helpers (called by other scripts) --

static func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in GameManager.shop_upgrades

static func get_tip_bonus() -> int:
	if "better_counter" in GameManager.shop_upgrades:
		return 2
	return 0

static func get_extra_customers() -> int:
	if "shop_sign" in GameManager.shop_upgrades:
		return 1
	return 0

static func get_memory_bonus_time() -> float:
	if "display_case" in GameManager.shop_upgrades:
		return 1.0
	return 0.0

static func get_recipe_bonus() -> int:
	if "herb_garden" in GameManager.shop_upgrades:
		return 3
	return 0

static func get_reward_multiplier() -> float:
	if "premium_shelves" in GameManager.shop_upgrades:
		return 1.2
	return 1.0
