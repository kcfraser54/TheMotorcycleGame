extends Node

## Coordinator for the gameplay scene.
## - Starts the score timer when the scene loads.
## - Listens for the player's `died` signal and ends the game.
## - Keeps the parallax background animating while the tree is paused
##   by setting its process_mode to ALWAYS at runtime. This is intentional
##   override of the child's mode and lives here (not in background.tscn)
##   because the Background scene shouldn't need to know it's used in a
##   pausable context.

@onready var player: CharacterBody2D = $Player
@onready var background: Node2D = $Background


func _ready() -> void:
	background.process_mode = Node.PROCESS_MODE_ALWAYS
	player.died.connect(_on_player_died)
	GameState.start_game()


func _on_player_died() -> void:
	GameState.end_game()
