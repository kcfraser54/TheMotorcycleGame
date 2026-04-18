extends Node

## Coordinator for the gameplay scene.
## - Starts the score timer when the scene loads.
## - Listens for the player's `died` signal and ends the game.
## - Keeps the parallax background animating while the tree is paused
##   by setting its process_mode to ALWAYS at runtime.

@onready var player: CharacterBody2D = $Player
@onready var background: Node2D = $Background


func _ready() -> void:
	# Background keeps scrolling on the GameOver screen for "alive" feel.
	background.process_mode = Node.PROCESS_MODE_ALWAYS
	player.died.connect(_on_player_died)
	GameState.start_game()


func _on_player_died() -> void:
	GameState.end_game()
