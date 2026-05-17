extends RigidBody3D

var _camera :Camera3D
var _stick :Node3D
var _debug_ball :MeshInstance3D

var ray : RayCast3D

var _aiming :bool= false
var _aim_from_point : Vector3

var _hit_queued :bool
var _hit_direction :Vector3
var _hit_force :float

func _ready():
	_camera = get_node("../Camera3D")
	_stick = get_node("../stick")
	_debug_ball = get_node("../debug_ball")
	ray = RayCast3D.new()
	await get_tree().process_frame
	get_tree().root.add_child(ray)

func _process(delta):
	if _aiming:
		_stick.global_position = _aim_from_point
		_stick.look_at(global_position)
	if Input.is_action_just_pressed("click") && !_hit_queued:
		_hit_queued = true
		_hit_direction = global_position - _aim_from_point
		_hit_force = _hit_direction.length()
		_hit_direction = _hit_direction.normalized()

func _physics_process(delta):
	if _hit_queued:
		apply_impulse(_hit_direction * _hit_force)
		apply_torque_impulse(Vector3.UP * 100)
		_hit_queued = false
		return
	if is_instance_valid(ray) && ray.is_inside_tree():
		var mpos := get_viewport().get_mouse_position()
		var origin := _camera.project_ray_origin(mpos)
		var dir := _camera.project_ray_normal(mpos)
		ray.global_position = origin
		ray.target_position = dir * 100
		if ray.is_colliding():
			_aiming = true
			_aim_from_point = ray.get_collision_point()
			_aim_from_point.y = global_position.y
			_debug_ball.global_position = ray.get_collision_point()
		else:
			_aiming = false
