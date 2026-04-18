extends CharacterBody2D

## Side-scrolling motorcycle player.
## - World scrolls right -> left, so the player feels constant leftward push.
## - Touch right half of screen: accelerate right (counter the push).
## - Touch top-left quarter: move up.  Touch bottom-left quarter: move down.
## - Player CAN slide off the left edge — that triggers `died`.
## - Vertical position is clamped to the road's drivable band (from RoadConfig).

## Emitted once when the bike has slid past the left edge by `death_offscreen_buffer`.
signal died

## Shared road geometry — vertical clamp uses road_top_y / road_bottom_y.
@export var road_config: RoadConfig

# --- Horizontal motion --------------------------------------------------
@export var leftward_push: float = 500.0    ## constant pull toward the left edge (px/s)
@export var rightward_accel: float = 2200.0 ## acceleration when "accelerate" held
@export var max_x_speed: float = 1000.0     ## cap on horizontal speed in either direction
@export var horizontal_drag: float = 1200.0 ## how quickly motion settles when no input

# --- Vertical motion ----------------------------------------------------
@export var vertical_speed: float = 520.0   ## constant up/down speed when held

# --- Bounds -------------------------------------------------------------
## Distance from the RIGHT edge the bike can't pass (left side is open for death).
@export var screen_right_padding: float = 30.0

# --- Death --------------------------------------------------------------
## How far past the left edge (in pixels) the player must go to die.
## Lets the bike visibly slide off-screen before we trigger game over.
@export var death_offscreen_buffer: float = 120.0

# --- Touch zone tracking (multitouch) -----------------------------------
enum Zone { NONE, ACCEL, UP, DOWN }

# Maps each active finger -> the Zone it's currently in. Typed dict so
# the editor flags any wrong-type assignments.
var _finger_zones: Dictionary[int, int] = {}

# Reverse index: how many fingers are currently in each zone. Lets
# `_any_finger_in()` be O(1) instead of iterating every physics tick.
var _zone_counts: Dictionary[int, int] = {}

# --- Cached screen geometry --------------------------------------------
var _screen_size: Vector2
var _screen_left: float
var _screen_right: float

var _alive: bool = true


func _ready() -> void:
	_refresh_screen_bounds()
	get_viewport().size_changed.connect(_refresh_screen_bounds)


## Reset to spawn state without reloading the scene. Currently unused
## (RESTART reloads the whole scene) but lets us add a respawn flow later
## without leaving the `_alive` flag stuck at false.
func reset() -> void:
	_alive = true
	velocity = Vector2.ZERO
	_finger_zones.clear()
	_zone_counts.clear()


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
	position.x = min(position.x, _screen_right - screen_right_padding)
	position.y = clamp(position.y, _road_top(), _road_bottom())

	# --- Death check: bike fully past the left edge.
	if position.x < _screen_left - death_offscreen_buffer:
		_alive = false
		_finger_zones.clear()
		_zone_counts.clear()
		died.emit()


# --- Touch input handling -----------------------------------------------
func _input(event: InputEvent) -> void:
	if not _alive:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			_set_finger_zone(event.index, _zone_for_position(event.position))
		else:
			_clear_finger(event.index)
	elif event is InputEventScreenDrag:
		_set_finger_zone(event.index, _zone_for_position(event.position))


# --- Helpers ------------------------------------------------------------
func _refresh_screen_bounds() -> void:
	_screen_size = get_viewport_rect().size
	_screen_left = -_screen_size.x * 0.5
	_screen_right = _screen_size.x * 0.5


func _zone_for_position(pos: Vector2) -> int:
	var w: float = _screen_size.x
	var h: float = _screen_size.y
	if pos.x >= w * 0.5:
		return Zone.ACCEL
	if pos.y < h * 0.5:
		return Zone.UP
	return Zone.DOWN


func _set_finger_zone(idx: int, zone: int) -> void:
	if _finger_zones.has(idx):
		var old: int = _finger_zones[idx]
		if old == zone:
			return
		_zone_counts[old] = max(0, _zone_counts.get(old, 0) - 1)
	_finger_zones[idx] = zone
	_zone_counts[zone] = _zone_counts.get(zone, 0) + 1


func _clear_finger(idx: int) -> void:
	if not _finger_zones.has(idx):
		return
	var z: int = _finger_zones[idx]
	_finger_zones.erase(idx)
	_zone_counts[z] = max(0, _zone_counts.get(z, 0) - 1)


func _any_finger_in(zone: int) -> bool:
	return _zone_counts.get(zone, 0) > 0


func _road_top() -> float:
	return road_config.road_top_y if road_config else 80.0


func _road_bottom() -> float:
	return road_config.road_bottom_y if road_config else 300.0

