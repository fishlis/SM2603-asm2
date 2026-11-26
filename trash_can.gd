extends Control
## Trash bin: drag a messed-up coffee cup in here to start over.
##
## Note: the drag and drop callbacks (_can_drop_data / _drop_data) only work
## on Control nodes, so this script must be attached to a Control
## (it cannot be attached to a Sprite2D).
## The trash bin image lives in the child node "TrashCan" (TextureRect).
##
## Highlight rule: the bin only changes colour while a coffee cup is being
## dragged and hovering over it. Dragging anything else (an ingredient
## card, for example) over the bin will not change its colour.

@export var highlight_color: Color = Color(1.0, 0.85, 0.35, 0.55)

@onready var trash_icon: TextureRect = get_node_or_null("TrashCan") as TextureRect

var _hovering: bool = false
var _base_scale: Vector2 = Vector2.ONE
var _base_modulate: Color = Color(1, 1, 1, 1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	if trash_icon != null:
		_base_scale = trash_icon.scale
		_base_modulate = trash_icon.modulate
	_update_visual(false)


func _process(_delta: float) -> void:
	_update_visual(_is_cup_hovering())


# Checks whether a cup is currently being dragged and the cursor is over the bin
func _is_cup_hovering() -> bool:
	var viewport := get_viewport()
	if viewport == null or not viewport.gui_is_dragging():
		return false

	var data = viewport.gui_get_drag_data()
	var drag_type: String = ""
	if typeof(data) == TYPE_DICTIONARY:
		drag_type = str(data.get("type", ""))

	return should_highlight(drag_type, viewport.get_mouse_position())


# Pure logic: given a drag type and a mouse position, decide whether to highlight
func should_highlight(drag_type: String, mouse_pos: Vector2) -> bool:
	if drag_type != "cup":
		return false
	return get_global_rect().has_point(mouse_pos)


# Only accepts drag data of the "cup" type
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and str(data.get("type", "")) == "cup"


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var cup = data.get("cup", null)
	if cup != null and cup.has_method("reset_cup"):
		cup.reset_cup()
		_play_feedback()


func _update_visual(hover: bool) -> void:
	if _hovering == hover:
		return
	_hovering = hover
	if trash_icon == null:
		return

	var target: Color = highlight_color if hover else _base_modulate
	var tw := create_tween()
	tw.tween_property(trash_icon, "modulate", target, 0.12)


func _play_feedback() -> void:
	if trash_icon == null:
		return
	var target_scale: Vector2 = _base_scale * 1.15
	var tw := create_tween()
	tw.tween_property(trash_icon, "scale", target_scale, 0.06)
	tw.tween_property(trash_icon, "scale", _base_scale, 0.10)
