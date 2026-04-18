extends CanvasLayer

## Leaderboard screen. Reads from the LocalLeaderboard autoload and renders
## one row per entry. Always returns to the main menu via `return_scene_path`
## (assigned in the Inspector), regardless of where the user came from.
##
## NOTE: stored as a path (not a PackedScene export) on purpose — MainMenu
## already holds a PackedScene reference to this scene, and a circular
## ext_resource pair causes one side to load as null at runtime.

@export_file("*.tscn") var return_scene_path: String = "res://scenes/ui/MainMenu.tscn"

# Color the most-recently submitted score (if it's in the top list) so the
# player can spot their fresh run instantly.
const HIGHLIGHT_COLOR := Color(1, 0.6, 1, 1)        # neon pink
const NORMAL_COLOR := Color(0.85, 0.95, 1, 1)       # pale cyan
const RANK_COLOR := Color(0.2, 1, 0.95, 1)          # cyan

@onready var entries_container: VBoxContainer = %Entries
@onready var empty_label: Label = %EmptyLabel
@onready var back_button: Button = %BackButton


func _ready() -> void:
	# This screen can be reached from a paused GameOver overlay; make sure
	# we're not still paused once we land here.
	get_tree().paused = false
	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()
	_populate()


func _populate() -> void:
	for child in entries_container.get_children():
		child.queue_free()

	var entries := LocalLeaderboard.get_top()
	if entries.is_empty():
		empty_label.visible = true
		entries_container.visible = false
		return

	empty_label.visible = false
	entries_container.visible = true

	var highlight := LocalLeaderboard.last_submitted_index
	for i in entries.size():
		var entry: Dictionary = entries[i]
		if i > 0:
			entries_container.add_child(_build_separator())
		entries_container.add_child(_build_row(i + 1, entry, i == highlight))


# Column widths tuned so the three fields line up cleanly at any entry count.
const RANK_COL_WIDTH := 120
const SCORE_COL_WIDTH := 220
const DATE_COL_WIDTH := 240
const ROW_SEPARATION := 24


func _build_row(rank: int, entry: Dictionary, highlight: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", ROW_SEPARATION)
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	var color := HIGHLIGHT_COLOR if highlight else NORMAL_COLOR

	var rank_label := Label.new()
	rank_label.text = "%d." % rank
	rank_label.add_theme_color_override("font_color", HIGHLIGHT_COLOR if highlight else RANK_COLOR)
	rank_label.add_theme_font_size_override("font_size", 32)
	rank_label.custom_minimum_size = Vector2(RANK_COL_WIDTH, 0)
	rank_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(rank_label)

	var score_label := Label.new()
	score_label.text = "%d" % int(entry.get("score", 0))
	score_label.add_theme_color_override("font_color", color)
	score_label.add_theme_font_size_override("font_size", 32)
	score_label.custom_minimum_size = Vector2(SCORE_COL_WIDTH, 0)
	score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(score_label)

	var date_label := Label.new()
	date_label.text = _format_date(String(entry.get("date", "")))
	date_label.add_theme_color_override("font_color", color)
	date_label.add_theme_font_size_override("font_size", 24)
	date_label.custom_minimum_size = Vector2(DATE_COL_WIDTH, 0)
	date_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(date_label)

	return row


func _build_separator() -> HSeparator:
	var sep := HSeparator.new()
	# Give the line a subtle neon tint so it reads as intentional.
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 1, 0.95, 0.35)
	style.content_margin_top = 1
	style.content_margin_bottom = 1
	sep.add_theme_stylebox_override("separator", style)
	return sep


## Convert a stored ISO 8601 timestamp (e.g. "2026-04-18T19:45:02") into a
## short display string ("2026-04-18"). Falls back to whatever was stored
## if it doesn't look parseable.
func _format_date(iso: String) -> String:
	if iso.length() >= 10 and iso[4] == "-" and iso[7] == "-":
		return iso.substr(0, 10)
	return iso


func _on_back_pressed() -> void:
	if return_scene_path.is_empty():
		push_error("Leaderboard: return_scene_path not assigned in Inspector.")
		return
	get_tree().change_scene_to_file(return_scene_path)
