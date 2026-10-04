extends RefCounted
class_name FoundationToolWire
## Tool-only typed canonical bytes. Never a Level codec or trusted graph loader.
const Schemas = preload("res://tools/foundation/authoring_acceptance/wire_schemas.gd")
const MAX_BYTES = 134217728
const MAX_DEPTH = 64

static func encode_wire(kind: String, value: Variant) -> Dictionary:
	var valid: Dictionary = Schemas.validate(kind, value)
	if not valid.ok: return valid
	if kind == "stage_result":
		var attachments := _inline_stage_attachments(value.stage_record)
		if not attachments.ok: return attachments
	if kind in ["input_manifest","archive_manifest","stage_result","worker_message"]:
		var identity: Dictionary = value.run_identity if kind == "stage_result" else value.identity
		var expected: Dictionary = digest("versions",identity.versions)
		if not expected.ok or expected.value != identity.execution_digest:
			return Schemas.failure("WIRE_SCHEMA_INVALID", "Execution digest does not bind versions")
	var encoded: Dictionary = _encode_value(value)
	if not encoded.ok: return encoded
	var bytes := ('["foundationtoolwire.v1",' + _quote(kind) + ',').to_utf8_buffer()
	if bytes.size() + encoded.value.size() + 1 > MAX_BYTES: return _error("Wire byte limit exceeded")
	bytes.append_array(encoded.value)
	bytes.append(93)
	return Schemas.success(bytes)

static func decode_wire(kind: String, bytes: PackedByteArray) -> Dictionary:
	var parsed: Dictionary = _parse(bytes)
	if not parsed.ok: return parsed
	var tree: Variant = parsed.value
	if typeof(tree) != TYPE_ARRAY or tree.size() != 3 or tree[0] != "foundationtoolwire.v1" or typeof(tree[1]) != TYPE_STRING or tree[1] != kind:
		return _error("Wrong wire envelope")
	var value: Dictionary = _read(tree[2], 1)
	if not value.ok: return value
	var encoded: Dictionary = encode_wire(kind, value.value)
	if not encoded.ok: return encoded
	if encoded.value != bytes: return _error("Noncanonical wire bytes")
	return value

static func digest(kind: String, value: Variant) -> Dictionary:
	var encoded: Dictionary = encode_wire(kind, value)
	if not encoded.ok: return encoded
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(encoded.value)
	return Schemas.success(hash.finish().hex_encode())

## Stateless STAGE_RESULT binding, after the caller reads the exact ArtifactRef.
## No filesystem fallback, IPC cursor, sequence start rule or lifecycle mutation.
## The consumer must also verify run-root containment/links and all input/output
## artifacts against input.ready, sealed policy and the formal LevelCodec.
static func verify_stage_result(message: Variant, bytes: PackedByteArray) -> Dictionary:
	var checked := encode_wire("worker_message",message)
	if not checked.ok: return checked
	if message.kind != "STAGE_RESULT": return Schemas.failure("WIRE_SCHEMA_INVALID", "Expected STAGE_RESULT message")
	var ref: Dictionary = message.payload_ref_or_inline
	if bytes.size() != ref.byte_length: return Schemas.failure("WIRE_SCHEMA_INVALID", "stage_result byte_length mismatch")
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(bytes)
	if hash.finish().hex_encode() != ref.sha256: return Schemas.failure("WIRE_SCHEMA_INVALID", "stage_result SHA-256 mismatch")
	var decoded := decode_wire("stage_result",bytes)
	if not decoded.ok: return decoded
	if decoded.value.run_identity != message.identity or decoded.value.stage_record.stage_id != message.stage_id:
		return Schemas.failure("WIRE_SCHEMA_INVALID", "WorkerMessage/stage_result identity or stage mismatch")
	return decoded

## Inline formal values and their output references describe the same bytes.
## External graph/canonical/input bytes still require consumer readback checks.
static func _inline_stage_attachments(stage: Dictionary) -> Dictionary:
	if stage.native_result == null: return Schemas.success(null)
	if stage.stage_id == "INTENT_BIND" and stage.native_result.ok:
		return _inline_artifact("intent",stage.native_result.bound_intent,stage.evidence_refs.bound_intent)
	if stage.stage_id == "ORIGINAL_GRAPH" and stage.native_result.solution_trace != null:
		return _inline_artifact("trace",stage.native_result.solution_trace,stage.evidence_refs.selected_trace_ref.trace)
	return Schemas.success(null)

static func _inline_artifact(kind: String, value: Dictionary, ref: Dictionary) -> Dictionary:
	var encoded := encode_wire(kind,value)
	if not encoded.ok: return encoded
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(encoded.value)
	if ref.byte_length != encoded.value.size() or ref.sha256 != hash.finish().hex_encode():
		return Schemas.failure("WIRE_SCHEMA_INVALID", "Inline value differs from its " + kind + " ArtifactRef")
	return Schemas.success(null)

## Internal value codec. It does not bypass the public record schema boundary.
static func _encode_value(value: Variant) -> Dictionary:
	var writer := Writer.new()
	writer.write(value, 1)
	if not writer.problem.is_empty(): return _error(writer.problem)
	return Schemas.success(writer.bytes)

static func _decode_value(bytes: PackedByteArray) -> Dictionary:
	var parsed: Dictionary = _parse(bytes)
	if not parsed.ok: return parsed
	var value: Dictionary = _read(parsed.value, 1)
	if not value.ok: return value
	var encoded: Dictionary = _encode_value(value.value)
	if not encoded.ok: return encoded
	if encoded.value != bytes: return _error("Noncanonical value bytes")
	return value

static func _parse(bytes: PackedByteArray) -> Dictionary:
	if bytes.size() > MAX_BYTES: return _error("Wire byte limit exceeded")
	if bytes.has(0): return _error("Raw NUL forbidden in JSON")
	if not _valid_utf8(bytes): return _error("Invalid UTF-8")
	var text := bytes.get_string_from_utf8()
	# Godot String cannot preserve embedded NUL. Reject before JSON.parse can
	# replace it and emit a Unicode error; never certify lossy text restoration.
	var nul_search := 0
	while true:
		var nul := text.find("\\u0000", nul_search)
		if nul < 0: break
		var slash := nul - 1
		while slash >= 0 and text[slash] == '\\': slash -= 1
		if (nul - slash - 1) % 2 == 0:
			return Schemas.failure("WIRE_PRECISION_UNSUPPORTED", "Godot String cannot preserve U+0000")
		nul_search = nul + 6
	# Bound container nesting before recursive JSON parsing; strings are skipped
	# using native find, so a permitted large string does not require 128M script steps.
	var position := 0
	var nesting := 0
	while position < text.length():
		var c := text[position]
		if c == '"':
			position += 1
			while true:
				var end := text.find('"', position)
				if end < 0: return _error("Unterminated string")
				var back := end - 1
				while back >= position and text[back] == '\\': back -= 1
				position = end + 1
				if (end - back - 1) % 2 == 0: break
		elif c == '[':
			nesting += 1
			if nesting > MAX_DEPTH * 3 + 2: return _error("Wire depth limit exceeded")
			position += 1
		elif c == ']':
			nesting -= 1
			position += 1
		elif c == '{' or c == '}': return _error("JSON objects forbidden")
		else: position += 1
	var parser := JSON.new()
	if parser.parse(text) != OK: return _error("Invalid JSON syntax")
	return Schemas.success(parser.data)

static func _valid_utf8(bytes: PackedByteArray) -> bool:
	# Native round trip detects ill-formed byte sequences without logging engine
	# decoder errors: validate high-byte runs first, skip ASCII via hex regex.
	var regex := RegEx.new()
	regex.compile("[\\x80-\\xff]")
	var latin := bytes.get_string_from_ascii()
	var cursor := 0
	while true:
		var found := regex.search(latin, cursor)
		if found == null: return true
		var i: int = found.get_start()
		var lead: int = bytes[i]
		var count := 0
		var cp := 0
		if lead >= 0xc2 and lead <= 0xdf: count = 2; cp = lead & 31
		elif lead >= 0xe0 and lead <= 0xef: count = 3; cp = lead & 15
		elif lead >= 0xf0 and lead <= 0xf4: count = 4; cp = lead & 7
		else: return false
		if i + count > bytes.size(): return false
		for offset in range(1, count):
			var part: int = bytes[i + offset]
			if part < 0x80 or part > 0xbf: return false
			cp = (cp << 6) | (part & 63)
		if (count == 3 and cp < 0x800) or (count == 4 and cp < 0x10000) or cp > 0x10ffff or (cp >= 0xd800 and cp <= 0xdfff): return false
		cursor = i + count
	return false

static func _quote(value: String) -> String:
	var text := value.replace('\\','\\\\').replace('"','\\"')
	for i in range(1,32): text = text.replace(String.chr(i), "\\u%04x" % i)
	return '"' + text + '"'

static func _int(text: Variant, minimum: int = -9223372036854775807 - 1, maximum: int = 9223372036854775807) -> Dictionary:
	if typeof(text) != TYPE_STRING or text.is_empty(): return _error("Integer text required")
	var negative: bool = text.begins_with("-")
	var digits: String = text.substr(1) if negative else text
	if digits.is_empty() or (digits.length() > 1 and digits[0] == "0") or (negative and digits == "0"): return _error("Noncanonical integer")
	for c in digits:
		if c not in "0123456789": return _error("Nondecimal integer")
	var limit := "9223372036854775808" if negative else "9223372036854775807"
	if digits.length() > 19 or (digits.length() == 19 and digits > limit): return _error("Integer overflow")
	var value: int = text.to_int()
	if value < minimum or value > maximum: return _error("Integer outside component domain")
	return Schemas.success(value)

static func _read(tree: Variant, depth: int) -> Dictionary:
	if depth > MAX_DEPTH: return _error("Wire depth limit exceeded")
	if typeof(tree) != TYPE_ARRAY or tree.is_empty() or typeof(tree[0]) != TYPE_STRING: return _error("Tagged array required")
	var tag: String = tree[0]
	var arities := {"null":1,"bool":2,"string":2,"name":2,"int":2,"f64":2,"v3i":4,"v3":4,"basis":4,"transform3d":3,"array":2,"dict":2}
	if not arities.has(tag) or tree.size() != arities[tag]: return _error("Unknown tag or arity")
	match tag:
		"null": return Schemas.success(null)
		"bool":
			return Schemas.success(tree[1]) if typeof(tree[1]) == TYPE_BOOL else _error("Bool required")
		"string", "name":
			if typeof(tree[1]) != TYPE_STRING: return _error("String required")
			return Schemas.success(StringName(tree[1]) if tag == "name" else tree[1])
		"int": return _int(tree[1])
		"f64":
			if typeof(tree[1]) != TYPE_STRING or tree[1].length() != 16: return _error("f64 bits required")
			for c in tree[1]:
				if c not in "0123456789abcdef": return _error("Noncanonical f64 hex")
			var bits: PackedByteArray = tree[1].hex_decode()
			bits.reverse()
			var value := bits.decode_double(0)
			return Schemas.success(value) if is_finite(value) else _error("Nonfinite f64")
		"v3i":
			var parts: Array = []
			for i in range(1,4):
				var part := _int(tree[i], -2147483648, 2147483647)
				if not part.ok: return part
				parts.append(part.value)
			return Schemas.success(Vector3i(parts[0],parts[1],parts[2]))
		"v3", "basis", "transform3d":
			var parts: Array = []
			for i in range(1,tree.size()):
				var part := _read(tree[i], depth + 1)
				if not part.ok: return part
				var expected: int = TYPE_FLOAT if tag == "v3" else TYPE_VECTOR3
				if tag == "transform3d" and i == 1: expected = TYPE_BASIS
				if typeof(part.value) != expected: return _error("Component type mismatch")
				parts.append(part.value)
			var value: Variant
			if tag == "v3":
				value = Vector3(parts[0],parts[1],parts[2])
				for i in 3:
					if _float_bits(value[i]) != _float_bits(parts[i]): return Schemas.failure("WIRE_PRECISION_UNSUPPORTED", "Vector component cannot round trip")
			elif tag == "basis": value = Basis(parts[0],parts[1],parts[2])
			else: value = Transform3D(parts[0],parts[1])
			return Schemas.success(value)
		"array":
			if typeof(tree[1]) != TYPE_ARRAY: return _error("Array payload required")
			var result: Array = []
			for child in tree[1]:
				var part := _read(child, depth + 1)
				if not part.ok: return part
				result.append(part.value)
			return Schemas.success(result)
		"dict":
			if typeof(tree[1]) != TYPE_ARRAY: return _error("Dictionary pairs required")
			var result := {}
			var previous := ""
			for pair in tree[1]:
				if typeof(pair) != TYPE_ARRAY or pair.size() != 2: return _error("Key/value pair required")
				var key := _read(pair[0], depth + 1)
				if not key.ok: return key
				if typeof(key.value) not in [TYPE_STRING,TYPE_STRING_NAME,TYPE_INT]: return _error("Unsupported key")
				var key_bytes: Dictionary = _encode_value(key.value)
				if not key_bytes.ok: return key_bytes
				var ordered: String = key_bytes.value.hex_encode()
				if (not previous.is_empty() and ordered <= previous) or result.has(key.value): return _error("Unsorted or duplicate decoded key")
				previous = ordered
				var part := _read(pair[1], depth + 1)
				if not part.ok: return part
				result[key.value] = part.value
			return Schemas.success(result)
	return _error("Unsupported value")

static func _float_bits(value: float) -> String:
	var bytes := PackedByteArray()
	bytes.resize(8)
	bytes.encode_double(0, value)
	bytes.reverse()
	return bytes.hex_encode()

static func _error(message: String) -> Dictionary:
	return Schemas.failure("WIRE_INVALID", message)

class Writer:
	var bytes := PackedByteArray()
	var problem := ""

	func put(text: String) -> void:
		if not problem.is_empty(): return
		var added := text.to_utf8_buffer()
		if bytes.size() + added.size() > MAX_BYTES:
			problem = "Wire byte limit exceeded"
			return
		bytes.append_array(added)

	func write(value: Variant, depth: int) -> void:
		if not problem.is_empty(): return
		if depth > MAX_DEPTH:
			problem = "Wire depth limit exceeded or cyclic value"
			return
		match typeof(value):
			TYPE_NIL: put('["null"]')
			TYPE_BOOL: put('["bool",true]' if value else '["bool",false]')
			TYPE_INT: put('["int",' + FoundationToolWire._quote(str(value)) + ']')
			TYPE_FLOAT:
				if not is_finite(value): problem = "Nonfinite float"; return
				put('["f64",' + FoundationToolWire._quote(FoundationToolWire._float_bits(value)) + ']')
			TYPE_STRING, TYPE_STRING_NAME:
				var text: String = String(value)
				# Validate Unicode scalar values without walking long ASCII strings.
				var invalid := RegEx.new()
				invalid.compile("[\\x{D800}-\\x{DFFF}]")
				if invalid.search(text) != null: problem = "Invalid Unicode scalar"; return
				put('["name",' if typeof(value) == TYPE_STRING_NAME else '["string",')
				put(FoundationToolWire._quote(text))
				put(']')
			TYPE_VECTOR3I: put('["v3i","%d","%d","%d"]' % [value.x,value.y,value.z])
			TYPE_VECTOR3, TYPE_BASIS, TYPE_TRANSFORM3D:
				var children: Array
				if typeof(value) == TYPE_VECTOR3: put('["v3",'); children = [value.x,value.y,value.z]
				elif typeof(value) == TYPE_BASIS: put('["basis",'); children = [value.x,value.y,value.z]
				else: put('["transform3d",'); children = [value.basis,value.origin]
				for i in children.size():
					if i: put(',')
					write(children[i], depth + 1)
				put(']')
			TYPE_ARRAY:
				put('["array",[')
				for i in value.size():
					if i: put(',')
					write(value[i], depth + 1)
					if not problem.is_empty(): return
				put(']]')
			TYPE_DICTIONARY:
				var keys: Array = []
				for key in value:
					if typeof(key) not in [TYPE_STRING,TYPE_STRING_NAME,TYPE_INT]: problem = "Unsupported key"; return
					var encoded: Dictionary = FoundationToolWire._encode_value(key)
					if not encoded.ok: problem = "Invalid key"; return
					keys.append([encoded.value.hex_encode(),key])
				keys.sort_custom(func(a,b): return a[0] < b[0])
				put('["dict",[')
				for i in keys.size():
					if i: put(',')
					put('[')
					write(keys[i][1], depth + 1)
					put(',')
					write(value[keys[i][1]], depth + 1)
					put(']')
					if not problem.is_empty(): return
				put(']]')
			_: problem = "Unsupported native type"
