@tool
extends Node3D
class_name BTable

var colliders : Array[ColliderNode]
var balls : Array[BallNode]

var physics: BilliardPhysics

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	print("btable ready")
	print("\tcolliders count: %s" % colliders.size())
	print("\tballs count: %s" % balls.size())

	physics = BilliardPhysics.new()

	physics.clear_balls()

	for ball in balls:
		physics.add_ball(ball.ball)

	for collider_node in colliders:
		physics.add_collider(collider_node.collider)

	physics.ball_ball_collision.connect(func(ball1: Ball, ball2: Ball, strength: float):
		var _sconfig := DebugDraw3D.new_scoped_config().set_thickness(0.01)
		var hitpoint := 0.5 * (ball1.position + ball2.position)
		DebugDraw3D.draw_arrow_ray(hitpoint, (ball1.position - hitpoint).normalized(), strength * 0.1, Color.ORANGE, 0.04, false, 1.0)
		DebugDraw3D.draw_arrow_ray(hitpoint, (ball2.position - hitpoint).normalized(), strength * 0.1, Color.ORANGE, 0.04, false, 1.0)
	)

	physics.ball_collider_collision.connect(func(ball: Ball, collider: Collider, strength: float, normal: Vector3):
		var _sconfig := DebugDraw3D.new_scoped_config().set_thickness(0.01)
		DebugDraw3D.draw_arrow_ray(ball.position, normal, strength * 0.1, Color.RED, 0.04, false, 1.0)
	)


func register_collider(collider: ColliderNode):
	colliders.append(collider)
	print("register collider: ", collider.get_path_to(self))

func unregister_collider(collider: ColliderNode):
	var pos = colliders.find(collider)
	if pos >= 0:
		colliders.remove_at(pos)
	print("unregister collider: ", collider.get_path_to(self))

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	physics.step(delta)
