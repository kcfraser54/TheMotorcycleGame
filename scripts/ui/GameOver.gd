extends CanvasLayer

## Game-over overlay. Hidden until GameState.game_over fires.
## Pauses the SceneTree on show so the player freezes; the parallax
## background keeps animating because Main.gd flips its process_mode
## to ALWAYS at runtime.
##
## Process mode (PROCESS_MODE_WHEN_PAUSED) is set on the root node in
## the .tscn so it shows in the Inspector — not here.

@export_file("*.tscn") var menu_scene_path: String = "res://scenes/ui/MainMenu.tscn"
@export_file("*.tscn") var leaderboard_scene_path: String = "res://scenes/ui/Leaderboard.tscn"

@onready var final_score_label: Label = %FinalScore
@onready var high_score_label: Label = %HighScore
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton
@onready var leaderboard_button: Button = %LeaderboardButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	GameState.game_over.connect(_on_game_over)


## Listen for the `pause` input action (Esc on desktop) and trigger RESTART
## while the Game Over overlay is visible. Uses _input rather than
## _unhandled_input so it works even if a Button currently has focus.
func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_on_restart_pressed()


func _on_game_over(final_score: int) -> void:
	final_score_label.text = "SCORE  %d" % final_score
	high_score_label.text = "BEST   %d" % GameState.high_score
	visible = true
	restart_button.grab_focus()
	get_tree().paused = true


func _on_restart_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	_go_to(menu_scene_path, "menu_scene_path")


func _on_leaderboard_pressed() -> void:
	_go_to(leaderboard_scene_path, "leaderboard_scene_path")


## Validate the target first, THEN unpause + change scene. If we unpaused
## before validating and the target was bad, GameOver's WHEN_PAUSED process
## mode would cut off input and soft-lock the overlay.
func _go_to(path: String, field_name: String) -> void:
	if path.is_empty():
		push_error("GameOver: %s not assigned in Inspector." % field_name)
		return
	get_tree().paused = false
	get_tree().change_scene_to_file(path)
