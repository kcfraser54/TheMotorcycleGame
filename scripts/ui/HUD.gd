extends CanvasLayer

## Top-right score readout. Listens to GameState.score_changed.
## All visual styling lives inside HUD.tscn as theme overrides — edit
## the scene to restyle without touching this script.

@onready var score_label: Label = %ScoreValue


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	# No defensive initial paint: GameState.start_game() emits score_changed
	# right after Main._ready, which fires this listener and paints "0".


func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)
