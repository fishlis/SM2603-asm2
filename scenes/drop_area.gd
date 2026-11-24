extends Control

@onready var zombie = get_parent()

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "cup"
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var items: Array = data.get("ingredients", [])
	if zombie and zombie.has_method("check_cup"):
		var matched: bool = zombie.check_cup(items)
		if matched:
			var cup = data.get("cup")
			if cup and cup.has_method("reset_cup"):
				cup.reset_cup()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
