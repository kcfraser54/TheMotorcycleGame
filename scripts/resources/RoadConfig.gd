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

@export var road_top_y: float = 80.0
@export var road_bottom_y: float = 300.0
@export var scroll_speed: float = 900.0
