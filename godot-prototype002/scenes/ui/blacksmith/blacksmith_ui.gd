extends Control
# Crafting UI for the blacksmith.
# Shows available recipes, material costs, and craft button.

@onready var recipe_list: VBoxContainer = $Panel/VBox/RecipeList
@onready var detail_panel: VBoxContainer = $Panel/VBox/Detail
@onready var craft_button: Button = $Panel/VBox/Detail/CraftButton
@onready var result_label: Label = $Panel/VBox/Detail/ResultLabel
@onready var blueprint_submit_button: Button = $Panel/VBox/BlueprintSubmit
@onready var close_button: Button = $Panel/VBox/CloseButton

var _selected_recipe_id: String = ""

func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	craft_button.pressed.connect(_on_craft_pressed)
	blueprint_submit_button.pressed.connect(_on_blueprint_submit_pressed)
	visible = false


func open() -> void:
	visible = true
	_refresh_recipes()


func _refresh_recipes() -> void:
	for child in recipe_list.get_children():
		child.queue_free()
	_selected_recipe_id = ""
	detail_panel.visible = false

	var available: Array = GameData.get_available_recipes(PlayerProfile.blueprints)
	for recipe_id in available:
		var recipe: Dictionary = GameData.recipes[recipe_id]
		var btn := Button.new()
		btn.text = recipe["name"]
		# Capture recipe_id by value for the closure
		var captured_id: String = recipe_id
		btn.pressed.connect(func(): _select_recipe(captured_id))
		recipe_list.add_child(btn)


func _select_recipe(recipe_id: String) -> void:
	_selected_recipe_id = recipe_id
	var recipe: Dictionary = GameData.recipes[recipe_id]
	detail_panel.visible = true
	result_label.text = ""

	# Show material requirements
	var cost_text: String = "必要素材:\n"
	for mat_id in recipe["materials"]:
		var need: int = int(recipe["materials"][mat_id])
		var have: int = int(PlayerProfile.materials.get(mat_id, 0))
		var mat_name: String = GameData.materials.get(mat_id, {}).get("name", mat_id)
		var ok: String = "✓" if have >= need else "✗"
		cost_text += "  %s %s %d/%d\n" % [ok, mat_name, have, need]
	result_label.text = cost_text

	craft_button.disabled = not PlayerProfile.has_materials(recipe["materials"])


func _on_craft_pressed() -> void:
	if _selected_recipe_id.is_empty():
		return
	var recipe: Dictionary = GameData.recipes[_selected_recipe_id]
	if not PlayerProfile.use_materials(recipe["materials"]):
		result_label.text = "素材が足りません"
		return
	PlayerProfile.add_to_warehouse(_selected_recipe_id)
	PlayerProfile.save_profile()
	result_label.text = recipe["name"] + " をクラフトしました！\n倉庫に追加されました。"
	craft_button.disabled = true


func _on_blueprint_submit_pressed() -> void:
	# In a full implementation this would open a blueprint selection UI.
	# Blueprints are picked up in the field as items, then submitted here to unlock recipes.
	result_label.text = "設計図はフィールドで設計図アイテムを拾うと入手できます"
