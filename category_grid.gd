extends GridContainer

@onready var category_slots = {
	"coffee": $ItemSlot,
	"water": $ItemSlot2,
	"syrup": $ItemSlot3,
	"ice": $ItemSlot4,
}

func update_category_slot(category: String, item_name: String, item_color: Color, item_icon: Texture2D)-> void:
	var slot = category_slots.get(category, null)
	if slot and slot.has_method("set_slot_data"):
		slot.set_slot_data(item_icon, item_color, item_name)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
