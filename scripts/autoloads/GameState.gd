extends Node

## Global game state singleton (autoload).
##
## Holds the running score and emits signals when it changes.
## Tweak `points_per_tick` and `tick_interval` in the Inspector
## (Project Settings → Autoload → GameState → Edit, or open the
## script and adjust the @export defaults) to change the scoring rate.
##
## NOTE: Process mode is set to ALWAYS in code (not in a .tscn) because
## autoloads have no scene file — the Inspector setting lives here only.

signal score_changed(new_score: int)
signal game_started
signal game_over(final_score: int)

@export var points_per_tick: int = 1
@export var tick_interval: float = 0.1   ## seconds between ticks

var current_score: int = 0
var high_score: int = 0
var is_running: bool = false

var _timer: Timer

func _ready() -> void:
	# Score logic must keep working even when the SceneTree is paused
	# (e.g. on Game Over) — gating is done via `is_running`, not pause.
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
	# Emit so any subscriber (HUD) repaints to "0" without each one
	# having to read GameState.current_score defensively.
	score_changed.emit(current_score)
	# Re-apply tick_interval so live Inspector tweaks between runs take effect.
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
	# Persist the run to the local leaderboard before broadcasting game_over,
	# so any listener (e.g. GameOver overlay) can read fresh top scores.
	LocalLeaderboard.submit(current_score)
	game_over.emit(current_score)

func _on_tick() -> void:
	if not is_running:
		return
	current_score += points_per_tick
	score_changed.emit(current_score)
