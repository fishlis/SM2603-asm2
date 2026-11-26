extends Node2D
@export var zombie_scene: PackedScene
@export var zombie_speed: float = 20.0
var score

# Zombies are drawn inside this z_index band so they always stay behind the
# background art and the UI, no matter how many of them are alive.
const ZOMBIE_Z_MIN := -50
const ZOMBIE_Z_MAX := -20

# The zombies in the order they spawned. The newest zombie is drawn in front.
var _zombie_order: Array = []

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
	# add_child appends the zombie as the LAST child. Godot picks overlapping
	# drag and drop targets by tree order (the last child wins) while it draws
	# them by z_index, so the newest zombie is both the last child and the one
	# drawn in front. That keeps the order bubble the player can see as the
	# one that actually receives the coffee.
	add_child(zombie)
	_zombie_order.append(zombie)
	_refresh_zombie_z_order()


# Removes the zombies that were freed and re-applies the z_index band.
func _refresh_zombie_z_order() -> void:
	var alive: Array = []
	for z in _zombie_order:
		if is_instance_valid(z):
			alive.append(z)
	_zombie_order = alive

	var count := _zombie_order.size()
	if count == 0:
		return

	# The oldest zombie gets the lowest z_index, the newest the highest one,
	# so the newest zombie is always drawn in front of the queue.
	for i in range(count):
		var z = _zombie_order[i]
		if count == 1:
			z.z_index = ZOMBIE_Z_MIN
		else:
			var t := float(i) / float(count - 1)
			z.z_index = int(round(lerp(float(ZOMBIE_Z_MIN), float(ZOMBIE_Z_MAX), t)))
