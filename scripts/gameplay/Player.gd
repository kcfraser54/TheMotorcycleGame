extends CharacterBody2D

## Side-scrolling motorcycle player.
## - World scrolls right -> left, so the player feels constant leftward push.
## - Touch right half of screen: accelerate right (counter the push).
## - Touch top-left quarter: move up.  Touch bottom-left quarter: move down.
## - Player CAN slide off the left edge — that triggers `died`.
## - Vertical position is clamped to the road's drivable band.

signal died

# --- Horizontal motion --------------------------------------------------
@export var leftward_push: float = 500.0    # constant pull toward the left edge (px/s)
@export var rightward_accel: float = 2200.0 # acceleration when "accelerate" held
@export var max_x_speed: float = 1000.0     # cap on horizontal speed in either direction
@export var horizontal_drag: float = 1200.0 # how quickly motion settles when no input

# --- Vertical motion ----------------------------------------------------
@export var vertical_speed: float = 520.0   # constant up/down speed when held

# --- Bounds (matches the road defined in background.tscn) ---------------
@export var road_top_y: float = 80.0
@export var road_bottom_y: float = 300.0
@export var screen_x_padding: float = 30.0  # keep player this far from RIGHT edge

# --- Death ---------------------------------------------------------------
## How far past the left edge (in pixels) the player must go to die.
## Lets the bike visibly slide off-screen before we trigger game over.
@export var death_offscreen_buffer: float = 120.0

# --- Touch zone tracking (multitouch) -----------------------------------
enum Zone { NONE, ACCEL, UP, DOWN }
var _finger_zones: Dictionary = {}   # finger_index -> Zone

# --- Cached screen geometry --------------------------------------------
var _screen_size: Vector2
var _screen_left: float
var _screen_right: float

var _alive: bool = true


func _ready() -> void:
	_screen_size = get_viewport_rect().size
	_screen_left = -_screen_size.x * 0.5
	_screen_right = _screen_size.x * 0.5


func _physics_process(delta: float) -> void:
	if not _alive:
		# Keep coasting offscreen with the leftward drift; no input.
		velocity.x = -leftward_push
		velocity.y = 0.0
		move_and_slide()
		return

	# --- Horizontal: leftward push always applied; right input fights it.
	var accel_input: bool = Input.is_action_pressed("accelerate") or _any_finger_in(Zone.ACCEL)
	if accel_input:
		velocity.x += rightward_accel * delta
	else:
		velocity.x -= leftward_push * delta
		if velocity.x < -leftward_push:
			velocity.x = move_toward(velocity.x, -leftward_push, horizontal_drag * delta)
	velocity.x = clamp(velocity.x, -max_x_speed, max_x_speed)

	# --- Vertical: discrete up/down via touch zones or W/S.
	var up_input: bool = Input.is_action_pressed("move_up") or _any_finger_in(Zone.UP)
	var down_input: bool = Input.is_action_pressed("move_down") or _any_finger_in(Zone.DOWN)
	if up_input and not down_input:
		velocity.y = -vertical_speed
	elif down_input and not up_input:
		velocity.y = vertical_speed
	else:
		velocity.y = 0.0

	move_and_slide()

	# --- Clamp: vertical to road, right side to screen, LEFT is open (death).
	position.x = min(position.x, _screen_right - screen_x_padding)
	position.y = clamp(position.y, road_top_y, road_bottom_y)

	# --- Death check: bike fully past the left edge.
	if position.x < _screen_left - death_offscreen_buffer:
		_alive = false
		_finger_zones.clear()
		died.emit()


# --- Touch input handling -----------------------------------------------
func _input(event: InputEvent) -> void:
	if not _alive:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_finger_zones[event.index] = _zone_for_position(event.position)
		else:
			_finger_zones.erase(event.index)
	elif event is InputEventScreenDrag:
		_finger_zones[event.index] = _zone_for_position(event.position)


func _zone_for_position(pos: Vector2) -> int:
	var w: float = _screen_size.x
	var h: float = _screen_size.y
	if pos.x >= w * 0.5:
		return Zone.ACCEL
	if pos.y < h * 0.5:
		return Zone.UP
	return Zone.DOWN


func _any_finger_in(zone: int) -> bool:
	for z in _finger_zones.values():
		if z == zone:
			return true
	return false
