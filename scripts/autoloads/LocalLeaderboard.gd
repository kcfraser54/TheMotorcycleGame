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
##
## Implementation: insertion-sort to capture the exact landing index without
## relying on `find()` reference-equality (which would silently break if a
## future change cloned/normalized entries before insert).
func submit(score: int) -> int:
	var entry := {
		"score": score,
		"date": Time.get_datetime_string_from_system(true),  # UTC, ISO 8601
	}
	var insert_at := _entries.size()
	for i in _entries.size():
		if score > int(_entries[i]["score"]):
			insert_at = i
			break
	_entries.insert(insert_at, entry)
	if _entries.size() > max_entries:
		_entries.resize(max_entries)
	# If the new entry got truncated off the end, it didn't qualify.
	last_submitted_index = insert_at if insert_at < _entries.size() else -1
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
		var score := int(item.get("score", 0))
		# Defend against hand-edited / corrupt saves: a negative score would
		# otherwise sort to the top and dominate the leaderboard forever.
		if score < 0:
			continue
		_entries.append({
			"score": score,
			"date": String(item.get("date", "")),
		})
	# Re-sort defensively in case the saved file was out of order.
	_entries.sort_custom(func(a, b): return int(a["score"]) > int(b["score"]))
	if _entries.size() > max_entries:
		_entries.resize(max_entries)


## Atomic write: serialize to `<SAVE_PATH>.tmp`, flush, then rename over the
## live file. If the process is killed mid-write, the live file is either
## the previous good version or doesn't yet exist — never a truncated/corrupt
## half-write that breaks _load() on next launch.
func _save() -> void:
	var tmp_path := SAVE_PATH + ".tmp"
	var f := FileAccess.open(tmp_path, FileAccess.WRITE)
	if f == null:
		push_warning("LocalLeaderboard: could not open %s for writing." % tmp_path)
		return
	var payload := {
		"version": SCHEMA_VERSION,
		"scores": _entries,
	}
	f.store_string(JSON.stringify(payload, "\t"))
	f.close()

	var dir := DirAccess.open("user://")
	if dir == null:
		push_warning("LocalLeaderboard: could not open user:// to finalize save.")
		return
	var tmp_name := tmp_path.get_file()
	var final_name := SAVE_PATH.get_file()
	var err := dir.rename(tmp_name, final_name)
	if err != OK:
		push_warning("LocalLeaderboard: atomic rename failed (err %d); save may be incomplete." % err)
