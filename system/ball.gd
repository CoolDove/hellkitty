extends RigidBody3D
class_name HBall

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

var trail_record_interval : float
var trail_remove_interval : float
func _process(delta):
	trail_record_interval -= delta
	if trail_record_interval <= 0:
		trail_record_interval = 0.02
		var record :bool= false
		var point_count :int= trail.get_point_count()
		var new_point := _camera.unproject_position(global_position)
		if point_count == 0:
			record = true
		else:
			record = new_point.distance_squared_to(
				trail.get_point_position(point_count-1)
			) > 0.02
		if record: trail.add_point(new_point)
	if linear_velocity.length_squared() < 0.04:
		trail_remove_interval -= delta
	if trail_remove_interval <= 0:
		trail_remove_interval = 0.2
		trail.remove_point(0)

func _physics_process(delta):
	if angular_velocity.length() > 0.01:
		var normal = Vector3.UP
		var radius = 0.028
		var v_contact = linear_velocity - angular_velocity.cross(normal) * radius
		v_contact = v_contact.slide(normal)
		var k = 0.15
		var force = -v_contact * k
		apply_central_force(force)
