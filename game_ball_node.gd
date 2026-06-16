extends BallNode
class_name GameBallNode

@onready var mesh :MeshInstance3D= %BallMesh.mesh


const COLOR_TEAM_A : Color = Color.CYAN 
const COLOR_TEAM_B : Color = Color.YELLOW

@export var team : Game.TeamFlag = Game.TeamFlag.A :
	set(value):
		team = value
		if is_node_ready():
			_set_ball_color(_get_team_color(team))

func _notification(what):
	if what == NOTIFICATION_READY:
		_set_ball_color(_get_team_color(team))

func _set_ball_color(color: Color):
	mesh.set_instance_shader_parameter("tint_color", color)
	print("set color to %s" % color)

func _get_team_color(team: Game.TeamFlag):
	return COLOR_TEAM_A if team == Game.TeamFlag.A else COLOR_TEAM_B
