extends Node2D

## ShelfStock - Tracks inventory levels per shelf.
## Shelves deplete when customers are served. Player restocks by tapping.
## Stock level affects customer reward multiplier.

signal stock_changed(shelf_id: String, level: int)
signal restock_complete(shelf_id: String)

var stock: Dictionary = {
	"shelf_left": 3,
	"shelf_right": 3,
	"shelf_back_left": 2,
	"shelf_back_right": 2,
}

var max_stock: Dictionary = {
	"shelf_left": 3,
	"shelf_right": 3,
	"shelf_back_left": 2,
	"shelf_back_right": 2,
}

# Visual positions (match shop_visuals.gd shelf draw positions)
var shelf_rects: Dictionary = {
	"shelf_left": Rect2(42, 195, 158, 210),
	"shelf_right": Rect2(520, 195, 158, 210),
	"shelf_back_left": Rect2(130, 118, 140, 45),
	"shelf_back_right": Rect2(450, 118, 140, 45),
}

var _pulse: float = 0.0
var _any_depleted: bool = false

func deplete_random(count: int = 1) -> void:
	for _i in count:
		var candidates: Array[String] = []
		for sid in stock:
			if stock[sid] > 0:
				candidates.append(sid)
		if candidates.is_empty():
			return
		var sid = candidates[randi() % candidates.size()]
		stock[sid] = maxi(stock[sid] - 1, 0)
		stock_changed.emit(sid, stock[sid])
	_check_depleted()
	queue_redraw()

func restock(shelf_id: String) -> bool:
	if stock[shelf_id] >= max_stock[shelf_id]:
		return false
	stock[shelf_id] = max_stock[shelf_id]
	stock_changed.emit(shelf_id, stock[shelf_id])
	restock_complete.emit(shelf_id)
	_check_depleted()
	queue_redraw()
	return true

func is_depleted(shelf_id: String) -> bool:
	return stock.get(shelf_id, 0) < max_stock.get(shelf_id, 0)

func get_stock_ratio() -> float:
	var total := 0
	var cap := 0
	for sid in stock:
		total += stock[sid]
		cap += max_stock[sid]
	if cap == 0:
		return 1.0
	return float(total) / float(cap)

func get_reward_multiplier() -> float:
	# Full stock = 1.0x, half = 0.75x, empty = 0.5x
	return 0.5 + 0.5 * get_stock_ratio()

func reset_all() -> void:
	for sid in stock:
		stock[sid] = max_stock[sid]
	_any_depleted = false
	queue_redraw()

func _check_depleted() -> void:
	_any_depleted = false
	for sid in stock:
		if stock[sid] < max_stock[sid]:
			_any_depleted = true
			return

func _process(delta: float) -> void:
	if _any_depleted:
		_pulse += delta
		queue_redraw()

func _draw() -> void:
	var pulse_val = (sin(_pulse * 3.5) + 1.0) / 2.0
	for sid in stock:
		var missing = max_stock[sid] - stock[sid]
		if missing <= 0:
			continue
		var rect: Rect2 = shelf_rects[sid]
		var ratio = float(missing) / float(max_stock[sid])
		# Dark overlay — more depleted = darker
		draw_rect(rect, Color(0, 0, 0, 0.12 * ratio))
		# Pulsing orange warning border
		var alpha = (0.25 + 0.25 * pulse_val) * ratio
		var warn = Color(1.0, 0.55, 0.1, alpha)
		draw_rect(Rect2(rect.position.x, rect.position.y, rect.size.x, 3), warn)
		draw_rect(Rect2(rect.position.x, rect.end.y - 3, rect.size.x, 3), warn)
		draw_rect(Rect2(rect.position.x, rect.position.y, 3, rect.size.y), warn)
		draw_rect(Rect2(rect.end.x - 3, rect.position.y, 3, rect.size.y), warn)
		# Center restock indicator dot when fully empty
		if stock[sid] == 0:
			var c = rect.get_center()
			var dot_alpha = 0.5 + 0.35 * pulse_val
			draw_circle(c, 16, Color(1.0, 0.45, 0.1, dot_alpha * 0.4))
			draw_circle(c, 10, Color(1.0, 0.6, 0.2, dot_alpha))
