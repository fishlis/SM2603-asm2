extends RigidBody2D


@export var zombie_speed: float = 200.0


@onready var patience_bar = $PatienceBar
@onready var order_overlay = $OrderOverlay

#ORDER Variables
@export var wait_time: float = 15.0
var remaining_time: float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var zombie_types = Array($AnimatedSprite2D.sprite_frames.get_animation_names())
	$AnimatedSprite2D.animation = zombie_types.pick_random()
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

func check_cup(items: Array) -> bool:
	if order_overlay == null:
		return false
		
	var order_id: String = str(order_overlay.current_order_id)
	
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
		print("not match", items)
		return false
	
func drinkOrder() -> void:
	print("Order complted!")
	queue_free()

func order_failed() -> void:
	queue_free()
	print("Failed Order!")
	
	
