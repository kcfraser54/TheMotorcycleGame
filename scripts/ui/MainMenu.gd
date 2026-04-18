extends Node

## Main menu controller. The scene root is a Node so the parallax
## Background renders correctly (it expects Node2D coordinates centered
## on the camera). The actual UI sits inside a CanvasLayer child.

@export var game_scene: PackedScene

@onready var start_button: Button = $UI/Center/VBox/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	start_button.grab_focus()
	# Make sure the world isn't paused if we returned here from GameOver.
	get_tree().paused = false


func _on_start_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		get_tree().change_scene_to_file("res://scenes/main/Main.tscn")
