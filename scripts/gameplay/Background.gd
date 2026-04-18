extends Node2D

## Side-view parallax backdrop (sky, sun, far/near buildings).
## Road animation (lane dashes, speed lines) lives on the Road child node
## via Road.gd — this script is intentionally narrow.

# --- Parallax horizontal scroll speeds (pixels/sec) ---------------------
# Closer layers move faster — creates depth.
@export var sky_speed: float = 8.0
@export var far_buildings_speed: float = 60.0
@export var near_buildings_speed: float = 180.0

@onready var sky_pair: Array[Sprite2D] = [$Sky, $Sky2]
@onready var far_pair: Array[Sprite2D] = [$FarBuildings, $FarBuildings2]
@onready var near_pair: Array[Sprite2D] = [$NearBuildings, $NearBuildings2]

# Cached viewport metrics — refreshed in _normalize_all() so the per-frame
# scroll loop doesn't keep calling into get_viewport_rect().
var _vp_width: float = 0.0
var _vp_half: float = 0.0


func _ready() -> void:
	_normalize_all()
	get_viewport().size_changed.connect(_normalize_all)


func _process(delta: float) -> void:
	_scroll_pair(sky_pair, sky_speed, delta)
	_scroll_pair(far_pair, far_buildings_speed, delta)
	_scroll_pair(near_pair, near_buildings_speed, delta)


# --- Sizing --------------------------------------------------------------
func _normalize_all() -> void:
	_vp_width = get_viewport_rect().size.x
	_vp_half = _vp_width * 0.5
	_normalize_pair(sky_pair)
	_normalize_pair(far_pair)
	_normalize_pair(near_pair)


func _normalize_pair(pair: Array[Sprite2D]) -> void:
	if pair.size() < 2:
		return
	# Each tile MUST be at least as wide as the viewport. If the texture is
	# too small, scale it up so one tile can always cover the whole screen
	# while the other is wrapping around.
	var tex_w: float = pair[0].texture.get_width()
	var min_scale_x: float = _vp_width / tex_w
	for s in pair:
		if s.scale.x < min_scale_x:
			s.scale.x = min_scale_x

	# Sync scale & y between the two sprites.
	pair[1].scale = pair[0].scale
	pair[1].position.y = pair[0].position.y

	var tile_w: float = _tile_width(pair[0])
	# Place sprite 0 to cover the left half, sprite 1 directly to its right.
	pair[0].position.x = 0.0
	pair[1].position.x = tile_w


func _tile_width(sprite: Sprite2D) -> float:
	return sprite.texture.get_width() * sprite.scale.x


# --- Scrolling -----------------------------------------------------------
func _scroll_pair(pair: Array[Sprite2D], speed: float, delta: float) -> void:
	if pair.size() < 2:
		return
	var tile_w: float = _tile_width(pair[0])
	for s in pair:
		s.position.x -= speed * delta

	# Wrap: when a sprite's RIGHT edge scrolls past the LEFT edge of the
	# viewport, teleport it to the right of its partner. Because each tile
	# is >= viewport width, the partner always covers the full screen during
	# the transition — no gaps, no pop-in.
	for i in pair.size():
		var s: Sprite2D = pair[i]
		var right_edge: float = s.position.x + tile_w * 0.5
		if right_edge <= -_vp_half:
			var other: Sprite2D = pair[1 - i]
			s.position.x = other.position.x + tile_w
