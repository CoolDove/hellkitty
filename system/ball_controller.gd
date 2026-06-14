extends Node
class_name BallController

## Ball controller for new physics system
## Can be reparented to control different BallNode instances

var ball_node : BallNode  # The 3D node we're controlling
var ball : Ball:  # The physics ball instance
	get:
		return ball_node.ball if ball_node else null

@onready var game : Game = find_parent("Game")

var _camera : Camera3D
var _stick : Node3D
var _spin_panel

var _force_bar : ProgressBar

# var ray : RayCast3D

var _aiming : bool = false
var _aim_to_point : Vector3

var _hit_queued : bool
var _hit_direction : Vector3
var _hit_force : float

func _ready():
	# ray = RayCast3D.new()
	await get_tree().process_frame
	# get_tree().root.add_child(ray)
	ball_node = get_parent() as BallNode
	_camera = get_viewport().get_camera_3d()
	_stick = game.stick
	_spin_panel = game.spin_panel
	print("BallController ready, controlling: ", ball_node.name if ball_node else "none")

func _notification(what):
	if what == NOTIFICATION_PARENTED:
		ball_node = get_parent() as BallNode
		print("Controller changed to: ", ball_node.name if ball_node else "none")

func _process(delta):
	if ball_node == null or ball == null:
		return

	if _aiming:
		_stick.global_position = ball_node.global_position - (_aim_to_point - ball_node.global_position).normalized() * 0.2
		_stick.look_at(ball_node.global_position)
	
	_hit_direction = _aim_to_point - ball_node.global_position
	_hit_force = clamp(_hit_direction.length(), 0.01, 1.5)
	
	if _force_bar != null:
		_force_bar.min_value = 0.01
		_force_bar.max_value = 1.5
		_force_bar.value = _hit_force
	
	if _input_shoot && !_hit_queued && _stick.visible:
		_hit_queued = true
		_hit_direction = _hit_direction.normalized()
		_control_end()
	
	# Right click to switch controlled ball
	# if Input.is_action_just_pressed("click_right"):
	# 	if ray.is_colliding():
	# 		var target = ray.get_collider() as Node
	# 		if target is BallNode:
	# 			reparent(target)
	
	_input_shoot = false

func _physics_process(delta):
	if ball_node == null or ball == null:
		return
	
	# Execute queued shot
	if _hit_queued:
		var spin : Vector2 = _spin_panel.get_hit_offset()
		print("Shot!")
		print("  Force: ", _hit_force)
		print("  Spin: ", spin)
		
		# Calculate shot based on game.gd implementation
		var shot_dir := _hit_direction.normalized()
		var shot_speed := _hit_force * 4.0  # Convert force to speed
		
		# Apply linear velocity
		ball.velocity = shot_dir * shot_speed
		
		# Apply spin based on hit offset (from game.gd)
		var r := ball.radius
		var max_offset := r * 0.7  # Can't hit too close to edge (miscue)
		
		# Hit point offset in ball's local space
		var right_dir := Vector3(shot_dir.z, 0, -shot_dir.x)  # Perpendicular to shot in XZ plane
		var up_dir := Vector3.UP
		
		# Contact point relative to ball center
		var contact_offset := right_dir * (spin.x * max_offset) + up_dir * (spin.y * max_offset)
		
		# Cue force direction
		var impulse_magnitude := shot_speed * ball.mass
		var cue_force := shot_dir * impulse_magnitude
		
		# Torque = r × F, angular impulse = torque (instantaneous)
		var angular_impulse := contact_offset.cross(cue_force)
		
		# Apply angular velocity change: Δω = angular_impulse / I
		ball.angular_velocity += angular_impulse / ball.inertia
		
		print("  Result: velocity=%s, spin=%s" % [ball.velocity, ball.angular_velocity])
		
		_hit_queued = false
		_spin_panel.reset_hit_offset()
		return
	
	# Only allow aiming when ball is not moving
	# if is_instance_valid(ray) && ray.is_inside_tree() && !ball.is_moving():
	if !ball.is_moving() && _stick != null:
		if !_stick.visible:
			_control_begin()

		var mpos := get_viewport().get_mouse_position()
		var origin := _camera.project_ray_origin(mpos)
		var dir := _camera.project_ray_normal(mpos)
		# ray.global_position = origin
		# ray.target_position = dir * 100

		var plane = Plane(Vector3.UP, 0.0)
		var intersects = plane.intersects_ray(origin, dir)
		
		if intersects != null:
			_aiming = true
			_aim_to_point = intersects
			_aim_to_point.y = ball_node.global_position.y
		else:
			_aiming = false

func _control_begin():
	_stick.show()
	_force_bar = game.force_bar

func _control_end():
	_force_bar = null
	_stick.hide()

var _input_shoot : bool
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && !event.pressed:
			_input_shoot = true
