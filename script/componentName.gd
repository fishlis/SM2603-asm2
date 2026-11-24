extends Control

var code: String = ""
var ingredient_name: String = ""

@onready var label: Label = $Label

func setup_component(p_code: String, p_name: String) -> void:
	code = p_code
	ingredient_name = p_name
	if label:
		label.text = "%s - %s" % [code, ingredient_name]
