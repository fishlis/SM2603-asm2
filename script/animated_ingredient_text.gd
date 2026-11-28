extends Control
class_name AnimatedIngredientText
## Animated ingredient text that pops up above a cup when an ingredient is
## successfully dropped into it.
##
## The animations are sequences of transparent PNG frames that were extracted
## from the original .MOV files. Godot cannot import QuickTime movies, so the
## frames are stored as individual PNGs and played back with AnimatedSprite2D.

@export var sprite_frames: SpriteFrames
## The area covered by the visible pixels inside the frame textures.
## The frames are much larger than the text itself, so this is needed to place
## the text right against the cup instead of floating above it.
@export var ink_rect: Rect2 = Rect2(1.0, 24.0, 637.0, 160.0)
## How long the text stays visible after the animation finished, in seconds.
@export var hold_time: float = 0.4
## The width the animation is scaled to on screen, in pixels of the parent
## space (the space this control lives in).
@export var target_width: float = 220.0
## The gap between the bottom of the text and the top of the cup, in pixels of
## the parent space.
@export var cup_gap: float = 2.0
## The animations that can be played, keyed by ingredient name.
## Every entry is a dictionary with these optional keys:
##   "frames"       -> SpriteFrames, the animation to play
##   "ink_rect"     -> Rect2, the visible area inside the frame textures
##   "target_width" -> float, the on screen width of the animation
@export var ingredient_animations: Dictionary = {}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _hold_timer: float = 0.0
var _is_playing: bool = false
## When greater than zero this overrides target_width.
var _width_override: float = -1.0
## The scale that was applied to the sprite during the last update.
var _applied_scale: float = 1.0
## The size of the source texture of the frames.
var _tex_size: Vector2 = Vector2.ZERO
## The cup icon this text is aligned against, kept so the text can be aligned
## again after the animation changed.
var _cup_icon: Control = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if sprite_frames != null:
		sprite.sprite_frames = sprite_frames
	sprite.stop()
	_tex_size = _get_texture_size()
	_apply_scale()
	resized.connect(_apply_scale)


## Overrides the display width of the animation, in pixels of the parent space.
## Pass a negative value to go back to using target_width.
func set_target_width(width: float) -> void:
	_width_override = width
	_apply_scale()


## The size the animation is actually drawn at, in the parent space.
func get_drawn_size() -> Vector2:
	if _tex_size == Vector2.ZERO:
		return Vector2.ZERO
	return _tex_size * _applied_scale


## Returns the size of the source texture of the animation frames.
func _get_texture_size() -> Vector2:
	var tex := _get_frame_texture()
	if tex == null:
		return Vector2.ZERO
	return Vector2(tex.get_width(), tex.get_height())


## Returns the first frame of the animation, or null when there is none.
func _get_frame_texture() -> Texture2D:
	if sprite == null or sprite.sprite_frames == null:
		return null
	if sprite.sprite_frames.get_frame_count("default") == 0:
		return null
	return sprite.sprite_frames.get_frame_texture("default", 0)


## Plays the animation that belongs to the given ingredient name.
## Returns true when an animation was found and started.
func play_for(ingredient_name: String) -> bool:
	var data: Dictionary = ingredient_animations.get(ingredient_name, {})
	var frames: SpriteFrames = data.get("frames", null) as SpriteFrames
	if frames == null:
		frames = sprite_frames
	if frames == null:
		return false

	# Swap in the frames of the requested ingredient.
	sprite.sprite_frames = frames
	sprite.stop()
	_tex_size = _get_texture_size()

	# Each ingredient has its own visible area and size, so take them over too.
	if data.has("ink_rect"):
		ink_rect = data["ink_rect"]
	if data.has("target_width"):
		target_width = float(data["target_width"])
	_width_override = -1.0

	_apply_scale()
	_align_to_cup()
	play()
	return true


## Places the animation directly above the given cup icon, centered on it and
## sitting right on top of the rim.
## The icon can be scaled, so its drawn rect is computed from its scale.
func align_above(icon: Control) -> void:
	_cup_icon = icon
	_align_to_cup()


## Recomputes the position of the text against the cup icon.
func _align_to_cup() -> void:
	var icon := _cup_icon
	if icon == null:
		return
	var icon_scale := icon.scale
	var icon_rect := icon.get_rect()
	# Control.get_rect() does not include the node scale, so multiply the size
	# by the scale to get the size the icon is really drawn at.
	var drawn_size := icon_rect.size * icon_scale
	# The scale happens around the pivot offset, so the top left corner of the
	# drawn icon is shifted by the pivot when the scale is not 1.
	var pivot := icon.pivot_offset
	var top_left := icon_rect.position + pivot * (Vector2.ONE - icon_scale)

	var text_size := get_drawn_size()
	if text_size.x <= 0.0 or text_size.y <= 0.0:
		return

	# The sprite is drawn centered on the control, so work out where the
	# visible pixels of the animation sit relative to that center.
	var ink_cx := 0.0
	var ink_bottom := 0.0
	if ink_rect.size != Vector2.ZERO and _tex_size != Vector2.ZERO:
		ink_cx = (ink_rect.position.x + ink_rect.size.x * 0.5) - _tex_size.x * 0.5
		ink_bottom = (ink_rect.position.y + ink_rect.size.y) - _tex_size.y * 0.5

	# Center the text horizontally on the cup and push it down so the visible
	# pixels rest right on top of the rim.
	position = Vector2(
		top_left.x + drawn_size.x * 0.5 - text_size.x * 0.5 - ink_cx * _applied_scale,
		top_left.y - cup_gap - text_size.y * 0.5 - ink_bottom * _applied_scale
	)
	# The control must be exactly as big as the drawn animation, otherwise
	# custom_minimum_size would resize it and shift the text out of place.
	custom_minimum_size = Vector2.ZERO
	size = text_size
	# Re-center the sprite inside the control after the size changed.
	_apply_scale()


## Scales the animation so it always has the same width on screen and keeps the
## sprite centered inside this control.
func _apply_scale() -> void:
	if sprite == null:
		return
	var tex := _get_frame_texture()
	if tex == null or tex.get_width() <= 0:
		return
	var width: float = _width_override if _width_override > 0.0 else target_width
	_applied_scale = width / float(tex.get_width())
	sprite.scale = Vector2(_applied_scale, _applied_scale)
	# The sprite is drawn centered on its own origin, so put that origin on the
	# center of the control to keep the text inside the control bounds.
	sprite.position = size * 0.5


## Plays the animation once. Call this when an ingredient is added to the cup.
func play() -> void:
	if sprite.sprite_frames == null or sprite.sprite_frames.get_frame_count("default") == 0:
		return

	visible = true
	_is_playing = true
	_hold_timer = 0.0

	_apply_scale()
	sprite.play("default")


func _process(delta: float) -> void:
	if not _is_playing:
		return

	# Wait until the animation has finished, then keep it visible for a moment
	if not sprite.is_playing():
		_hold_timer += delta
		if _hold_timer >= hold_time:
			_is_playing = false
			visible = false
			sprite.stop()
			sprite.frame = 0
