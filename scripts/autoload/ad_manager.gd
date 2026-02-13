extends Node

## AdManager - The diegetic advertising engine.
## Serves ads as in-world content: billboards, newspapers, products, radio.
## Phase 1: Placeholder content. Phase 2+: Real ad SDK integration.

signal ad_content_loaded(surface_id: String)
signal ad_impression(surface_id: String, ad_id: String)
signal ad_interaction(surface_id: String, ad_id: String, interaction_type: String)

# Ad surface types that exist in the game world
enum SurfaceType { BILLBOARD, NEWSPAPER, PRODUCT_LABEL, RADIO, POSTER }

# Registry of all ad surfaces in the current scene
var active_surfaces: Dictionary = {}  # surface_id -> surface_data

# Placeholder ad content (replaced by real ads later)
var ad_catalog: Array[Dictionary] = []

func _ready() -> void:
	_load_placeholder_ads()
	print("[AdManager] Diegetic ad engine ready. %d placeholder ads loaded." % ad_catalog.size())

func _load_placeholder_ads() -> void:
	# Load placeholder ad content from data/ads/
	var dir = DirAccess.open("res://data/ads/")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var file = FileAccess.open("res://data/ads/" + file_name, FileAccess.READ)
				if file:
					var json = JSON.new()
					if json.parse(file.get_as_text()) == OK:
						ad_catalog.append(json.data)
					file.close()
			file_name = dir.get_next()

	# If no files found, use hardcoded placeholders
	if ad_catalog.is_empty():
		ad_catalog = _get_default_placeholders()

func _get_default_placeholders() -> Array[Dictionary]:
	return [
		{
			"id": "placeholder_01",
			"type": "billboard",
			"headline": "Fresh Bread Daily",
			"body": "Visit the bakery on Elm Street",
			"color": Color(0.95, 0.85, 0.6),
		},
		{
			"id": "placeholder_02",
			"type": "newspaper",
			"headline": "Town Festival This Weekend",
			"body": "Don't miss the annual harvest celebration!",
			"color": Color(0.9, 0.9, 0.85),
		},
		{
			"id": "placeholder_03",
			"type": "product",
			"headline": "Mountain Spring Water",
			"body": "Pure refreshment from the highlands",
			"color": Color(0.7, 0.85, 0.95),
		},
	]

# -- Surface Registration --

func register_surface(surface_id: String, surface_type: SurfaceType, node: Node) -> void:
	active_surfaces[surface_id] = {
		"type": surface_type,
		"node": node,
		"current_ad": null,
		"impressions": 0,
	}
	_assign_ad_to_surface(surface_id)

func unregister_surface(surface_id: String) -> void:
	active_surfaces.erase(surface_id)

# -- Ad Serving --

func _assign_ad_to_surface(surface_id: String) -> void:
	if ad_catalog.is_empty():
		return
	# Simple rotation for now. Will be replaced with programmatic serving.
	var ad = ad_catalog[randi() % ad_catalog.size()]
	active_surfaces[surface_id]["current_ad"] = ad
	ad_content_loaded.emit(surface_id)

func get_ad_for_surface(surface_id: String) -> Dictionary:
	if surface_id in active_surfaces and active_surfaces[surface_id]["current_ad"]:
		return active_surfaces[surface_id]["current_ad"]
	return {}

# -- Tracking --

func record_impression(surface_id: String) -> void:
	if surface_id in active_surfaces:
		var ad = active_surfaces[surface_id]["current_ad"]
		if ad:
			active_surfaces[surface_id]["impressions"] += 1
			ad_impression.emit(surface_id, ad.get("id", "unknown"))
			Analytics.track_event("ad_impression", {
				"surface_id": surface_id,
				"ad_id": ad.get("id", "unknown"),
			})

func record_interaction(surface_id: String, interaction_type: String) -> void:
	if surface_id in active_surfaces:
		var ad = active_surfaces[surface_id]["current_ad"]
		if ad:
			ad_interaction.emit(surface_id, ad.get("id", "unknown"), interaction_type)
			Analytics.track_event("ad_interaction", {
				"surface_id": surface_id,
				"ad_id": ad.get("id", "unknown"),
				"type": interaction_type,
			})
