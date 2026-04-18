extends Node2D

## Animates the lane dashes and motion speed-lines on the road surface.
## Reads geometry + scroll speed from a shared RoadConfig resource so the
## Player and any future obstacle scripts stay in sync.

@export var road_config: RoadConfig

# --- Lane dashes ---------------------------------------------------------
@export var dash_count: int = 14
@export var dash_width: float = 60.0
@export var dash_height: float = 5.0
@export var dash_gap: float = 50.0
## Y positions of each lane divider (top-down 3-lane road).
@export var lane_divider_ys: Array[float] = [150.0, 230.0]
@export var dash_color: Color = Color(0.65, 0.7, 0.72, 0.85)

# --- Speed lines (motion streaks) ---------------------------------------
@export var speed_line_count: int = 16
@export var speed_line_min_speed: float = 600.0
@export var speed_line_max_speed: float = 1500.0
@export var speed_line_color: Color = Color(0.75, 0.7, 0.85, 0.28)

## Inner record so the speed-line array is typed instead of a Dictionary
## with magic string keys.
class SpeedLine:
	var node: ColorRect
	var speed: float

@onready var dashes_root: Node2D = $Dashes
@onready var speed_lines_root: Node2D = $SpeedLines

var _screen_left: float
var _screen_right: float

var _dashes: Array[ColorRect] = []
var _speed_lines: Array[SpeedLine] = []

# Guard so _build_* never duplicates children if _ready ever fires twice.
var _built: bool = false


func _ready() -> void:
	_refresh_screen_bounds()
	get_viewport().size_changed.connect(_refresh_screen_bounds)
	if _built:
		return
	_built = true
	_build_dashes()
	_build_speed_lines()


func _process(delta: float) -> void:
	_animate_dashes(delta)
	_animate_speed_lines(delta)


# --- Helpers ------------------------------------------------------------
func _refresh_screen_bounds() -> void:
	var vp_size := get_viewport_rect().size
	_screen_left = -vp_size.x * 0.5 - 50.0
	_screen_right = vp_size.x * 0.5 + 50.0


func _scroll_speed() -> float:
	return road_config.scroll_speed if road_config else 900.0


func _road_top() -> float:
	return road_config.road_top_y if road_config else 80.0


func _road_bottom() -> float:
	return road_config.road_bottom_y if road_config else 300.0


# --- Dashes -------------------------------------------------------------
func _build_dashes() -> void:
	var spacing := dash_width + dash_gap
	for lane_index in lane_divider_ys.size():
		var y: float = lane_divider_ys[lane_index]
		# Stagger lanes by half a cycle so dashes don't all line up vertically.
		var offset: float = (spacing * 0.5) if (lane_index % 2 == 1) else 0.0
		for i in dash_count:
			var dash := ColorRect.new()
			dash.color = dash_color
			dash.size = Vector2(dash_width, dash_height)
			dash.position = Vector2(_screen_left + i * spacing + offset, y - dash_height * 0.5)
			dashes_root.add_child(dash)
			_dashes.append(dash)


func _animate_dashes(delta: float) -> void:
	var spacing := dash_width + dash_gap
	var total_span := dash_count * spacing
	var s := _scroll_speed()
	for dash in _dashes:
		dash.position.x -= s * delta
		if dash.position.x + dash_width < _screen_left:
			dash.position.x += total_span


# --- Speed lines --------------------------------------------------------
func _build_speed_lines() -> void:
	var top := _road_top()
	var bot := _road_bottom()
	for i in speed_line_count:
		var line := ColorRect.new()
		line.color = speed_line_color
		var length := randf_range(60.0, 180.0)
		var thickness := randf_range(1.0, 3.0)
		line.size = Vector2(length, thickness)
		line.position = Vector2(
			randf_range(_screen_left, _screen_right),
			randf_range(top, bot)
		)
		speed_lines_root.add_child(line)

		var entry := SpeedLine.new()
		entry.node = line
		entry.speed = randf_range(speed_line_min_speed, speed_line_max_speed)
		_speed_lines.append(entry)


func _animate_speed_lines(delta: float) -> void:
	var top := _road_top()
	var bot := _road_bottom()
	for entry in _speed_lines:
		entry.node.position.x -= entry.speed * delta
		if entry.node.position.x + entry.node.size.x < _screen_left:
			entry.node.position.x = _screen_right + randf_range(0.0, 200.0)
			entry.node.position.y = randf_range(top, bot)
			entry.speed = randf_range(speed_line_min_speed, speed_line_max_speed)
