extends SceneTree
var failures: Array[String] = []
var checks := 0
func check(value: bool, label: String) -> void:
 checks += 1
 if not value: failures.append(label)
func _initialize() -> void:
 call_deferred("run")
func frames(count: int) -> void:
 for i in count: await process_frame
func run() -> void:
 var path := "res://game/shell/visual_02/character_backdrop.gd"
 check(ResourceLoader.exists(path), "native backdrop exists")
 if not ResourceLoader.exists(path):
  finish()
  return
 var view = load(path).new()
 root.add_child(view)
 view.size = Vector2(1280,720)
 await frames(3)
 var state: Dictionary = view.debug_state()
 check(state.model_path.ends_with("BG_CH_WAKABA_CUBE_001.glb"), "surface uses approved Wakaba")
 check(view.get_node("Viewport/Stage/Character/Model").get_child_count() > 0, "production model is instantiated")
 check(not has_physics(view), "display scene contains no physics bodies or shapes")
 check(absf(lowest_mesh(view.get_node("Viewport/Stage/Character/Model"))) < 0.001, "actual transformed model stays grounded")
 var pose: Transform3D = state.pose
 await frames(8)
 check(not pose.is_equal_approx(view.debug_state().pose), "idle moves on real process frames")
 check(absf(lowest_mesh(view.get_node("Viewport/Stage/Character/Model"))) < 0.001, "moving model retains ground contact")
 view.request_motion("lean")
 await create_timer(0.65).timeout
 var leaning: Transform3D = view.debug_state().pose
 check(absf(leaning.basis.get_euler().z) > 0.03, "lean request visibly tilts the actual model")
 check(absf(lowest_mesh(view.get_node("Viewport/Stage/Character/Model"))) < 0.001, "requested lean retains ground contact")
 await create_timer(1.0).timeout
 var settled: Transform3D = view.debug_state().pose
 check(absf(settled.basis.get_euler().z) < 0.02, "lean settles back into restrained idle")
 view.set_active(false)
 pose = view.debug_state().pose
 await frames(5)
 check(pose.is_equal_approx(view.debug_state().pose), "inactive freezes pose")
 check(not view.is_processing() and view.get_node("Viewport").render_target_update_mode == SubViewport.UPDATE_DISABLED, "inactive disables processing and rendering")
 view.set_active(true)
 await frames(8)
 check(not pose.is_equal_approx(view.debug_state().pose), "reactivation resumes motion")
 view.set_reduced_motion(true)
 pose = view.debug_state().pose
 view.request_motion("turn")
 await frames(8)
 check(pose.is_equal_approx(view.debug_state().pose), "reduced motion freezes both idle and requests")
 for i in 12:
  view.set_world_layer(i % 2)
  view.request_motion("lean")
 check(view.debug_state().model_path.ends_with("BG_CH_MORTIS_CUBE_001.glb"), "inner uses approved Mortis")
 check(view.get_node("Viewport/Stage/Character").get_child_count() == 1, "rapid switching retains one model")
 view.hide()
 await frames(2)
 check(not view.is_processing(), "hidden backdrop suspends")
 view.show()
 view.set_reduced_motion(false)
 await frames(3)
 check(view.is_processing(), "visible backdrop resumes")
 view.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
 await frames(2)
 check(not view.is_processing(), "window blur suspends")
 view.notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN)
 await frames(2)
 check(view.is_processing(), "focus resumes")
 for dimensions in [Vector2(960,720),Vector2(1280,720),Vector2(1920,1080)]:
  view.size = dimensions
  await frames(2)
  check(view.get_node("Viewport").size == Vector2i(dimensions), "viewport follows %s" % dimensions)
 view.queue_free()
 await frames(2)
 check(not is_instance_valid(view), "cleanup releases backdrop")
 finish()
func finish() -> void:
 print(JSON.stringify({"checks":checks,"failures":failures,"scope":"HEADLESS_LIFECYCLE_NOT_VISUAL_QA"}))
 quit(0 if failures.is_empty() else 1)
func has_physics(node: Node) -> bool:
 if node is CollisionObject3D or node is CollisionShape3D: return true
 for child in node.get_children():
  if has_physics(child): return true
 return false
func lowest_mesh(node: Node) -> float:
 var lowest := INF
 if node is MeshInstance3D:
  lowest = (node.global_transform * node.get_aabb()).position.y
 for child in node.get_children():
  lowest = minf(lowest, lowest_mesh(child))
 return lowest
