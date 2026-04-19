extends Node

## Main menu controller. The scene root is a Node so the parallax
## Background renders correctly (it expects Node2D coordinates centered
## on the camera). The actual UI sits inside a CanvasLayer child.

@export_file("*.tscn") var game_scene_path: String = "res://scenes/main/Main.tscn"
@export_file("*.tscn") var leaderboard_scene_path: String = "res://scenes/ui/Leaderboard.tscn"

@onready var start_button: Button = %StartButton
@onready var leaderboard_button: Button = %LeaderboardButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	start_button.grab_focus()
	# Make sure the world isn't paused if we returned here from GameOver.
	get_tree().paused = false


func _on_start_pressed() -> void:
	if game_scene_path.is_empty():
		push_error("MainMenu: game_scene_path not assigned in Inspector.")
		return
	get_tree().change_scene_to_file(game_scene_path)


func _on_leaderboard_pressed() -> void:
	if leaderboard_scene_path.is_empty():
		push_error("MainMenu: leaderboard_scene_path not assigned in Inspector.")
		return
	get_tree().change_scene_to_file(leaderboard_scene_path)
