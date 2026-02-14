extends Control

## UpgradeShop - Panel where players spend coins on shop improvements.
## Opens from the day summary screen or a dedicated tap zone.
## Purchased upgrades are tracked in GameManager.shop_upgrades.

signal upgrade_purchased(upgrade_id: String)
signal panel_closed()

@onready var panel_bg: ColorRect = $PanelBG
@onready var title_label: Label = $PanelBG/TitleLabel
@onready var coins_display: Label = $PanelBG/CoinsDisplay
@onready var item_container: VBoxContainer = $PanelBG/ScrollContainer/ItemContainer
@onready var close_btn: Button = $PanelBG/CloseBtn

var is_open: bool = false

# All available upgrades — id, name, description, cost, icon_color, effect
var upgrade_catalog: Array[Dictionary] = [
	{
		"id": "better_counter",
		"name": "Oak Counter",
		"desc": "A sturdy counter. Customers tip 2 extra coins.",
		"cost": 25,
		"color": Color(0.55, 0.4, 0.25),
		"tier": 1,
	},
	{
		"id": "shop_sign",
		"name": "Shop Sign",
		"desc": "Hang a sign outside. +1 customer per day.",
		"cost": 30,
		"color": Color(0.8, 0.65, 0.3),
		"tier": 1,
	},
	{
		"id": "lantern",
		"name": "Warm Lantern",
		"desc": "Cozy lighting. Puzzle time limits are more forgiving.",
		"cost": 20,
		"color": Color(0.9, 0.75, 0.4),
		"tier": 1,
	},
	{
		"id": "herb_garden",
		"name": "Herb Garden",
		"desc": "Grow your own herbs. Recipe puzzles give +3 bonus.",
		"cost": 40,
		"color": Color(0.4, 0.7, 0.35),
		"tier": 2,
	},
	{
		"id": "display_case",
		"name": "Display Case",
		"desc": "Show off goods. Memory puzzles reveal 1 extra second.",
		"cost": 35,
		"color": Color(0.6, 0.75, 0.85),
		"tier": 2,
	},
	{
		"id": "bell",
		"name": "Service Bell",
		"desc": "Ding! Customers arrive faster between orders.",
		"cost": 50,
		"color": Color(0.85, 0.8, 0.3),
		"tier": 2,
	},
	{
		"id": "premium_shelves",
		"name": "Premium Shelves",
		"desc": "Fine wood shelving. All rewards +20%.",
		"cost": 75,
		"color": Color(0.5, 0.35, 0.2),
		"tier": 3,
	},
	{
		"id": "garden_expansion",
		"name": "Garden Expansion",
		"desc": "Bigger garden. Unlocks rare recipe ingredients.",
		"cost": 60,
		"color": Color(0.3, 0.6, 0.3),
		"tier": 3,
	},
]

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close_panel)

func open_panel() -> void:
	if is_open:
		return
	is_open = true
	_refresh_list()
	_update_coins_display()
	visible = true
	# Slide up
	panel_bg.position.y = 600.0
	var tween = create_tween()
	tween.tween_property(panel_bg, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func close_panel() -> void:
	if not is_open:
		return
	var tween = create_tween()
	tween.tween_property(panel_bg, "position:y", 600.0, 0.2).set_ease(Tween.EASE_IN)
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
		# Add a checkmark overlay effect — dim the color
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
	# Find the upgrade data
	var upgrade_data: Dictionary = {}
	for u in upgrade_catalog:
		if u["id"] == upgrade_id:
			upgrade_data = u
			break

	if upgrade_data.is_empty():
		return

	# Try to spend coins
	if not GameManager.spend_coins(upgrade_data["cost"]):
		return

	# Track the purchase
	GameManager.shop_upgrades.append(upgrade_id)
	upgrade_purchased.emit(upgrade_id)
	Analytics.track_event("upgrade_purchased", {"id": upgrade_id, "cost": upgrade_data["cost"]})
	print("[UpgradeShop] Purchased: %s for %d coins" % [upgrade_data["name"], upgrade_data["cost"]])

	# Refresh the list to show owned state
	_refresh_list()
	_update_coins_display()

	# Flash feedback
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

# -- Upgrade effect helpers (called by shop.gd) --

static func has_upgrade(upgrade_id: String) -> bool:
	return upgrade_id in GameManager.shop_upgrades

static func get_tip_bonus() -> int:
	# Oak Counter gives +2 tip
	if "better_counter" in GameManager.shop_upgrades:
		return 2
	return 0

static func get_extra_customers() -> int:
	# Shop Sign gives +1 customer
	if "shop_sign" in GameManager.shop_upgrades:
		return 1
	return 0

static func get_memory_bonus_time() -> float:
	# Display Case gives +1s reveal
	if "display_case" in GameManager.shop_upgrades:
		return 1.0
	return 0.0

static func get_recipe_bonus() -> int:
	# Herb Garden gives +3 recipe reward
	if "herb_garden" in GameManager.shop_upgrades:
		return 3
	return 0

static func get_reward_multiplier() -> float:
	# Premium Shelves gives 1.2x
	if "premium_shelves" in GameManager.shop_upgrades:
		return 1.2
	return 1.0
