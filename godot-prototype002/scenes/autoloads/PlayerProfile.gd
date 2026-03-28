extends Node
# Persistent player data: character roster, insurance slot settings.
# Saved to user://profile.json between sessions.

const SAVE_PATH := "user://profile.json"

var owned_characters: Array = []   # list of character definition dicts
var insurance_slots: int = Constants.BASE_INSURANCE_SLOTS
var selected_character_id: String = ""
var insurance_selections: Array = []  # item IDs to protect (up to insurance_slots)

# Season pass flag (would be set by a backend/storefront integration)
var has_season_pass: bool = false


func _ready() -> void:
	load_profile()
	if owned_characters.is_empty():
		_init_default_characters()


func _init_default_characters() -> void:
	# Give the player one starter character per class at game start
	for class_id in GameData.classes:
		var class_data: Dictionary = GameData.classes[class_id]
		owned_characters.append({
			"id": class_id + "_starter",
			"class": class_id,
			"name": class_data["name"] + "（初期）",
			"sprite_body": class_data["sprite_body"],
			"stat_mods": {},  # no bonus stats for starter
			"rarity": "common",
		})
	save_profile()


func get_character(char_id: String) -> Dictionary:
	for c in owned_characters:
		if c["id"] == char_id:
			return c
	return {}


func set_season_pass(enabled: bool) -> void:
	has_season_pass = enabled
	insurance_slots = Constants.MAX_INSURANCE_SLOTS if enabled else Constants.BASE_INSURANCE_SLOTS
	save_profile()


func save_profile() -> void:
	var data := {
		"owned_characters": owned_characters,
		"insurance_slots": insurance_slots,
		"selected_character_id": selected_character_id,
		"insurance_selections": insurance_selections,
		"has_season_pass": has_season_pass,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_profile() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		owned_characters = parsed.get("owned_characters", [])
		insurance_slots = parsed.get("insurance_slots", Constants.BASE_INSURANCE_SLOTS)
		selected_character_id = parsed.get("selected_character_id", "")
		insurance_selections = parsed.get("insurance_selections", [])
		has_season_pass = parsed.get("has_season_pass", false)
