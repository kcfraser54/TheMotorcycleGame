extends Resource
class_name RoadConfig

## Shared road geometry + scroll speed.
##
## Used by Player (vertical clamp), Road (visual scroll speed), and
## Obstacle (despawn-edge scroll). Edit res://resources/default_road.tres
## in the Inspector to retune the road for the whole game in one place.
##
## NOTE: This is one of only two scripts in the project with `class_name`
## (the other is Obstacle). It's required so `@export var road_config: RoadConfig`
## can be typed in scenes; without it you'd have to use untyped Resource
## and lose Inspector validation.
##
## DEFAULTS: kept here as constants so any consumer (Road, Background, Obstacle)
## that fails to receive a config can fall back to the SAME numbers without
## three files quietly drifting out of sync.

const DEFAULT_ROAD_TOP_Y := 80.0
const DEFAULT_ROAD_BOTTOM_Y := 300.0
const DEFAULT_SCROLL_SPEED := 900.0

@export var road_top_y: float = DEFAULT_ROAD_TOP_Y
@export var road_bottom_y: float = DEFAULT_ROAD_BOTTOM_Y
@export var scroll_speed: float = DEFAULT_SCROLL_SPEED
