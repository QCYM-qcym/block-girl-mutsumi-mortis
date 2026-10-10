extends RefCounted
## Fixed orthographic observation basis, independent of viewport/zoom/renderer.
## Logical projection numerators; positive screen_v means screen descent.
const VERSION = "game_feel.orthographic.v1"
const RIGHT = [Vector3i(1,0,-1),Vector3i(1,0,1),Vector3i(-1,0,1),Vector3i(-1,0,-1)]
const DOWN = [Vector3i(2,-3,2),Vector3i(-2,-3,2),Vector3i(-2,-3,-2),Vector3i(2,-3,-2)]
static func project(point: Vector3i, quadrant: int) -> Vector2i:
	# Path coordinates are bounded to ±1e6 by DATA; both products fit int32.
	return Vector2i(_dot(point,RIGHT[quadrant]),_dot(point,DOWN[quadrant]))
static func basis(quadrant: int) -> Basis:
	var right := Vector3(RIGHT[quadrant]).normalized()
	var up := -Vector3(DOWN[quadrant]).normalized()
	return Basis(right,up,right.cross(up))
static func descending(points: Array, quadrant: int) -> bool:
	var first := project(points[0],quadrant)
	var previous := first
	for point in points.slice(1):
		var next := project(point,quadrant)
		if next.x != first.x or next.y <= previous.y: return false
		previous = next
	return true

static func _dot(a: Vector3i, b: Vector3i) -> int:
	return int(a.x)*int(b.x)+int(a.y)*int(b.y)+int(a.z)*int(b.z)
