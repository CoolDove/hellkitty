class_name BallNode
extends Node3D

var ball : Ball

# Physical properties
@export var mass: float = PhysicsConstants.BALL_MASS
@export var radius: float = PhysicsConstants.BALL_RADIUS

func _ready() -> void:
	ball = Ball.new(get_instance_id(), Vector2(global_position.x, global_position.z))
	ball.radius = radius
	ball.mass = mass

func _process(delta: float) -> void:
	if ball == null:
		return
	global_position = ball.position
	global_transform.basis = ball.rotation
