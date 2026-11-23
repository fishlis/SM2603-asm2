extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_drawing_pad_ingredient_added(category: String, item_name: String, item_color: Color, item_icon: Texture2D) -> void:
	var grid = $Inventory/CanvasLayer/Inventory/Category_grid
	if grid and grid.has_method("update_category_slot"):
		grid.update_category_slot(category, item_name, item_color, item_icon)
	
