extends BallNode
class_name GameBallNode

@onready var mesh :MeshInstance3D= %BallMesh.mesh

@export var team : Game.TeamFlag = Game.TeamFlag.Blue :
	set(value):
		team = value
		if is_node_ready():
			_set_ball_color(Color.BLUE if team == Game.TeamFlag.Blue else Color.YELLOW)

func _notification(what):
	if what == NOTIFICATION_READY:
		_set_ball_color(Color.BLUE if team == Game.TeamFlag.Blue else Color.YELLOW)

func _set_ball_color(color: Color):
	mesh.set_instance_shader_parameter("tint_color", color)
	print("set color to %s" % color)
