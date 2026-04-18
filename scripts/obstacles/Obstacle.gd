extends Area2D
class_name Obstacle

## Base class for road obstacles (Barrier, Rock, SpikeStrip, ...).
##
## Behaviour shared by all obstacles:
##   - Scrolls leftward at `road_config.scroll_speed`.
##   - Self-cleans when fully past the left edge.
##   - Emits `hit_player` when the Player body enters its area; the
##     gameplay coordinator decides what that means (death, slowdown, etc.).
##
## NOTE: This is one of only two scripts in the project with `class_name`
## (the other is RoadConfig). It's required so subclasses can write
## `extends Obstacle` instead of an ugly path-based extends.

signal hit_player

@export var road_config: RoadConfig
## Extra distance past the left edge before queue_free() runs, so an
## obstacle can fully exit the screen before being culled.
@export var despawn_buffer: float = 200.0

var _screen_left: float


func _ready() -> void:
	_refresh_bounds()
	get_viewport().size_changed.connect(_refresh_bounds)
	body_entered.connect(_on_body_entered)


func _refresh_bounds() -> void:
	_screen_left = -get_viewport_rect().size.x * 0.5


func _physics_process(delta: float) -> void:
	var s := road_config.scroll_speed if road_config else RoadConfig.DEFAULT_SCROLL_SPEED
	position.x -= s * delta
	if position.x < _screen_left - despawn_buffer:
		queue_free()


func _on_body_entered(body: Node) -> void:
	# Player exposes a `died` signal — sniff for that to identify it
	# without coupling to a class_name.
	if body.has_signal("died"):
		hit_player.emit()
