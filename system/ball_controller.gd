extends Node
class_name BallController

var ball : HBall

var _camera :Camera3D
var _stick :Node3D
var _spin_panel

var ray : RayCast3D

var _aiming :bool= false
var _aim_to_point : Vector3

var _hit_queued :bool
var _hit_direction :Vector3
var _hit_force :float

func _ready():
	ray = RayCast3D.new()
	await get_tree().process_frame
	get_tree().root.add_child(ray)
	ball = get_parent() as HBall
	_camera = Billiards.instance.camera
	_stick = Billiards.instance.stick
	_spin_panel = Billiards.instance.spin_panel

func _notification(what):
	if what == NOTIFICATION_PARENTED:
		ball = get_parent() as HBall
		print("controller changed")

func _process(delta):
	if _aiming:
		_stick.global_position = ball.global_position - (_aim_to_point - ball.global_position).normalized() * 0.2
		_stick.look_at(ball.global_position)
	if _input_shoot && !_hit_queued && _stick.visible:
		_hit_queued = true
		_hit_direction = _aim_to_point - ball.global_position
		_hit_force = _hit_direction.length()
		_hit_direction = _hit_direction.normalized()
		_stick.hide()
	if Input.is_action_just_pressed("click_right"):
		var balls := get_tree().get_nodes_in_group("ball")
		if balls.size() > 0:
			if ray.is_colliding():
				var target = ray.get_collider() as Node
				if target.is_in_group("ball"):
					reparent(target)
	_input_shoot = false

func _physics_process(delta):
	if _hit_queued:
		var spin :Vector2= _spin_panel.get_hit_offset()
		print("spin: ", spin)
		ball.apply_impulse(_hit_direction * _hit_force, Vector3(spin.x * 0.028, spin.y * 0.028, 0))
		_hit_queued = false
		_spin_panel.reset_offset()
		return
	if is_instance_valid(ray) && ray.is_inside_tree() && ball.sleeping:
		if !_stick.visible: _stick.show()
		var mpos := get_viewport().get_mouse_position()
		var origin := _camera.project_ray_origin(mpos)
		var dir := _camera.project_ray_normal(mpos)
		ray.global_position = origin
		ray.target_position = dir * 100
		if ray.is_colliding():
			_aiming = true
			_aim_to_point = ray.get_collision_point()
			_aim_to_point.y = ball.global_position.y
		else:
			_aiming = false

var _input_shoot : bool
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && !event.pressed:
			_input_shoot = true
