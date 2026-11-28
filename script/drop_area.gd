extends Control
## Drop target placed on the zombie's order bubble.
##
## Zombies queue up and their order bubbles overlap. Godot picks the drop
## target by TREE ORDER (the last sibling wins), while the zombies are drawn
## by z_index, so the engine would normally hand the cup to the zombie drawn
## BEHIND the others.
##
## To keep both in sync, every bubble checks whether a bubble that is drawn
## in front of it covers the cursor. If one does, this bubble refuses the
## drop and dims itself, so only the order bubble that is truly in front can
## receive the coffee.

const DROP_AREA_GROUP := "order_drop_area"

@export var highlight_color: Color = Color(1.0, 0.85, 0.35, 0.6)
@export var dimmed_color: Color = Color(0.55, 0.55, 0.55, 0.8)

@onready var order_overlay: Node2D = get_parent() as Node2D
@onready var speech_bubble: TextureRect = order_overlay.get_node_or_null("SpeechBubble") as TextureRect
@onready var order_icon: TextureRect = order_overlay.get_node_or_null("OrderIcon") as TextureRect

var _hovering: bool = false
var _coverage: float = 0.0
var _base_bubble_modulate: Color = Color(1, 1, 1, 1)
var _base_icon_modulate: Color = Color(1, 1, 1, 1)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group(DROP_AREA_GROUP)
	if speech_bubble != null:
		_base_bubble_modulate = speech_bubble.modulate
	if order_icon != null:
		_base_icon_modulate = order_icon.modulate


func _process(_delta: float) -> void:
	var hovering := _is_cup_hovering()
	var coverage := _covered_ratio()
	if hovering != _hovering or not is_equal_approx(coverage, _coverage):
		_hovering = hovering
		_coverage = coverage
		_apply_appearance()


# Walks up the tree to find the zombie that owns this order bubble
func find_zombie() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.has_method("check_cup"):
			return node
		node = node.get_parent()
	return null


# The drawing order of this bubble inside the canvas layer.
# A higher value means the bubble is drawn further in front.
func get_effective_z() -> int:
	var total := 0
	var node: Node = self
	while node is CanvasItem:
		total += (node as CanvasItem).z_index
		var parent := node.get_parent()
		if parent is CanvasLayer:
			break
		node = parent
	return total


# Checks whether a cup is currently being dragged over this bubble
func _is_cup_hovering() -> bool:
	var viewport := get_viewport()
	if viewport == null or not viewport.gui_is_dragging():
		return false

	var data = viewport.gui_get_drag_data()
	var drag_type: String = ""
	if typeof(data) == TYPE_DICTIONARY:
		drag_type = str(data.get("type", ""))
	if drag_type != "cup":
		return false

	var mouse_pos := viewport.get_mouse_position()
	return get_global_rect().has_point(mouse_pos) and _is_frontmost_at(mouse_pos)


# Pure logic: given a drag type and a mouse position, decide whether to highlight
func should_highlight(drag_type: String, mouse_pos: Vector2) -> bool:
	if drag_type != "cup":
		return false
	if not get_global_rect().has_point(mouse_pos):
		return false
	return _is_frontmost_at(mouse_pos)


# True when no order bubble drawn in front of this one covers the given point
func _is_frontmost_at(mouse_pos: Vector2) -> bool:
	var my_z := get_effective_z()
	for node in get_tree().get_nodes_in_group(DROP_AREA_GROUP):
		var area := node as Control
		if area == null or area == self:
			continue
		if area.get_effective_z() <= my_z:
			continue
		if area.get_global_rect().has_point(mouse_pos):
			return false
	return true


# How much of this bubble is covered by a bubble that is drawn in front of it
func _covered_ratio() -> float:
	var my_rect := get_global_rect()
	var my_area := my_rect.size.x * my_rect.size.y
	if my_area <= 0.0:
		return 0.0

	var my_z := get_effective_z()
	var worst := 0.0
	for node in get_tree().get_nodes_in_group(DROP_AREA_GROUP):
		var area := node as Control
		if area == null or area == self:
			continue
		if area.get_effective_z() <= my_z:
			continue
		var inter := my_rect.intersection(area.get_global_rect())
		if inter.size.x <= 0.0 or inter.size.y <= 0.0:
			continue
		worst = maxf(worst, (inter.size.x * inter.size.y) / my_area)
	return clampf(worst, 0.0, 1.0)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY or str(data.get("type", "")) != "cup":
		return false
	# Refuse when a bubble in front of this one is under the cursor.
	# Godot does not fall through to the control underneath, so refusing here
	# is what keeps the order in front.
	var ok = _is_frontmost_at(get_global_mouse_position())
	return ok


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var zombie := find_zombie()
	if zombie == null:
		return

	var items: Array = data.get("ingredients", [])
	var dropped_cup_type: String = str(data.get("cup_type", "cup")).strip_edges().to_lower()

	if zombie.has_method("check_cup"):
		var matched: bool = zombie.check_cup(items, dropped_cup_type)
		if matched:
			var cup = data.get("cup")
			if cup and cup.has_method("reset_cup"):
				cup.reset_cup()
			_play_success_feedback()


func _apply_appearance() -> void:
	var bubble_target := _base_bubble_modulate
	var icon_target := _base_icon_modulate

	# Dim this bubble when an order bubble in front of it is covering it
	if _coverage > 0.0:
		var dim_amount := clampf(_coverage * 1.5, 0.0, 1.0)
		bubble_target = _base_bubble_modulate.lerp(dimmed_color, dim_amount)
		icon_target = _base_icon_modulate.lerp(dimmed_color, dim_amount)

	# Highlight only when this bubble is the one that would actually receive the drop
	if _hovering:
		bubble_target = highlight_color
		icon_target = highlight_color

	if speech_bubble != null:
		var tw := create_tween()
		tw.tween_property(speech_bubble, "modulate", bubble_target, 0.12)
	if order_icon != null:
		var tw2 := create_tween()
		tw2.tween_property(order_icon, "modulate", icon_target, 0.12)


func _play_success_feedback() -> void:
	if order_icon == null:
		return
	var base_scale: Vector2 = order_icon.scale
	var tw := create_tween()
	tw.tween_property(order_icon, "scale", base_scale * 1.25, 0.08)
	tw.tween_property(order_icon, "scale", base_scale, 0.12)
