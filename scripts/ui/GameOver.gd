extends CanvasLayer

## Game-over overlay. Hidden until GameState.game_over_signal fires.
## Pauses the SceneTree on show so the player freezes; the parallax
## background keeps animating because its process_mode is set to ALWAYS.

@onready var final_score_label: Label = $Dim/Center/VBox/FinalScore
@onready var high_score_label: Label = $Dim/Center/VBox/HighScore
@onready var restart_button: Button = $Dim/Center/VBox/Buttons/RestartButton
@onready var menu_button: Button = $Dim/Center/VBox/Buttons/MenuButton


func _ready() -> void:
	# Buttons must be reachable while the tree is paused.
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	visible = false
	restart_button.pressed.connect(_on_restart_pressed)
	menu_button.pressed.connect(_on_menu_pressed)
	GameState.game_over_signal.connect(_on_game_over)


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
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")
