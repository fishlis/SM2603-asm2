extends Panel
@onready var icon: TextureRect = $Icon

func _get_drag_data(at_position: Vector2) -> Variant:
	if icon.texture == null:
		return
	var preview = duplicate()
	set_drag_preview(preview)
	return icon

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return true
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var tmp = icon.texture
	icon.texture = data.texture
	data.texture = tmp
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
