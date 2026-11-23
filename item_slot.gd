extends Panel

@onready var icon: TextureRect = $Icon
@onready var label: Label = $Label

func set_slot_data(new_texture: Texture2D, new_color: Color, new_text: String)-> void:
	if icon:
		icon.texture = new_texture
		icon.modulate = new_color
	if label:
		label.text = new_text
		label.modulate = new_color
func _get_drag_data(at_position: Vector2) -> Variant:
	if icon.texture == null and (label == null or label.text == ""):
		return null
	var preview = duplicate()
	set_drag_preview(preview)
	return self

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Panel and data.has_node("Icon")
	
func _drop_data(at_position: Vector2, data: Variant) -> void:
	var other_icon: TextureRect = data.get_nmode("Icon")
	var tmp_tex = icon.texture
	var tmp_mod = icon.modulate
	
	icon.texture = other_icon.texture
	icon.modulate = other_icon.modulate
	other_icon.texture = tmp_tex
	other_icon.modulate = tmp_mod
	
	if label and data.has_node("Label"):
		var other_label: Label = data.get_node("Label")
		var tmp_txt = label.text
		label.text = other_label.text
		other_label.text = tmp_txt
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
