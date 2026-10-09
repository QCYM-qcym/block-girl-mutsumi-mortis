extends RefCounted
## Run-scoped delivery guard shared by both public sampling modules. Retired
## known runs and watermarks outlive clear(); Host still guards unseen old runs.
var _watermarks: Dictionary = {}
var _retired_runs: Dictionary = {}
var _current_run := ""

func claim(event: Dictionary) -> bool:
	var identity: Dictionary = event.presentation_identity
	var run := JSON.stringify([identity.session_id, identity.level_run_id])
	if _retired_runs.has(run): return false
	var previous: Dictionary = _watermarks.get(run, {})
	if not previous.is_empty() and (event.event_id <= previous.event_id or event.attempt_id <= previous.attempt_id or identity.generation < previous.generation): return false
	if not _current_run.is_empty() and _current_run != run:
		_retired_runs[_current_run] = true
	_current_run = run
	_watermarks[run] = {"event_id": event.event_id, "attempt_id": event.attempt_id, "generation": identity.generation}
	return true
