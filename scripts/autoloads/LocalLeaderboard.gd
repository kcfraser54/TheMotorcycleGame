extends Node

## Local leaderboard singleton (autoload).
##
## Persists the top `max_entries` scores to `user://leaderboard.json` so they
## survive across runs and reinstalls-of-the-same-user. No player names are
## stored — each entry is just a score and an ISO 8601 UTC timestamp.
##
## Storage shape (versioned so we can migrate later without losing data):
##   {
##     "version": 1,
##     "scores": [ { "score": 1234, "date": "2026-04-18T19:45:02" }, ... ]
##   }
##
## Tweak `max_entries` in Project Settings → Autoload → LocalLeaderboard,
## or edit the @export default below.

signal leaderboard_changed

const SAVE_PATH := "user://leaderboard.json"
const SCHEMA_VERSION := 1

@export var max_entries: int = 10

var _entries: Array[Dictionary] = []
## Index in `_entries` of the most recently submitted score, or -1 if none
## this session (or if it didn't make the cut). Lets the UI highlight it.
var last_submitted_index: int = -1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load()


## Add a score. Returns the index it landed at in the top list,
## or -1 if it didn't qualify.
func submit(score: int) -> int:
	var entry := {
		"score": score,
		"date": Time.get_datetime_string_from_system(true),  # UTC, ISO 8601
	}
	_entries.append(entry)
	# Sort descending by score; stable enough for our needs.
	_entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if _entries.size() > max_entries:
		_entries.resize(max_entries)
	last_submitted_index = _entries.find(entry)
	_save()
	leaderboard_changed.emit()
	return last_submitted_index


## Returns a copy of the top entries (already sorted, capped to max_entries).
func get_top() -> Array[Dictionary]:
	return _entries.duplicate(true)


func clear() -> void:
	_entries.clear()
	last_submitted_index = -1
	_save()
	leaderboard_changed.emit()


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		push_warning("LocalLeaderboard: could not open %s for reading." % SAVE_PATH)
		return
	var text := f.get_as_text()
	f.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("LocalLeaderboard: save file malformed; ignoring.")
		return
	# Version check left intentionally permissive — future migrations land here.
	var raw_scores: Variant = parsed.get("scores", [])
	if typeof(raw_scores) != TYPE_ARRAY:
		return
	_entries.clear()
	for item: Variant in raw_scores:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		_entries.append({
			"score": int(item.get("score", 0)),
			"date": String(item.get("date", "")),
		})
	if _entries.size() > max_entries:
		_entries.resize(max_entries)


func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("LocalLeaderboard: could not open %s for writing." % SAVE_PATH)
		return
	var payload := {
		"version": SCHEMA_VERSION,
		"scores": _entries,
	}
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()
