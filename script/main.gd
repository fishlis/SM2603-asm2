extends Node2D
@export var zombie_scene: PackedScene
@export var zombie_speed: float = 20.0
@export var zombie_spacing: float = 110
@export var bubble_stagger_y: float = 8
@export var max_zombies: int =3
@export var slot_spacing_x: float = 150
@export var stop_x: float = 300
@export var stop_y_offset: float = 160

var score: int = 0
## True once the round is over. While this is set the game is paused.
var _game_over: bool = false

# Zombies are drawn inside this z_index band so they always stay behind the
# background art and the UI, no matter how many of them are alive.
const ZOMBIE_Z_MIN := -50
const ZOMBIE_Z_MAX := -20

# The zombies in the order they spawned. The newest zombie is drawn in front.
var _zombie_order: Array = []
var _bubble_base_y: float = -120

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_on_zombie_timer_timeout()

	# The countdown timer ends the round when it runs out.
	var countdown: Node = get_node_or_null("CountdownTimer")
	if countdown != null:
		countdown.game_over.connect(_on_game_over)
		countdown.restart_requested.connect(_on_restart_requested)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var alive: Array = []
	for z in _zombie_order:
		if is_instance_valid(z) and not z.is_queued_for_deletion():
			alive.append(z)
	_zombie_order = alive
	
	var target_y = $ZombieSpawnPoint.position.y + stop_y_offset
	
	for i in range(_zombie_order.size()):
		var z = _zombie_order[i]

		if z.is_leaving:
			z.position = z.position.move_toward($ZombieSpawnPoint.position, zombie_speed * delta)

			if z.position.distance_to($ZombieSpawnPoint.position) < 5:
				z.queue_free()

			continue

		var target_x = stop_x + i * slot_spacing_x
		var target_pos = Vector2(target_x, target_y)

		if z is RigidBody2D and z.position.x <= target_x:
			z.linear_velocity = Vector2.ZERO

		z.position = z.position.move_toward(target_pos, zombie_speed * delta)

		


func _on_drawing_pad_ingredient_added(category: String, item_name: String, item_color: Color, item_icon: Texture2D) -> void:
	var grid = $Inventory/CanvasLayer/Inventory/Category_grid
	if grid and grid.has_method("update_category_slot"):
		grid.update_category_slot(category, item_name, item_color, item_icon)


func _on_zombie_timer_timeout() -> void:
	if _zombie_order.size() >= max_zombies:
		return
	# Create a new instance of the Mob scene.
	var zombie = zombie_scene.instantiate()

	# Choose a random location on Path2D.
	var zombie_spawn_location = $ZombieSpawnPoint
	# Set the mob's position to the random location.
	zombie.position = zombie_spawn_location.position
	
	
	
	# Set the mob's direction perpendicular to the path direction.
	var direction = zombie_spawn_location.rotation

	# Add some randomness to the direction.
	direction += randf_range(-PI / 32, PI / 32)
	
	if zombie is RigidBody2D:
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
	zombie.tree_exited.connect(_refresh_zombie_z_order)
	if zombie.has_signal("order_completed"):
		zombie.order_completed.connect(_on_order_completed)
	_zombie_order.append(zombie)
	_refresh_zombie_z_order()


# Removes the zombies that were freed and re-applies the z_index band.
func _refresh_zombie_z_order() -> void:
	var alive: Array = []
	for z in _zombie_order:
		if is_instance_valid(z) and not z.is_queued_for_deletion():
			alive.append(z)
	_zombie_order = alive

	var count := _zombie_order.size()
	# The oldest zombie gets the lowest z_index, the newest the highest one,
	# so the newest zombie is always drawn in front of the queue.
	if count ==0:
		return
		
	for i in range(count):
		var z = _zombie_order[i]
		
		var t := 1-(float(i) / float(max(count - 1,1)))
		z.z_index = int(round(lerp(float(ZOMBIE_Z_MIN), float(ZOMBIE_Z_MAX), t)))
			
		var overlay = z.get_node_or_null("OrderOverlay") as Node2D
		if overlay != null:
			var offset_index = (count-1) - i
			overlay.position.x = 0.0
			#overlay.position.y = _bubble_base_y - offset_index * bubble_stagger_y


## Called when a zombie received a correct order. The score goes up by one.
func _on_order_completed() -> void:
	score += 1


## Called when the countdown timer reaches 00:00. The round is over, so the
## game is paused and the game over panel is shown.
func _on_game_over() -> void:
	if _game_over:
		return
	_game_over = true
	get_tree().paused = true

	var countdown: Node = get_node_or_null("CountdownTimer")
	if countdown != null:
		countdown.show_game_over("Orders completed: %d" % score)

	# The zombies stop moving while the game is paused.
	for z in _zombie_order:
		if is_instance_valid(z) and z is RigidBody2D:
			z.linear_velocity = Vector2.ZERO
			z.freeze = true


## Called when the player presses the restart button on the game over panel.
## The current scene is reloaded so a fresh round starts with a full clock.
func _on_restart_requested() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
