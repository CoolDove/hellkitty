extends Node3D

## Demo scene for billiard physics
## This demonstrates how to use the physics engine in Godot

var physics: BilliardPhysics
var scale_factor: float = 400.0  # Pixels per meter

# Visual settings
var ball_colors: Array[Color] = [
	Color.WHITE,      # 0: Cue ball
	Color.YELLOW,     # 1
	Color.BLUE,       # 2
	Color.RED,        # 3
	Color.PURPLE,     # 4
	Color.ORANGE,     # 5
	Color.GREEN,      # 6
	Color.MAROON,     # 7
	Color.BLACK,      # 8
]

var table_color := Color(0.0, 0.4, 0.0)  # Green felt
var cushion_color := Color(0.4, 0.2, 0.1)  # Brown wood

func _ready() -> void:
	# Create physics engine with table
	var table := Table.new(2.54, 1.27)  # Standard pool table size
	physics = BilliardPhysics.new(table)
	# Connect signals
	physics.ball_ball_collision.connect(_on_ball_ball_collision)
	physics.ball_wall_collision.connect(_on_ball_wall_collision)
	# Setup initial ball positions
	_setup_balls()

func _setup_balls() -> void:
	physics.clear_balls()

	var balls := get_tree().get_nodes_in_group("balls")
	for ball in balls:
		physics.add_ball(ball.ball)

	# Cue ball
	#var cue := Ball.new(0, Vector2(-0.6, 0.0))
	#physics.add_ball(cue)
	#
	## Rack balls in triangle formation
	#var start_x := 0.5
	#var start_y := 0.0
	#var d := PhysicsConstants.BALL_DIAMETER * 1.02  # Slight gap
	#
	#var rack_positions: Array[Vector2] = [
		#Vector2(start_x, start_y),  # 1
		#Vector2(start_x + d * 0.866, start_y - d * 0.5),  # 2
		#Vector2(start_x + d * 0.866, start_y + d * 0.5),  # 3
		#Vector2(start_x + d * 1.732, start_y - d),  # 4
		#Vector2(start_x + d * 1.732, start_y),  # 5 (8-ball position)
		#Vector2(start_x + d * 1.732, start_y + d),  # 6
		#Vector2(start_x + d * 2.598, start_y - d * 1.5),  # 7
		#Vector2(start_x + d * 2.598, start_y - d * 0.5),  # 8
		#Vector2(start_x + d * 2.598, start_y + d * 0.5),  # 9
	#]
	
	#for i in range(rack_positions.size()):
		#var ball := Ball.new(i + 1, rack_positions[i])
		#physics.add_ball(ball)


func _process(delta: float) -> void:
	physics.step(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_shoot_cue_ball(event.position)
	
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_R:
			_setup_balls()  # Reset

func screen_pos_to_world_z0(position: Vector2, camera: Camera3D) -> Vector3:
	var origin = camera.project_ray_origin(position)
	var dir = camera.project_ray_normal(position)
	var plane = Plane(Vector3.UP, 0.0)
	return plane.intersects_ray(origin, dir)

func _shoot_cue_ball(mouse_pos: Vector2) -> void:
	var wpos := screen_pos_to_world_z0(mouse_pos, get_viewport().get_camera_3d())
	print("wpos: ", wpos)
	if physics.is_simulation_active():
		return  # Don't shoot while balls are moving

	var cue_ball := physics.balls[0]
	var direction := wpos - cue_ball.position
	cue_ball.velocity = direction * 4
	print("velocity: ", direction)

func _on_ball_ball_collision(ball1: Ball, ball2: Ball, strength: float) -> void:
	# Play collision sound here
	print("Ball %d hit Ball %d (strength: %.2f)" % [ball1.ball_number, ball2.ball_number, strength])


func _on_ball_wall_collision(ball: Ball, strength: float) -> void:
	# Play cushion sound here
	print("Ball %d hit cushion (strength: %.2f)" % [ball.ball_number, strength])
