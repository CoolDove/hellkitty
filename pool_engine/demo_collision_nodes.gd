## Demo scene showing how to use BilliardCollision2D nodes with different shapes
## 
## This version uses a single BilliardCollision2D node class that supports
## multiple collision shapes (rect, circle) through configuration.

extends Node

@onready var spin_panel := %SpinPanel
@onready var world := %World3D

## Physics engine
var physics: BilliardPhysics

## Table dimensions
var table_width: float = 2.54   # meters
var table_depth: float = 1.27   # meters
var wall_thickness: float = 0.05  # meters

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
	# Create physics engine
	var table := Table.new(table_width, table_depth)
	physics = BilliardPhysics.new(table)
	
	# Connect signals
	physics.ball_ball_collision.connect(_on_ball_ball_collision)
	physics.ball_wall_collision.connect(_on_ball_wall_collision)
	
	# Create collision nodes for the table walls
	_setup_collision_nodes()
	
	# Setup initial ball positions
	_setup_balls()


## Create collision nodes representing the table boundaries
func _setup_collision_nodes() -> void:
	var half_w := table_width / 2.0
	var half_d := table_depth / 2.0
	
	# Left wall (x-min, normal points +X into table)
	var left_wall := BilliardCollision2D.new()
	left_wall.name = "LeftWall"
	left_wall.shape_type = BilliardCollision2D.ShapeType.RECT
	left_wall.position_2d = Vector2(-half_w, 0)
	left_wall.rect_half_x = wall_thickness
	left_wall.rect_half_z = half_d + wall_thickness
	left_wall.rect_normal = Vector3(1, 0, 0)  # Points +X into table
	world.add_child(left_wall)
	physics.add_collision_node(left_wall)
	
	# Right wall (x+max, normal points -X into table)
	var right_wall := BilliardCollision2D.new()
	right_wall.name = "RightWall"
	right_wall.shape_type = BilliardCollision2D.ShapeType.RECT
	right_wall.position_2d = Vector2(half_w, 0)
	right_wall.rect_half_x = wall_thickness
	right_wall.rect_half_z = half_d + wall_thickness
	right_wall.rect_normal = Vector3(-1, 0, 0)  # Points -X into table
	world.add_child(right_wall)
	physics.add_collision_node(right_wall)
	
	# Bottom wall (z-min, normal points +Z into table)
	var bottom_wall := BilliardCollision2D.new()
	bottom_wall.name = "BottomWall"
	bottom_wall.shape_type = BilliardCollision2D.ShapeType.RECT
	bottom_wall.position_2d = Vector2(0, -half_d)
	bottom_wall.rect_half_x = half_w + wall_thickness
	bottom_wall.rect_half_z = wall_thickness
	bottom_wall.rect_normal = Vector3(0, 0, 1)  # Points +Z into table
	world.add_child(bottom_wall)
	physics.add_collision_node(bottom_wall)
	
	# Top wall (z+max, normal points -Z into table)
	var top_wall := BilliardCollision2D.new()
	top_wall.name = "TopWall"
	top_wall.shape_type = BilliardCollision2D.ShapeType.RECT
	top_wall.position_2d = Vector2(0, half_d)
	top_wall.rect_half_x = half_w + wall_thickness
	top_wall.rect_half_z = wall_thickness
	top_wall.rect_normal = Vector3(0, 0, -1)  # Points -Z into table
	world.add_child(top_wall)
	physics.add_collision_node(top_wall)
	
	print("Collision nodes created: ", physics.collision_nodes.size())


func _setup_balls() -> void:
	physics.clear_balls()
	
	var balls := get_tree().get_nodes_in_group("balls")
	for ball in balls:
		physics.add_ball(ball.ball)


func _process(delta: float) -> void:
	physics.step(delta)


func _unhandled_input(event: InputEvent) -> void:
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
	
	if physics.is_simulation_active():
		return  # Don't shoot while balls are moving
	
	var hit_offset: Vector2 = spin_panel.get_hit_offset()
	var cue_ball := physics.balls[0]
	var direction := wpos - cue_ball.position
	direction.y = 0.0
	var shot_dir := direction.normalized()
	var shot_speed := direction.length() * 4
	
	# Apply cue ball velocity
	cue_ball.velocity = shot_dir * shot_speed
	
	var r := cue_ball.radius
	var max_offset := r * 0.7  # Can't hit too close to edge (miscue)
	
	# Hit point offset in ball's local space
	var right_dir := Vector3(shot_dir.z, 0, -shot_dir.x)  # Perpendicular to shot in XZ plane
	var up_dir := Vector3.UP
	
	# Contact point relative to ball center
	var contact_offset := right_dir * (hit_offset.x * max_offset) + up_dir * (hit_offset.y * max_offset)
	
	# Cue force direction (along shot direction)
	var impulse_magnitude := shot_speed * cue_ball.mass
	var cue_force := shot_dir * impulse_magnitude
	
	# Torque = r × F, angular impulse = torque (instantaneous)
	var angular_impulse := contact_offset.cross(cue_force)
	
	# Apply angular velocity change: Δω = angular_impulse / I
	cue_ball.angular_velocity += angular_impulse / cue_ball.inertia
	
	print("Shot: dir=%s, speed=%.2f, offset=%s, spin=%s" % [shot_dir, shot_speed, hit_offset, cue_ball.angular_velocity])
	spin_panel.reset_hit_offset()


func _on_ball_ball_collision(ball1: Ball, ball2: Ball, strength: float) -> void:
	# Play collision sound here
	print("Ball %d hit Ball %d (strength: %.2f)" % [ball1.ball_number, ball2.ball_number, strength])


func _on_ball_wall_collision(ball: Ball, strength: float) -> void:
	# Play cushion sound here
	print("Ball %d hit cushion (strength: %.2f)" % [ball.ball_number, strength])
