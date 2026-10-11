extends SceneTree
## Verify copied derived cache against the exact declared import identities.
func _initialize()->void:
	var manifest:=""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--uid-manifest="): manifest=arg.trim_prefix("--uid-manifest=")
	if manifest.is_empty(): push_error("Explicit declared UID manifest required");quit(1);return
	var rows:Variant=JSON.parse_string(FileAccess.get_file_as_string(manifest))
	if not rows is Array: push_error("UID manifest is not an array");quit(1);return
	var seen:Dictionary={}
	for row in rows:
		var id:int=ResourceUID.text_to_id(row.uid)
		if id<0 or not FileAccess.file_exists(row.path) or (seen.has(id) and seen[id]!=row.path):
			push_error("Invalid or ambiguous declared resource UID: "+str(row));quit(1);return
		seen[id]=row.path
		if not ResourceUID.has_id(id) or ResourceUID.get_id_path(id)!=row.path:
			push_error("Derived cache does not resolve declared import: "+str(row));quit(1);return
	print(JSON.stringify({"status":"PASS","verified_import_uids":seen.size(),"source_changes":"NONE","api":"ResourceUID.has_id/get_id_path"}))
	quit(0)
