extends Control
# Equipment UI — lets player select which crafted weapon/armor to bring to the field.

@onready var weapon_list: VBoxContainer = $Panel/VBox/WeaponList
@onready var armor_list: VBoxContainer = $Panel/VBox/ArmorList
@onready var equipped_label: Label = $Panel/VBox/EquippedLabel
@onready var close_button: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	visible = false


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	for child in weapon_list.get_children():
		child.queue_free()
	for child in armor_list.get_children():
		child.queue_free()

	# Default options
	var default_btn := Button.new()
	default_btn.text = "【デフォルト】クラス標準武器"
	default_btn.pressed.connect(func(): _equip_weapon(""))
	weapon_list.add_child(default_btn)

	var no_armor_btn := Button.new()
	no_armor_btn.text = "【なし】防具なし"
	no_armor_btn.pressed.connect(func(): _equip_armor(""))
	armor_list.add_child(no_armor_btn)

	# Crafted items from warehouse
	for entry in PlayerProfile.warehouse:
		var recipe_id: String = entry.get("recipe_id", "")
		if recipe_id not in GameData.recipes:
			continue
		var recipe: Dictionary = GameData.recipes[recipe_id]
		var qty: int = int(entry.get("qty", 1))
		var btn := Button.new()
		btn.text = "%s × %d" % [recipe["name"], qty]
		var captured_id: String = recipe_id
		var category: String = recipe["category"]
		if category == "weapon":
			btn.pressed.connect(func(): _equip_weapon(captured_id))
			weapon_list.add_child(btn)
		elif category == "armor":
			btn.pressed.connect(func(): _equip_armor(captured_id))
			armor_list.add_child(btn)

	_update_equipped_label()


func _equip_weapon(recipe_id: String) -> void:
	PlayerProfile.equipped_weapon_recipe = recipe_id
	PlayerProfile.save_profile()
	_update_equipped_label()


func _equip_armor(recipe_id: String) -> void:
	PlayerProfile.equipped_armor_recipe = recipe_id
	PlayerProfile.save_profile()
	_update_equipped_label()


func _update_equipped_label() -> void:
	var w_name: String = "クラス標準"
	if PlayerProfile.equipped_weapon_recipe != "":
		w_name = GameData.recipes.get(PlayerProfile.equipped_weapon_recipe, {}).get("name", "?")
	var a_name: String = "なし"
	if PlayerProfile.equipped_armor_recipe != "":
		a_name = GameData.recipes.get(PlayerProfile.equipped_armor_recipe, {}).get("name", "?")
	equipped_label.text = "装備中: 武器[%s] 防具[%s]" % [w_name, a_name]
