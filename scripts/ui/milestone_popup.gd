extends Control

## MilestonePopup - Shows achievement banners when the player hits milestones.
## Slides in from top, holds, slides out. Queues multiple milestones.

var _queue: Array[Dictionary] = []
var _showing: bool = false

# Track which milestones have been triggered
var _triggered: Dictionary = {}

# Milestone definitions: check after each order/day
var milestones: Array[Dictionary] = [
	{"id": "first_sale", "title": "First Sale!", "desc": "You served your first customer.", "check": "coins", "threshold": 1},
	{"id": "coin_50", "title": "Coin Collector", "desc": "Earned 50 coins total.", "check": "coins", "threshold": 50},
	{"id": "coin_100", "title": "Hundred Club", "desc": "Earned 100 coins total.", "check": "coins", "threshold": 100},
	{"id": "coin_250", "title": "Big Money", "desc": "Earned 250 coins.", "check": "coins", "threshold": 250},
	{"id": "coin_500", "title": "Half a Grand", "desc": "500 coins and counting!", "check": "coins", "threshold": 500},
	{"id": "streak_3", "title": "Hot Streak!", "desc": "3 customers in a row.", "check": "streak", "threshold": 3},
	{"id": "streak_5", "title": "On Fire!", "desc": "5 customer streak!", "check": "streak", "threshold": 5},
	{"id": "day_3", "title": "Regular Hours", "desc": "Completed 3 days.", "check": "day", "threshold": 3},
	{"id": "day_7", "title": "One Week In", "desc": "A full week of business!", "check": "day", "threshold": 7},
	{"id": "puzzle_10", "title": "Puzzle Pro", "desc": "Solved 10 puzzles.", "check": "puzzles", "threshold": 10},
	{"id": "puzzle_25", "title": "Master Crafter", "desc": "25 puzzles solved!", "check": "puzzles", "threshold": 25},
	{"id": "perfect_day", "title": "Perfect Day", "desc": "Served every customer with 75%+ patience.", "check": "special", "threshold": 0},
]

func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func check_milestones(context: Dictionary) -> void:
	## context keys: coins, streak, day, puzzles, perfect_day
	for m in milestones:
		if m["id"] in _triggered:
			continue
		var triggered = false
		match m["check"]:
			"coins":
				if context.get("coins", 0) >= m["threshold"]:
					triggered = true
			"streak":
				if context.get("streak", 0) >= m["threshold"]:
					triggered = true
			"day":
				if context.get("day", 0) >= m["threshold"]:
					triggered = true
			"puzzles":
				if context.get("puzzles", 0) >= m["threshold"]:
					triggered = true
			"special":
				if m["id"] == "perfect_day" and context.get("perfect_day", false):
					triggered = true
		if triggered:
			_triggered[m["id"]] = true
			_queue.append(m)
			Analytics.track_event("milestone_reached", {"milestone": m["id"]})
	if not _queue.is_empty() and not _showing:
		_show_next()

func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		visible = false
		return
	_showing = true
	visible = true
	var m = _queue.pop_front()

	# Clear old children
	for child in get_children():
		child.queue_free()

	# Banner background
	var banner = ColorRect.new()
	banner.name = "Banner"
	banner.position = Vector2(60, -100)  # Start off-screen
	banner.size = Vector2(600, 90)
	banner.color = Color(0.12, 0.1, 0.15, 0.95)
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(banner)

	# Gold accent line
	var accent = ColorRect.new()
	accent.position = Vector2(0, 0)
	accent.size = Vector2(600, 4)
	accent.color = Color(1.0, 0.8, 0.2)
	accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(accent)

	# Bottom accent
	var accent_bot = ColorRect.new()
	accent_bot.position = Vector2(0, 86)
	accent_bot.size = Vector2(600, 4)
	accent_bot.color = Color(1.0, 0.8, 0.2)
	accent_bot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(accent_bot)

	# Star icon area
	var star = Label.new()
	star.text = "*"
	star.add_theme_font_size_override("font_size", 42)
	star.position = Vector2(15, 15)
	star.size = Vector2(50, 50)
	star.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	star.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	star.modulate = Color(1.0, 0.85, 0.2)
	star.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(star)

	# Title
	var title = Label.new()
	title.text = m["title"]
	title.add_theme_font_size_override("font_size", 30)
	title.position = Vector2(70, 10)
	title.size = Vector2(510, 40)
	title.modulate = Color(1.0, 0.95, 0.75)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(title)

	# Description
	var desc = Label.new()
	desc.text = m["desc"]
	desc.add_theme_font_size_override("font_size", 22)
	desc.position = Vector2(70, 48)
	desc.size = Vector2(510, 30)
	desc.modulate = Color(0.75, 0.72, 0.68)
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner.add_child(desc)

	# Animate: slide in from top
	var tween = create_tween()
	tween.tween_property(banner, "position:y", 20.0, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	# Hold
	tween.tween_interval(2.5)
	# Slide out
	tween.tween_property(banner, "position:y", -110.0, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_callback(_show_next)

func get_triggered_milestones() -> Dictionary:
	return _triggered

func load_triggered(data: Dictionary) -> void:
	_triggered = data
