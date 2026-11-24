extends RigidBody2D


@export var zombie_speed: float = 200.0


@onready var patience_bar = $PatienceBar

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


func drinkOrder() -> void:
	pass

func order_failed() -> void:
	queue_free()
	print("Failed Order!")
	
	
