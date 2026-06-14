class_name BallNode
extends Node3D

var ball : Ball

# Physical properties
@export var mass: float = PhysicsConstants.BALL_MASS
@export var radius: float = PhysicsConstants.BALL_RADIUS

var table : BTable

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	ball = Ball.new(get_instance_id(), Vector2(global_position.x, global_position.z))
	ball.radius = radius
	ball.mass = mass

func _process(_delta: float) -> void:
	var _s = DebugDraw3D.new_scoped_config()
	_s.set_thickness(0.002)
	DebugDraw3D.draw_sphere(global_position, 0.002, Color.DARK_RED, 0.5)
	if ball == null:
		return
	global_position = ball.position
	global_transform.basis = ball.rotation

func _notification(what):
	if Engine.is_editor_hint():
		return
	if what == NOTIFICATION_ENTER_WORLD || what == NOTIFICATION_PARENTED:
		var look4table = self
		while true:
			look4table = look4table.get_parent()
			if look4table != null && look4table is BTable:
				break
			else:
				look4table = null
				break
		if look4table != null && table != look4table:
			table = look4table
			table.balls.append(self)
	elif what == NOTIFICATION_EXIT_WORLD || what == NOTIFICATION_UNPARENTED:
		if table != null:
			var pos = table.balls.find(self)
			if pos >= 0:
				table.balls.remove_at(pos)
				table = null
