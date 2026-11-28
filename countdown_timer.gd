extends CanvasLayer
class_name CountdownTimer

## Counts down the time left in the round and ends the game when it runs out.
##
## The remaining time is shown as MM:SS, starting at 03:00 and counting down
## to 00:00. The countdown is driven by the frame time, so the clock never
## drifts and the round ends exactly when the time is up. When the timer
## reaches zero the [signal game_over] signal is emitted so the main scene can
## stop the game.
##
## The root node is a CanvasLayer so the clock stays on top of the game no
## matter what is drawn in the world.

## How long the round lasts, in seconds.
@export var duration: float = 180.0

## Emitted the moment the countdown reaches 00:00.
signal game_over

## Emitted when the player presses the restart button on the game over panel.
signal restart_requested

@onready var label: Label = $TimerDisplay/Label
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var game_over_panel: Control = $GameOverLayer/GameOverPanel
@onready var score_label: Label = $GameOverLayer/GameOverPanel/VBox/Score
@onready var timer: Timer = $Timer

## The number of seconds that are still left on the clock.
var _remaining: float = 0.0
## True once the countdown has run out.
var _finished: bool = false


func _ready() -> void:
	timer.wait_time = 1.0
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	$GameOverLayer/GameOverPanel/VBox/RestartButton.pressed.connect(_on_restart_pressed)
	reset()


## Restarts the countdown from the full duration.
func reset() -> void:
	_remaining = duration
	_finished = false
	_update_label()
	hide_game_over()
	timer.start()


## Stops the countdown without ending the game.
func stop() -> void:
	timer.stop()


## The number of seconds that are still left on the clock.
func get_remaining() -> float:
	return _remaining


## Shows the game over panel.
func show_game_over(score_text: String = "") -> void:
	# The panel keeps running while the game is paused so the restart button
	# can still be pressed.
	game_over_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	if score_label != null:
		score_label.text = score_text
	if game_over_panel != null:
		game_over_panel.visible = true


## Hides the game over panel.
func hide_game_over() -> void:
	if game_over_panel != null:
		game_over_panel.visible = false


## Counts the clock down every frame so the round ends exactly on time.
func _process(delta: float) -> void:
	if _finished:
		return

	_remaining = maxf(0.0, _remaining - delta)
	_update_label()

	if _remaining <= 0.0:
		_finished = true
		timer.stop()
		game_over.emit()


## Called once per second by the Timer node. The clock itself is driven by
## _process, so this only makes sure the label is refreshed.
func _on_timer_timeout() -> void:
	if _finished:
		return
	_update_label()


## Called when the player presses the restart button.
func _on_restart_pressed() -> void:
	restart_requested.emit()


## Writes the remaining time onto the label as MM:SS.
func _update_label() -> void:
	if label == null:
		return
	# Round up so the clock shows 03:00 for the whole first second and only
	# drops to 02:59 once a full second has passed.
	var total := int(ceil(_remaining))
	label.text = "%02d:%02d" % [total / 60, total % 60]
