extends Node

## Global game state singleton (autoload).
##
## Holds the running score and emits signals when it changes.
## Tweak `points_per_tick` and `tick_interval` in the Inspector
## (Project Settings → Autoload → GameState → Edit, or open the
## script and adjust the @export defaults) to change the scoring rate.

signal score_changed(new_score: int)
signal game_started
signal game_over_signal(final_score: int)

@export var points_per_tick: int = 1
@export var tick_interval: float = 0.1   # seconds between ticks

var current_score: int = 0
var high_score: int = 0
var is_running: bool = false

var _timer: Timer


func _ready() -> void:
	# Autoload should keep ticking even if you later add other pause logic;
	# we gate scoring on `is_running` instead.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_timer = Timer.new()
	_timer.wait_time = max(tick_interval, 0.001)
	_timer.one_shot = false
	_timer.autostart = false
	_timer.timeout.connect(_on_tick)
	add_child(_timer)


func start_game() -> void:
	current_score = 0
	is_running = true
	score_changed.emit(current_score)
	_timer.wait_time = max(tick_interval, 0.001)
	_timer.start()
	game_started.emit()


func end_game() -> void:
	if not is_running:
		return
	is_running = false
	_timer.stop()
	if current_score > high_score:
		high_score = current_score
	game_over_signal.emit(current_score)


func _on_tick() -> void:
	if not is_running:
		return
	current_score += points_per_tick
	score_changed.emit(current_score)
