class_name BallNode
extends Node3D

var ball : Ball

# Physical properties
@export var mass: float = PhysicsConstants.BALL_MASS
@export var radius: float = PhysicsConstants.BALL_RADIUS

var trail :Line2D

func _ready() -> void:
	ball = Ball.new(get_instance_id(), Vector2(global_position.x, global_position.z))
	ball.radius = radius
	ball.mass = mass
	
	trail = Line2D.new()
	trail.width = 2
	trail.default_color = Color.INDIAN_RED

	ball.ball_collision.connect(func(another: Ball, strength: float):
		trail_record_interval = 0
		print("manual record point")
	)
	ball.wall_collision.connect(func(strength: float):
		trail_record_interval = 0
		print("manual record point")
	)

	await get_tree().process_frame
	get_tree().root.add_child(trail)

var trail_record_interval : float
var trail_remove_interval : float
func _process(delta: float) -> void:
	trail_record_interval -= delta
	if trail_record_interval <= 0:
		trail_record_interval = 0.02
		var record :bool= false
		var point_count :int= trail.get_point_count()
		var new_point := get_viewport().get_camera_3d().unproject_position(global_position)
		if point_count == 0:
			record = true
		else:
			record = new_point.distance_squared_to(
				trail.get_point_position(point_count-1)
			) > 0.02
		if record:
			trail.add_point(new_point)

	if ball.velocity.length_squared() < 0.04:
		trail_remove_interval -= delta
	if trail_remove_interval <= 0:
		trail_remove_interval = 0.2
		trail.remove_point(0)

	if ball == null:
		return
	global_position = ball.position
	global_transform.basis = ball.rotation
