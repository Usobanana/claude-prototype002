extends Control
# Warehouse UI — shows all crafted items stored in PlayerProfile.warehouse.

@onready var item_list: VBoxContainer = $Panel/VBox/ItemList
@onready var close_button: Button = $Panel/VBox/CloseButton
@onready var empty_label: Label = $Panel/VBox/EmptyLabel

func _ready() -> void:
	close_button.pressed.connect(func(): visible = false)
	visible = false


func open() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	for child in item_list.get_children():
		child.queue_free()

	if PlayerProfile.warehouse.is_empty():
		empty_label.visible = true
		return
	empty_label.visible = false

	for entry in PlayerProfile.warehouse:
		var recipe_id: String = entry.get("recipe_id", "")
		var qty: int = int(entry.get("qty", 1))
		if recipe_id not in GameData.recipes:
			continue
		var recipe: Dictionary = GameData.recipes[recipe_id]
		var lbl := Label.new()
		lbl.text = "%s × %d" % [recipe["name"], qty]
		item_list.add_child(lbl)
