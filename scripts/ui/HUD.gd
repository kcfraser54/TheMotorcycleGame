extends CanvasLayer

## Top-right score readout. Listens to GameState.score_changed.
## All visual styling lives inside HUD.tscn as theme overrides — edit
## the scene to restyle without touching this script.

@onready var score_label: Label = $ScorePanel/Margin/HBox/ScoreValue


func _ready() -> void:
	GameState.score_changed.connect(_on_score_changed)
	_on_score_changed(GameState.current_score)


func _on_score_changed(new_score: int) -> void:
	score_label.text = str(new_score)
