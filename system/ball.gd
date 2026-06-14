extends RigidBody3D
class_name HBall

@export var color : Color

var _camera :Camera3D
var trail :Line2D

var radius :float= 0.

func _ready():
	trail = Line2D.new()
	trail.width = 2
	trail.default_color = Color.INDIAN_RED
	contact_monitor = true
	max_contacts_reported = 1

	await get_tree().process_frame
	get_tree().root.add_child(trail)
	_camera = Billiards.instance.camera

func _process(delta):
	DebugDraw3D.draw_sphere(global_position, 0.01, Color.DARK_RED)

func _physics_process(delta):
	if angular_velocity.length() > 0.01:
		var normal = Vector3.UP
		var radius = 0.028
		var v_contact = linear_velocity - angular_velocity.cross(normal) * radius
		v_contact = v_contact.slide(normal)
		var k = 0.1
		var force = -v_contact * k
		apply_central_force(force)


func _on_body_entered(body):
	if body is HBall:
		print("ball hit: ", body.name)
