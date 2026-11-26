extends Panel

@export var cup_type: String = "cup"
@export var empty_text: String = "Empty Cup"

@onready var cup_icon: TextureRect = _get_first_child(["CupIcon", "TextureRect"], "TextureRect") as TextureRect
@onready var cup_label: Label = _get_first_child(["CupLabel", "TogoLabel"], "Label") as Label

var slots_by_category := {
	"coffee": "",
	"water": "",
	"syrup": "",
	"ice": "",
}

func _ready() -> void:
	update_cup_text()

func _get_first_child(names: Array, class_hint: String) -> Node:
	for n in names:
		var c := get_node_or_null(n)
		if c != null:
			return c
	for c in get_children():
		if c.is_class(class_hint):
			return c
	return null

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "ingredient"

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var item_name: String = str(data.get("name", ""))
	var cat: String = str(data.get("category", ""))

	if item_name == "":
		return

	if cat in slots_by_category:
		slots_by_category[cat] = item_name
	else:
		if "Water" in item_name or "Milk" in item_name:
			slots_by_category["water"] = item_name
		elif "Syrup" in item_name or "Chocolate" in item_name:
			slots_by_category["syrup"] = item_name
		elif "Ice" in item_name:
			slots_by_category["ice"] = item_name
		else:
			slots_by_category["coffee"] = item_name

	update_cup_text()

func _get_drag_data(_at_position: Vector2) -> Variant:
	var items := get_ingredients_list()
	if items.is_empty():
		return null

	var preview := duplicate()
	
	preview.set("slots_by_category", slots_by_category.duplicate(true))
	set_drag_preview(preview)

	return {
		"type": "cup",
		"cup": self,
		"cup_type": cup_type.strip_edges().to_lower(),
		"ingredients": items,
	}

func reset_cup() -> void:
	for key in slots_by_category:
		slots_by_category[key] = ""
	update_cup_text()

func get_ingredients_list() -> Array[String]:
	var result: Array[String] = []
	for key in slots_by_category:
		if slots_by_category[key] != "":
			result.append(slots_by_category[key])
	return result

func update_cup_text() -> void:
	if cup_label == null:
		return
	var items := get_ingredients_list()
	if items.is_empty():
		cup_label.text = empty_text
	else:
		cup_label.text = "\n".join(items)
