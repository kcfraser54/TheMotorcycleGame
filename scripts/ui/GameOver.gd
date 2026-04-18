extends CanvasLayer

## Game-over overlay. Hidden until GameState.game_over fires.
## Pauses the SceneTree on show so the player freezes; the parallax
## background keeps animating because Main.gd flips its process_mode
## to ALWAYS at runtime.
##
## Process mode (PROCESS_MODE_WHEN_PAUSED) is set on the root node in
## the .tscn so it shows in the Inspector — not here.

@export var menu_scene: PackedScene

@onready var final_score_label: Label = %FinalScore
@onready var high_score_label: Label = %HighScore
@onready var restart_button: Button = %RestartButton
@onready var menu_button: Button = %MenuButton


func _ready() -> void:
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	GameState.game_over.connect(_on_game_over)


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
	get_tree().paused = false
	if not menu_scene:
		push_error("GameOver: menu_scene PackedScene not assigned in Inspector.")
		return
	get_tree().change_scene_to_packed(menu_scene)
