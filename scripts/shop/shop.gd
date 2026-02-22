extends Node2D

## Shop - The player's shop. The core space of The Veil.
## ALL tap input is handled here. Taps either open interactions or move the player.

@onready var player: CharacterBody2D = $Player
@onready var camera: Camera2D = $Player/Camera2D
@onready var day_label: Label = $UI/DayLabel
@onready var coins_label: Label = $UI/CoinsLabel
@onready var inventory_panel: Control = $UI/InventoryPanel
@onready var sorting_puzzle: Control = $UI/SortingPuzzle
@onready var recipe_puzzle: Control = $UI/RecipePuzzle
@onready var memory_puzzle: Control = $UI/MemoryPuzzle
@onready var customer_manager: Node = $CustomerManager
@onready var upgrade_shop: Control = $UI/UpgradeShop
@onready var upgrade_btn: Button = $UI/UpgradeBtn

var day_night: CanvasModulate = null
var tap_juice: Node2D = null
var shelf_stock: Node2D = null
var day_intro: Control = null
var screen_shake: Node = null
var milestone_popup: Control = null
var coins_earned_today: int = 0
var _intro_playing: bool = false

# Shelf data
var shelf_items: Dictionary = {
	"shelf_left": ["coffee", "spices", "wine"],
	"shelf_right": ["tools", "leather", "spirits"],
	"shelf_back_left": ["coffee", "tools"],
	"shelf_back_right": ["spices", "leather"],
}

# Shelf positions and sizes for tap detection
var shelf_zones: Dictionary = {
	"shelf_left": Rect2(40, 200, 160, 200),
	"shelf_right": Rect2(520, 200, 160, 200),
	"shelf_back_left": Rect2(130, 120, 140, 40),
	"shelf_back_right": Rect2(450, 120, 140, 40),
}

# Counter zone for tap detection -- big generous area around the counter
var counter_zone: Rect2 = Rect2(140, 850, 440, 180)

# How close player needs to be to interact
const INTERACT_DISTANCE: float = 300.0

func _ready() -> void:
	_setup_visuals()
	_setup_collisions()
	_register_ad_surfaces()
	_update_hud()
	GameManager.game_state_changed.connect(_on_state_changed)
	GameManager.day_advanced.connect(_on_day_advanced)
	inventory_panel.item_selected.connect(_on_item_selected)
	sorting_puzzle.puzzle_completed.connect(_on_puzzle_completed)
	sorting_puzzle.puzzle_closed.connect(_on_puzzle_closed)
	recipe_puzzle.puzzle_completed.connect(_on_puzzle_completed)
	recipe_puzzle.puzzle_closed.connect(_on_puzzle_closed)
	memory_puzzle.puzzle_completed.connect(_on_puzzle_completed)
	memory_puzzle.puzzle_closed.connect(_on_puzzle_closed)
	upgrade_shop.upgrade_purchased.connect(_on_upgrade_purchased)
	upgrade_shop.panel_closed.connect(_on_upgrade_shop_closed)
	upgrade_btn.pressed.connect(_open_upgrade_shop)
	customer_manager.init(self)
	customer_manager.order_filled.connect(_on_order_filled)
	customer_manager.day_complete.connect(_on_day_complete)
	customer_manager.day_progress.connect(_on_day_progress)
	Analytics.track_event("scene_entered", {"scene": "shop"})
	_restore_visual_upgrades()
	# Hide static tap hint — replaced by contextual Day 1 hints
	var old_hint = $UI.get_node_or_null("TapHint")
	if old_hint:
		old_hint.visible = false
	print("[Shop] Welcome to your shop. Day %d." % GameManager.current_day)
	_start_day_with_intro()

func _input(event: InputEvent) -> void:
	# Don't process taps during intro or if a panel is open
	if _intro_playing:
		return
	if inventory_panel.is_open or sorting_puzzle.visible or recipe_puzzle.visible or memory_puzzle.visible or upgrade_shop.is_open:
		return

	var tap_pos: Vector2 = Vector2.ZERO
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap_pos = get_canvas_transform().affine_inverse() * Vector2(event.position)
	elif event is InputEventScreenTouch and event.pressed:
		tap_pos = get_canvas_transform().affine_inverse() * Vector2(event.position)
	else:
		return

	# Priority 1: Did they tap the counter? (and is player close enough?)
	if counter_zone.has_point(tap_pos):
		_dismiss_tutorial_hint_for_action("counter")
		if tap_juice:
			tap_juice.spawn_tap(tap_pos, Color(0.9, 0.75, 0.4))
		var dist = player.global_position.distance_to(counter_zone.get_center())
		if dist < INTERACT_DISTANCE:
			if _try_serve_customer():
				return
		# Not close enough — walk toward counter instead
		player.move_to(Vector2(360, 980))
		return

	# Priority 2: Did they tap a shelf? (and is player close enough?)
	for shelf_id in shelf_zones:
		var zone: Rect2 = shelf_zones[shelf_id]
		if zone.has_point(tap_pos):
			var dist = player.global_position.distance_to(zone.get_center())
			if dist < INTERACT_DISTANCE:
				# If shelf needs restocking, restock it; otherwise open inventory
				if shelf_stock and shelf_stock.is_depleted(shelf_id):
					if shelf_stock.restock(shelf_id):
						if tap_juice:
							tap_juice.spawn_tap(tap_pos, Color(0.3, 1.0, 0.5))
							tap_juice.spawn_floating_text(tap_pos + Vector2(0, -30), "Restocked!", Color(0.3, 0.9, 0.5))
						print("[Shop] Restocked %s!" % shelf_id)
					return
				else:
					if tap_juice:
						tap_juice.spawn_tap(tap_pos, Color(0.6, 0.9, 0.5))
					inventory_panel.open_panel(shelf_id, shelf_items[shelf_id])
					return
			# Not close enough — walk toward shelf
			if tap_juice:
				tap_juice.spawn_tap(tap_pos, Color(0.6, 0.9, 0.5))
			player.move_to(zone.get_center() + Vector2(0, 120))
			return

	# Priority 3: Nothing special tapped — just walk there
	_dismiss_tutorial_hint_for_action("walk")
	if tap_juice:
		tap_juice.spawn_tap(tap_pos, Color(1.0, 1.0, 1.0, 0.4))
	player.move_to(tap_pos)

func _try_serve_customer() -> bool:
	var customer = customer_manager.get_current_customer()
	if customer != null and customer.state == "waiting":
		var puzzle_type = customer_manager.get_puzzle_type()
		if puzzle_type == "recipe":
			var recipe_id = customer_manager.get_recipe_id()
			recipe_puzzle.start_puzzle("craft_%d" % GameManager.current_day, recipe_id)
		elif puzzle_type == "memory":
			var items: Array[String] = []
			items.assign(customer.requested_items)
			memory_puzzle.start_puzzle("memory_%d" % GameManager.current_day, items)
		else:
			var items: Array[String] = []
			items.assign(customer.requested_items)
			sorting_puzzle.start_puzzle("order_%d" % GameManager.current_day, items)
		return true
	return false

func _on_item_selected(item_id: String) -> void:
	print("[Shop] Browsing item: %s" % item_id)

func _on_puzzle_completed(_puzzle_id: String, _time_taken: float, _moves: int) -> void:
	var customer = customer_manager.get_current_customer()
	if customer:
		customer.complete_order()
		GameManager.complete_puzzle(_puzzle_id)
	sorting_puzzle.visible = false
	recipe_puzzle.visible = false
	memory_puzzle.visible = false
	# After first puzzle on Day 1 — show shelf restock hint
	if GameManager.current_day == 1 and day_intro and not day_intro.has_hint("shelf"):
		var t = get_tree().create_timer(2.0)
		t.timeout.connect(func():
			if day_intro:
				day_intro.show_hint("shelf", "Tap glowing shelves to restock", Vector2(30, 160), "down")
		)

func _on_puzzle_closed() -> void:
	pass

func _on_order_filled(reward: int) -> void:
	coins_earned_today += reward
	# Deplete 1-2 shelves per order served
	if shelf_stock:
		shelf_stock.deplete_random(randi_range(1, 2))
	if tap_juice:
		tap_juice.spawn_coin_pop(Vector2(360, 900))
		# Floating coin text
		if reward > 0:
			tap_juice.spawn_floating_text(Vector2(360, 860), "+%d coins" % reward, Color(1.0, 0.9, 0.3))
			# Screen shake — bigger for bigger rewards
			if screen_shake:
				screen_shake.shake(clampf(reward * 0.3, 3.0, 12.0))
			# Streak flash
			var streak = customer_manager.get_streak()
			if streak >= 2:
				tap_juice.spawn_streak_flash(Vector2(360, 780), streak)
				if streak >= 3 and screen_shake:
					screen_shake.shake(10.0 + streak * 2.0, 6.0)
		else:
			tap_juice.spawn_floating_text(Vector2(360, 860), "Too slow!", Color(0.9, 0.3, 0.3))
			if screen_shake:
				screen_shake.shake(6.0, 10.0)  # Quick sharp shake
	print("[Shop] Order filled! Earned %d coins." % reward)
	# Check milestones
	if milestone_popup:
		milestone_popup.check_milestones({
			"coins": GameManager.player_coins,
			"streak": customer_manager.get_streak(),
			"day": GameManager.current_day,
			"puzzles": GameManager.puzzles_completed,
		})

func _on_stock_changed(_shelf_id: String, _level: int) -> void:
	_update_hud()

func _on_restock_complete(_shelf_id: String) -> void:
	_update_hud()
	_dismiss_tutorial_hint_for_action("shelf")
	Analytics.track_event("shelf_restocked", {"shelf_id": _shelf_id})

func _on_day_progress(progress: float) -> void:
	if day_night:
		day_night.set_progress(progress)
	if progress == 0.0:
		coins_earned_today = 0

func _start_day_with_intro() -> void:
	_intro_playing = true
	if day_intro:
		day_intro.intro_finished.connect(_on_intro_finished, CONNECT_ONE_SHOT)
		day_intro.show_day_intro(GameManager.current_day)
	else:
		_on_intro_finished()

func _on_intro_finished() -> void:
	_intro_playing = false
	# Start the day with a brief delay before first customer
	customer_manager.start_day_delayed(3.0 if GameManager.current_day == 1 else 1.5)
	# Show Day 1 tutorial hints
	if GameManager.current_day == 1 and day_intro:
		_show_tutorial_hints()

func _show_tutorial_hints() -> void:
	# Show "walk around" hint first
	day_intro.show_hint("walk", "Tap anywhere to walk around", Vector2(220, 700), "down")
	# Counter hint after small delay
	var t1 = get_tree().create_timer(4.0)
	t1.timeout.connect(func():
		if day_intro and not day_intro.has_hint("counter"):
			day_intro.dismiss_hint("walk")
			day_intro.show_hint("counter", "Tap the counter to serve customers", Vector2(170, 810), "down")
	)

func _dismiss_tutorial_hint_for_action(action: String) -> void:
	if not day_intro:
		return
	match action:
		"walk":
			day_intro.dismiss_hint("walk")
		"counter":
			day_intro.dismiss_hint("counter")
		"shelf":
			day_intro.dismiss_hint("shelf")
		"restock":
			day_intro.dismiss_hint("restock")

func _on_day_complete() -> void:
	print("[Shop] All customers served! Day %d complete." % GameManager.current_day)
	GameManager.advance_day()
	SaveManager.save_game()
	_show_day_summary()

func _show_day_summary() -> void:
	var summary = $UI/DaySummary
	summary.visible = true
	var prev_day = GameManager.current_day - 1
	var served = customer_manager.customers_served_today

	# --- Text content ---
	summary.get_node("DayText").text = "Day %d Complete" % prev_day
	summary.get_node("CoinsText").text = ""

	# --- Animate panel slide in ---
	var panel = summary.get_node("Panel")
	var dimmer = summary.get_node("Dimmer")
	dimmer.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	panel.pivot_offset = panel.size / 2
	var show_tween = create_tween().set_parallel(true)
	show_tween.tween_property(dimmer, "modulate:a", 1.0, 0.3)
	show_tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# --- Animated coin counter ---
	var coins_label_node = summary.get_node("CoinsText")
	show_tween.chain().tween_method(func(val: int):
		coins_label_node.text = "+%d coins  |  %d total  |  Lv %d" % [val, GameManager.player_coins, GameManager.player_level]
	, 0, coins_earned_today, 0.6)

	# --- Star rating (1-3 stars based on served count) ---
	var stars = 1
	if served >= 4:
		stars = 3
	elif served >= 3:
		stars = 2
	if not summary.has_node("StarsLabel"):
		var slbl = Label.new()
		slbl.name = "StarsLabel"
		slbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slbl.add_theme_font_size_override("font_size", 44)
		slbl.position = Vector2(110, 460)
		slbl.size = Vector2(500, 50)
		summary.add_child(slbl)
	var star_text = ""
	for i in stars:
		star_text += "*"
	summary.get_node("StarsLabel").text = star_text

	# --- Buttons ---
	summary.get_node("NextBtn").pressed.connect(func():
		_close_day_summary(summary)
	, CONNECT_ONE_SHOT)

	if not summary.has_node("UpgradeBtn"):
		var ubtn = Button.new()
		ubtn.name = "UpgradeBtn"
		ubtn.text = "Shop Upgrades"
		ubtn.add_theme_font_size_override("font_size", 28)
		ubtn.position = Vector2(220, 530)
		ubtn.size = Vector2(280, 50)
		summary.add_child(ubtn)
		ubtn.pressed.connect(func():
			summary.visible = false
			upgrade_shop.open_panel()
			upgrade_shop.panel_closed.connect(func():
				_show_day_summary()
			, CONNECT_ONE_SHOT)
		)

func _close_day_summary(summary: Control) -> void:
	var panel = summary.get_node("Panel")
	var dimmer = summary.get_node("Dimmer")
	var close_tween = create_tween().set_parallel(true)
	close_tween.tween_property(dimmer, "modulate:a", 0.0, 0.25)
	close_tween.tween_property(panel, "scale", Vector2(0.7, 0.7), 0.2).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_BACK)
	close_tween.chain().tween_callback(func():
		summary.visible = false
		# Reset to morning and start new day
		if day_night:
			day_night.snap_to_morning()
		if shelf_stock:
			shelf_stock.reset_all()
		if day_intro:
			day_intro.dismiss_all_hints()
		_start_day_with_intro()
	)

func _setup_visuals() -> void:
	# Add procedural shop background (draws behind everything)
	var shop_vis = Node2D.new()
	shop_vis.name = "ShopVisuals"
	shop_vis.z_index = -5
	shop_vis.set_script(load("res://scripts/visual/shop_visuals.gd"))
	add_child(shop_vis)
	move_child(shop_vis, 0)
	# Hide all ColorRect placeholders
	for node_name in ["Floor", "WallBack", "WallLeft", "WallRight", "Counter", "CounterLabel", "CounterFront", "DoorMat", "DoorLabel"]:
		var node = get_node_or_null(node_name)
		if node:
			node.visible = false
	# Hide shelf visuals (keep StaticBody2D for collision)
	for shelf_name in ["ShelfLeft", "ShelfRight", "ShelfBackLeft", "ShelfBackRight"]:
		var shelf = get_node_or_null(shelf_name)
		if shelf:
			for child in shelf.get_children():
				if child is ColorRect or child is Label:
					child.visible = false
	# Hide ad surface placeholders (frame is drawn by ShopVisuals)
	for ad_name in ["AdBillboardBorder", "AdBillboardLabel"]:
		var node = get_node_or_null(ad_name)
		if node:
			node.visible = false
	# Hide player ColorRects (replaced by PlayerVisual)
	for child_name in ["PlayerOutline", "PlayerVisual", "PlayerLabel"]:
		var node = player.get_node_or_null(child_name)
		if node:
			node.visible = false
	# Add player visual
	var pv = Node2D.new()
	pv.name = "PlayerArt"
	pv.set_script(load("res://scripts/visual/player_visual.gd"))
	player.add_child(pv)
	# Day/night cycle (CanvasModulate tints entire scene)
	day_night = CanvasModulate.new()
	day_night.name = "DayNightCycle"
	day_night.set_script(load("res://scripts/visual/day_night_cycle.gd"))
	add_child(day_night)
	# Shelf stock tracking + visual overlay (above shop visuals, below player)
	shelf_stock = Node2D.new()
	shelf_stock.name = "ShelfStock"
	shelf_stock.z_index = -2
	shelf_stock.set_script(load("res://scripts/shop/shelf_stock.gd"))
	add_child(shelf_stock)
	# Tap feedback effects (draws on top of everything in game world)
	tap_juice = Node2D.new()
	tap_juice.name = "TapJuice"
	tap_juice.z_index = 50
	tap_juice.set_script(load("res://scripts/visual/tap_juice.gd"))
	add_child(tap_juice)
	# Connect shelf_stock signals (after node is created)
	if shelf_stock:
		shelf_stock.stock_changed.connect(_on_stock_changed)
		shelf_stock.restock_complete.connect(_on_restock_complete)
	# Screen shake for impact
	screen_shake = Node.new()
	screen_shake.name = "ScreenShake"
	screen_shake.set_script(load("res://scripts/visual/screen_shake.gd"))
	add_child(screen_shake)
	screen_shake.setup(camera)
	# Day intro overlay (lives in UI CanvasLayer)
	day_intro = Control.new()
	day_intro.name = "DayIntro"
	day_intro.anchors_preset = Control.PRESET_FULL_RECT
	day_intro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	day_intro.set_script(load("res://scripts/ui/day_intro.gd"))
	$UI.add_child(day_intro)
	# Milestone popup system
	milestone_popup = Control.new()
	milestone_popup.name = "MilestonePopup"
	milestone_popup.anchors_preset = Control.PRESET_FULL_RECT
	milestone_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	milestone_popup.set_script(load("res://scripts/ui/milestone_popup.gd"))
	$UI.add_child(milestone_popup)

func _setup_collisions() -> void:
	var player_shape = RectangleShape2D.new()
	player_shape.size = Vector2(32, 32)
	$Player/CollisionShape2D.shape = player_shape

	var shelf_side_shape = RectangleShape2D.new()
	shelf_side_shape.size = Vector2(160, 200)
	$ShelfLeft/CollisionShape2D.shape = shelf_side_shape
	$ShelfRight/CollisionShape2D.shape = shelf_side_shape

	var shelf_back_shape = RectangleShape2D.new()
	shelf_back_shape.size = Vector2(140, 40)
	$ShelfBackLeft/CollisionShape2D.shape = shelf_back_shape
	$ShelfBackRight/CollisionShape2D.shape = shelf_back_shape

	_add_wall_collision(Vector2(360, 60), Vector2(720, 120))
	_add_wall_collision(Vector2(20, 640), Vector2(40, 1280))
	_add_wall_collision(Vector2(700, 640), Vector2(40, 1280))
	_add_wall_collision(Vector2(360, 940), Vector2(320, 60))

func _add_wall_collision(pos: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	body.position = pos
	var shape = CollisionShape2D.new()
	var rect = RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)

func _register_ad_surfaces() -> void:
	AdManager.register_surface("shop_billboard_01", AdManager.SurfaceType.BILLBOARD, $AdBillboard)
	AdManager.register_surface("shop_poster_left", AdManager.SurfaceType.POSTER, $AdPosterLeft)
	AdManager.register_surface("shop_poster_right", AdManager.SurfaceType.POSTER, $AdPosterRight)

func _on_state_changed(key: String, _value: Variant) -> void:
	if key == "player_coins":
		_update_hud()

func _on_day_advanced(_day: int) -> void:
	_update_hud()

func _open_upgrade_shop() -> void:
	upgrade_shop.open_panel()

func _on_upgrade_purchased(upgrade_id: String) -> void:
	_update_hud()
	_apply_visual_upgrade(upgrade_id)
	print("[Shop] Upgrade purchased: %s" % upgrade_id)

func _on_upgrade_shop_closed() -> void:
	pass

func _apply_visual_upgrade(upgrade_id: String) -> void:
	match upgrade_id:
		"better_counter":
			$Counter.color = Color(0.45, 0.3, 0.18)
			$CounterFront.color = Color(0.38, 0.25, 0.14)
			$CounterLabel.text = "OAK COUNTER"
		"shop_sign":
			if not has_node("ShopSign"):
				var sign_rect = ColorRect.new()
				sign_rect.name = "ShopSign"
				sign_rect.position = Vector2(260, 1170)
				sign_rect.size = Vector2(200, 30)
				sign_rect.color = Color(0.8, 0.65, 0.3)
				sign_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(sign_rect)
				var sign_label = Label.new()
				sign_label.text = "OPEN"
				sign_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				sign_label.position = Vector2(0, 2)
				sign_label.size = Vector2(200, 26)
				sign_label.add_theme_font_size_override("font_size", 22)
				sign_rect.add_child(sign_label)
		"lantern":
			$Floor.color = Color(0.94, 0.91, 0.84)
		"herb_garden":
			if not has_node("HerbGarden"):
				var garden = ColorRect.new()
				garden.name = "HerbGarden"
				garden.position = Vector2(60, 440)
				garden.size = Vector2(100, 60)
				garden.color = Color(0.4, 0.65, 0.35)
				garden.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(garden)
		"display_case":
			if not has_node("DisplayCase"):
				var display = ColorRect.new()
				display.name = "DisplayCase"
				display.position = Vector2(540, 870)
				display.size = Vector2(120, 80)
				display.color = Color(0.7, 0.82, 0.9, 0.8)
				display.mouse_filter = Control.MOUSE_FILTER_IGNORE
				add_child(display)
		"premium_shelves":
			$ShelfLeft/ShelfLeftVisual.color = Color(0.45, 0.35, 0.25)
			$ShelfRight/ShelfRightVisual.color = Color(0.45, 0.35, 0.25)
			$ShelfBackLeft/Visual.color = Color(0.43, 0.33, 0.23)
			$ShelfBackRight/Visual.color = Color(0.43, 0.33, 0.23)

func _restore_visual_upgrades() -> void:
	for uid in GameManager.shop_upgrades:
		_apply_visual_upgrade(uid)

func _update_hud() -> void:
	day_label.text = "Day %d  Lv %d" % [GameManager.current_day, GameManager.player_level]
	var stock_text := ""
	if shelf_stock:
		var ratio = shelf_stock.get_stock_ratio()
		if ratio < 1.0:
			var pct = int(ratio * 100)
			stock_text = "  |  Stock %d%%" % pct
	coins_label.text = "%d coins%s" % [GameManager.player_coins, stock_text]
