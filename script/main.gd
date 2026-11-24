extends Node2D
@export var zombie_scene: PackedScene
@export var zombie_speed: float = 20.0
var score

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_zombie_timer_timeout()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_drawing_pad_ingredient_added(category: String, item_name: String, item_color: Color, item_icon: Texture2D) -> void:
	var grid = $Inventory/CanvasLayer/Inventory/Category_grid
	if grid and grid.has_method("update_category_slot"):
		grid.update_category_slot(category, item_name, item_color, item_icon)
	


func _on_zombie_timer_timeout() -> void:
	# Create a new instance of the Mob scene.
	var zombie = zombie_scene.instantiate()

	# Choose a random location on Path2D.
	var zombie_spawn_location = $ZombieSpawnPoint
	# Set the mob's position to the random location.
	zombie.position = zombie_spawn_location.position

	# Set the mob's direction perpendicular to the path direction.
	var direction = zombie_spawn_location.rotation + PI / 2

	# Add some randomness to the direction.
	direction += randf_range(-PI / 4, PI / 4)

	# Choose the velocity for the mob.
	var velocity = Vector2(zombie_speed, 0.0)
	zombie.linear_velocity = velocity.rotated(direction)

	# Spawn the mob by adding it to the Main scene.
	add_child(zombie)
	zombie.z_index = -get_child_count()
