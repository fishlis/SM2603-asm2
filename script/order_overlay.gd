extends Node2D

@onready var order_icon: TextureRect = $OrderIcon
var current_order_id: String
var current_order_cup_type: String
#id, cup_type for each order
var orders = [
	{ "id": "espresso_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/espresso_cup.png") },
	{ "id": "espresso_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/espresso_togo.png") },
	{ "id": "americano_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/americano_cup.png") },
	{ "id": "americano_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/americano_togo.png") },
	{ "id": "mocha_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/mocha_cup.png") },
	{ "id": "mocha_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/mocha_togo.png") },
	{ "id": "latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/latte_cup.png") },
	{ "id": "latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/latte_togo.png") },
	{ "id": "vanilla_latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/vanilla_latte_cup.png") },
	{ "id": "vanilla_latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/vanilla_latte_togo.png") },
	{ "id": "caramel_latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/caramel_latte_cup.png") },
	{ "id": "caramel_latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/caramel_latte_togo.png") },
	{ "id": "hazelnut_latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/hazelnut_latte_cup.png") },
	{ "id": "hazelnut_latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/hazelnut_latte_togo.png") },
	{ "id": "oatmilk_mocha_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/oatmilk_mocha_cup.png") },
	{ "id": "oatmilk_mocha_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/oatmilk_mocha_togo.png") },
	{ "id": "oatmilk_latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/oatmilk_latte_cup.png") },
	{ "id": "oatmilk_latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/oatmilk_latte_togo.png") },
	{ "id": "oatmilk_vanilla_latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/oatmilk_vanilla_latte_cup.png") },
	{ "id": "oatmilk_vanilla_latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/oatmilk_vanilla_latte_togo.png") },
	{ "id": "oatmilk_caramel_latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/oatmilk_caramel_latte_cup.png") },
	{ "id": "oatmilk_caramel_latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/oatmilk_caramel_latte_togo.png") },
	{ "id": "oatmilk_hazelnut_latte_cup", "cup_type": "cup", "texture": preload("res://assets/coffee_icons/orders/oatmilk_hazelnut_latte_cup.png") },
	{ "id": "oatmilk_hazelnut_latte_togo", "cup_type": "togo", "texture": preload("res://assets/coffee_icons/orders/oatmilk_hazelnut_latte_togo.png") }
]

func set_order(texture: Texture2D) -> void:
	order_icon.texture = texture

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var order = orders.pick_random()
	order_icon.texture = order.texture
	current_order_id = order.id
	current_order_cup_type = order.cup_type
	print("Order: " + current_order_id + " CupType: " + current_order_cup_type)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
