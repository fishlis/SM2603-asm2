extends RigidBody2D


@export var zombie_speed: float = 200.0


@onready var patience_bar = $PatienceBar
@onready var order_overlay = $OrderOverlay

#ORDER Variables
@export var wait_time: float = 15.0
var remaining_time: float
var zombie_type := ""
var is_leaving = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var characters = ["boy1", "boy2", "girl1", "girl2"]
	
	zombie_type = characters.pick_random()

	$AnimatedSprite2D.animation = zombie_type + "_walk_in"
	$AnimatedSprite2D.play()

	remaining_time = wait_time
	patience_bar.max_value = 100.0
	patience_bar.value = 100.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	remaining_time-= delta
	patience_bar.value = (remaining_time / wait_time) * 100.0

	if remaining_time <= 0.0:
		order_failed()

func check_cup(items: Array, cup_type: String = "cup") -> bool:
	if order_overlay == null:
		return false
		
	var order_id: String = str(order_overlay.current_order_id)
	var required_cup_type: String = str(order_overlay.current_order_cup_type).strip_edges().to_lower()
	
	if required_cup_type == "":
		if order_id.ends_with("_togo"):
			required_cup_type = "togo"
			
		else:
			required_cup_type = "cup"
			
	if cup_type != required_cup_type:
		print("wrong cup type! got:", cup_type, "expected: ", required_cup_type)
		return false
	
	var has_coffee = "Coffee" in items
	var has_milk = "Milk" in items or "Oat Milk" in items
	var has_water = "Water" in items
	var has_choc = "Chocolate" in items
	var has_caramel = "Caramel Syrup" in items
	var has_vanilla = "Vanilla Syrup" in items
	var has_hazelnut = "Hazelnut Syrup" in items
	
	var is_ok = false
	if "mocha" in order_id:
		is_ok = has_coffee and has_choc
	elif "caramel_latte" in order_id:
		is_ok = has_coffee and has_milk and has_caramel
	elif "vanilla_latte" in order_id:
		is_ok = has_coffee and has_milk and has_vanilla
	elif "hazelnut_latte" in order_id:
		is_ok = has_coffee and has_milk and has_hazelnut
	elif "latte" in order_id:
		is_ok = has_coffee and has_milk
	elif "americano" in order_id:
		is_ok = has_coffee and has_water
	elif "espresso" in order_id:
		is_ok = has_coffee and not has_milk and not has_choc
	
	if is_ok:
		print("matched!")
		drinkOrder()
		return true
	else:
		print("not match", items, "cup_type:", cup_type)
		return false
	
func drinkOrder() -> void:
	print("Order completed!")
	zombieLeaving()

func order_failed() -> void:
	print("Failed Order!")
	zombieLeaving()
	
func zombieLeaving() -> void:
	is_leaving = true
	
	patience_bar.hide()
	order_overlay.hide()
	$AnimatedSprite2D.animation = zombie_type + "_walk_out"
	$AnimatedSprite2D.play()
