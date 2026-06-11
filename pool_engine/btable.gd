@tool
extends Node3D
class_name BTable

var collisions : Array[CollisionNode]
var balls : Array[BallNode]

var physics: BilliardPhysics

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	print("btable ready")
	print("\tcollisions count: %s" % collisions.size())
	print("\tballs count: %s" % balls.size())

	var table := Table.new(2.54, 1.27)  # Standard pool table size
	physics = BilliardPhysics.new(table)

	physics.clear_balls()

	for ball in balls:
		physics.add_ball(ball.ball)

	for collision in collisions:
		physics.add_collision(collision)

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	physics.step(delta)
