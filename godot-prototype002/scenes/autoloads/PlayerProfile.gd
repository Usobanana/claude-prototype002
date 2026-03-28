extends Node
# Persistent player data: character roster, insurance slot settings,
# crafting materials, warehouse, and equipment selections.
# Saved to user://profile.json between sessions.

const SAVE_PATH := "user://profile.json"

# --- Original fields ---
var owned_characters: Array = []   # list of character definition dicts
var insurance_slots: int = Constants.BASE_INSURANCE_SLOTS
var selected_character_id: String = ""
var insurance_selections: Array = []  # item IDs to protect (up to insurance_slots)
var has_season_pass: bool = false

# --- New fields ---
var player_name: String = ""
var materials: Dictionary = {}            # { "iron": 5, "wood": 3, ... }
var blueprints: Array = []                # unlocked blueprint IDs (plain Array for JSON compat)
var warehouse: Array = []                 # [{ "recipe_id": "recipe_iron_sword", "qty": 1 }, ...]
var equipped_weapon_recipe: String = ""   # empty = class default weapon
var equipped_armor_recipe: String = ""    # empty = no armor


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


# ---------------------------------------------------------------------------
# Material helpers
# ---------------------------------------------------------------------------

func add_material(mat_id: String, amount: int) -> void:
	var current: int = int(materials.get(mat_id, 0))
	materials[mat_id] = current + amount


func has_materials(cost: Dictionary) -> bool:
	for mat_id in cost:
		var need: int = int(cost[mat_id])
		var have: int = int(materials.get(mat_id, 0))
		if have < need:
			return false
	return true


func use_materials(cost: Dictionary) -> bool:
	if not has_materials(cost):
		return false
	for mat_id in cost:
		var need: int = int(cost[mat_id])
		var current: int = int(materials.get(mat_id, 0))
		materials[mat_id] = current - need
	return true


# ---------------------------------------------------------------------------
# Warehouse helpers
# ---------------------------------------------------------------------------

func add_to_warehouse(recipe_id: String) -> void:
	for entry in warehouse:
		if entry.get("recipe_id", "") == recipe_id:
			entry["qty"] = int(entry.get("qty", 0)) + 1
			return
	warehouse.append({ "recipe_id": recipe_id, "qty": 1 })


# ---------------------------------------------------------------------------
# Blueprint helpers
# ---------------------------------------------------------------------------

func unlock_blueprint(bp_id: String) -> void:
	if bp_id not in blueprints:
		blueprints.append(bp_id)


# ---------------------------------------------------------------------------
# Save / Load
# ---------------------------------------------------------------------------

func save_profile() -> void:
	var data := {
		"owned_characters": owned_characters,
		"insurance_slots": insurance_slots,
		"selected_character_id": selected_character_id,
		"insurance_selections": insurance_selections,
		"has_season_pass": has_season_pass,
		"player_name": player_name,
		"materials": materials,
		"blueprints": blueprints,
		"warehouse": warehouse,
		"equipped_weapon_recipe": equipped_weapon_recipe,
		"equipped_armor_recipe": equipped_armor_recipe,
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
	if not parsed is Dictionary:
		return

	owned_characters = parsed.get("owned_characters", [])
	insurance_slots = parsed.get("insurance_slots", Constants.BASE_INSURANCE_SLOTS)
	selected_character_id = parsed.get("selected_character_id", "")
	insurance_selections = parsed.get("insurance_selections", [])
	has_season_pass = parsed.get("has_season_pass", false)
	player_name = parsed.get("player_name", "")
	materials = parsed.get("materials", {})
	blueprints = parsed.get("blueprints", [])
	warehouse = parsed.get("warehouse", [])
	equipped_weapon_recipe = parsed.get("equipped_weapon_recipe", "")
	equipped_armor_recipe = parsed.get("equipped_armor_recipe", "")
