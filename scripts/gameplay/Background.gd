extends Node2D

## Side-view scrolling background for a motorcycle game.
## Camera looks at the bike's profile; everything scrolls right -> left.

# --- Parallax horizontal scroll speeds (pixels/sec) -----------------------
# Closer layers move faster — creates depth.
@export var sky_speed: float = 8.0
@export var far_buildings_speed: float = 60.0
@export var near_buildings_speed: float = 180.0

# --- Road / ground motion ------------------------------------------------
@export var road_speed: float = 900.0          # how fast lane dashes scream past
@export var dash_count: int = 14
@export var dash_width: float = 60.0
@export var dash_height: float = 5.0
@export var dash_gap: float = 50.0             # spacing between dashes
## Y positions of each lane divider (top-down view, 3-lane road).
@export var lane_divider_ys: Array[float] = [150.0, 230.0]
@export var dash_color: Color = Color(0.65, 0.7, 0.72, 0.85)

# Speed lines streak across the road for a "rushing" sensation.
@export var speed_line_count: int = 16
@export var speed_line_min_speed: float = 600.0
@export var speed_line_max_speed: float = 1500.0
@export var road_top_y: float = 75.0
@export var road_bottom_y: float = 305.0
@export var speed_line_color: Color = Color(0.75, 0.7, 0.85, 0.28)

@onready var sky_pair: Array = [$Sky, $Sky2]
@onready var far_pair: Array = [$FarBuildings, $FarBuildings2]
@onready var near_pair: Array = [$NearBuildings, $NearBuildings2]
@onready var dashes_root: Node2D = $Road/Dashes
@onready var speed_lines_root: Node2D = $Road/SpeedLines

var _screen_left: float
var _screen_right: float

var _dashes: Array = []
var _speed_lines: Array = []   # each: { node: ColorRect, speed: float }


func _ready() -> void:
	randomize()
	# Derive screen bounds from the actual viewport so nothing is hardcoded.
	var vp_size := get_viewport_rect().size
	_screen_left = -vp_size.x * 0.5 - 50.0   # small buffer
	_screen_right = vp_size.x * 0.5 + 50.0
	_normalize_pair(sky_pair)
	_normalize_pair(far_pair)
	_normalize_pair(near_pair)
	_build_dashes()
	_build_speed_lines()


func _process(delta: float) -> void:
	_scroll_pair(sky_pair, sky_speed, delta)
	_scroll_pair(far_pair, far_buildings_speed, delta)
	_scroll_pair(near_pair, near_buildings_speed, delta)
	_animate_dashes(delta)
	_animate_speed_lines(delta)


# --- Parallax sprite pair scrolling --------------------------------------
func _normalize_pair(pair: Array) -> void:
	if pair.size() < 2:
		return
	# Each tile MUST be at least as wide as the viewport.  If the texture is
	# too small, we scale it up so one tile can always cover the whole screen
	# while the other is wrapping around.
	var vp_w: float = get_viewport_rect().size.x
	var tex_w: float = pair[0].texture.get_width()
	var min_scale_x: float = vp_w / tex_w
	for s in pair:
		if s.scale.x < min_scale_x:
			s.scale.x = min_scale_x

	# Sync scale & y between the two sprites.
	pair[1].scale = pair[0].scale
	pair[1].position.y = pair[0].position.y

	var tile_w: float = _tile_width(pair[0])
	# Place sprite 0 so it covers the left half, sprite 1 directly to its right.
	pair[0].position.x = 0.0
	pair[1].position.x = tile_w


func _tile_width(sprite: Sprite2D) -> float:
	return sprite.texture.get_width() * sprite.scale.x


func _scroll_pair(pair: Array, speed: float, delta: float) -> void:
	if pair.size() < 2:
		return
	var tile_w: float = _tile_width(pair[0])

	for s in pair:
		s.position.x -= speed * delta

	# Wrap: when a sprite's RIGHT edge scrolls past the LEFT edge of the
	# viewport, teleport it to the right of its partner.  Because each tile
	# is >= viewport width, the partner always covers the full screen during
	# the transition — no gaps, no pop-in.
	var vp_half: float = get_viewport_rect().size.x * 0.5
	for i in range(pair.size()):
		var s: Sprite2D = pair[i]
		var right_edge: float = s.position.x + tile_w * 0.5
		if right_edge <= -vp_half:
			var other: Sprite2D = pair[1 - i]
			s.position.x = other.position.x + tile_w


# --- Dashed lane markings (the "conveyor belt") --------------------------
func _build_dashes() -> void:
	var spacing: float = dash_width + dash_gap
	# Stagger lanes by half a cycle so the dashes don't all line up vertically.
	for lane_index in range(lane_divider_ys.size()):
		var y: float = lane_divider_ys[lane_index]
		var offset: float = (spacing * 0.5) if (lane_index % 2 == 1) else 0.0
		for i in range(dash_count):
			var dash := ColorRect.new()
			dash.color = dash_color
			dash.size = Vector2(dash_width, dash_height)
			dash.position = Vector2(_screen_left + i * spacing + offset, y - dash_height * 0.5)
			dashes_root.add_child(dash)
			_dashes.append(dash)


func _animate_dashes(delta: float) -> void:
	var spacing: float = dash_width + dash_gap
	var total_span: float = dash_count * spacing
	for dash in _dashes:
		dash.position.x -= road_speed * delta
		if dash.position.x + dash_width < _screen_left:
			dash.position.x += total_span


# --- Speed lines (motion streaks across the ground) ----------------------
func _build_speed_lines() -> void:
	for i in range(speed_line_count):
		var line := ColorRect.new()
		line.color = speed_line_color
		var length: float = randf_range(60.0, 180.0)
		var thickness: float = randf_range(1.0, 3.0)
		line.size = Vector2(length, thickness)
		line.position = Vector2(
			randf_range(_screen_left, _screen_right),
			randf_range(road_top_y, road_bottom_y)
		)
		speed_lines_root.add_child(line)
		_speed_lines.append({
			"node": line,
			"speed": randf_range(speed_line_min_speed, speed_line_max_speed),
		})


func _animate_speed_lines(delta: float) -> void:
	for entry in _speed_lines:
		var line: ColorRect = entry["node"]
		line.position.x -= entry["speed"] * delta
		if line.position.x + line.size.x < _screen_left:
			line.position.x = _screen_right + randf_range(0.0, 200.0)
			line.position.y = randf_range(road_top_y, road_bottom_y)
			entry["speed"] = randf_range(speed_line_min_speed, speed_line_max_speed)
