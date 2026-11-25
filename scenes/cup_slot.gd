extends Panel

@export var cup_type: String = "cup"

@onready var cup_icon: TextureRect = $CupIcon
@onready var cup_label: Label = $CupLabel

var slots_by_category ={
	"coffee": "",
	"water": "",
	"syrup": "",
	"ice": ""
}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	update_cup_text()

func _drop_data(at_position: Vector2, data: Variant) -> void:
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
	
func _get_drag_data(at_position: Vector2) -> Variant:
	var items = get_ingredients_list()
	if items.is_empty():
		return null
	var preview = duplicate()
	set_drag_preview(preview)
	return{
		"type": "cup",
		"cup": self,
		"cup_type": cup_type.strip_edges().to_lower(),
		"ingredients": items
	}

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "ingredient"
	
func reset_cup()->void:
	for key in slots_by_category:
		slots_by_category[key] = ""
	update_cup_text()
	
func get_ingredients_list()-> Array[String]:
	var result: Array[String] = []
	for key in slots_by_category:
		if slots_by_category[key] != "":
			result.append(slots_by_category[key])
	return result

func update_cup_text() -> void:
	if cup_label == null:
		return
	var items = get_ingredients_list()
	if items.is_empty():
		cup_label.text = "Empty Cup"
	else:
		cup_label.text = "\n".join(items)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
