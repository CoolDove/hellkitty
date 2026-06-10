## Scene manager for billiard collision testing
## Handles collision node setup and visualization

class_name BilliardSceneManager
extends Node3D

@onready var world := %World3D
@onready var spin_panel := %SpinPanel

var physics: BilliardPhysics
var ball_nodes: Array[Node3D] = []
var collision_nodes: Array[BilliardCollision2D] = []

# Debug visualization
var debug_enabled := true
var collision_visual_meshes: Dictionary = {}  # collision_node -> MeshInstance3D


func _ready() -> void:
	# Create physics engine
	var table := Table.new(2.54, 1.27)
	physics = BilliardPhysics.new(table)
	
	# Connect signals
	physics.ball_ball_collision.connect(_on_ball_ball_collision)
	physics.ball_wall_collision.connect(_on_ball_wall_collision)
	
	# Setup scene
	_setup_collision_nodes()
	_setup_ball_nodes()
	
	print("✅ Scene initialized: %d collision nodes, %d balls" % [
		collision_nodes.size(),
		ball_nodes.size()
	])


## Create all collision nodes (4 walls + optional pockets)
func _setup_collision_nodes() -> void:
	var half_w = 1.27
	var half_d = 0.635
	
	# Left wall
	_add_collision_node(
		"LeftWall",
		BilliardCollision2D.ShapeType.RECT,
		Vector2(-half_w, 0),
		Vector3(1, 0, 0),
		0.05, 0.635, 0.05
	)
	
	# Right wall
	_add_collision_node(
		"RightWall",
		BilliardCollision2D.ShapeType.RECT,
		Vector2(half_w, 0),
		Vector3(-1, 0, 0),
		0.05, 0.635, 0.05
	)
	
	# Bottom wall
	_add_collision_node(
		"BottomWall",
		BilliardCollision2D.ShapeType.RECT,
		Vector2(0, -half_d),
		Vector3(0, 0, 1),
		1.27, 0.05, 0.05
	)
	
	# Top wall
	_add_collision_node(
		"TopWall",
		BilliardCollision2D.ShapeType.RECT,
		Vector2(0, half_d),
		Vector3(0, 0, -1),
		1.27, 0.05, 0.05
	)


## Add a single collision node with optional visualization
func _add_collision_node(
	name: String,
	shape_type: BilliardCollision2D.ShapeType,
	position_2d: Vector2,
	normal_or_unused: Vector3,
	param_x: float,
	param_y: float,
	param_z: float = 0.0
) -> BilliardCollision2D:
	
	var node = BilliardCollision2D.new()
	node.name = name
	node.shape_type = shape_type
	node.position_2d = position_2d
	
	match shape_type:
		BilliardCollision2D.ShapeType.RECT:
			node.rect_half_x = param_x
			node.rect_half_z = param_y
			node.rect_normal = normal_or_unused
		
		BilliardCollision2D.ShapeType.CIRCLE:
			node.circle_radius = param_x

	world.add_child(node)
	collision_nodes.append(node)
	physics.add_collision_node(node)
	
	# Create visualization
	if debug_enabled:
		_create_collision_visual(node)
	
	return node


## Create visual mesh for collision node (for debugging)
func _create_collision_visual(collision_node: BilliardCollision2D) -> void:
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.name = collision_node.name + "_Visual"
	
	match collision_node.shape_type:
		BilliardCollision2D.ShapeType.RECT:
			_create_rect_visual(mesh_instance, collision_node)
		BilliardCollision2D.ShapeType.CIRCLE:
			_create_circle_visual(mesh_instance, collision_node)
	
	collision_node.add_child(mesh_instance)
	collision_visual_meshes[collision_node] = mesh_instance


## Create visual mesh for rectangular collision
func _create_rect_visual(mesh_instance: MeshInstance3D, collision_node: BilliardCollision2D) -> void:
	var size = Vector2(
		collision_node.rect_half_x * 2.0,
		collision_node.rect_half_z * 2.0
	)
	
	var mesh = QuadMesh.new()
	mesh.size = size
	
	# Create material with transparency
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(1, 0.5, 0, 0.3)  # Orange with transparency
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	mesh.material = material
	mesh_instance.mesh = mesh


## Create visual mesh for circular collision
func _create_circle_visual(mesh_instance: MeshInstance3D, collision_node: BilliardCollision2D) -> void:
	# Create a simple circular wireframe using a torus or cylinder
	var mesh = CylinderMesh.new()
	mesh.height = 0.01  # Very thin
	mesh.top_radius = collision_node.circle_radius
	mesh.bottom_radius = collision_node.circle_radius
	
	# Create material
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	
	material.albedo_color = Color(1, 0, 0, 0.3)  # Red for sink (pocket)
	
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material = material
	mesh_instance.mesh = mesh


## Get all ball nodes from the scene
func _setup_ball_nodes() -> void:
	var balls = get_tree().get_nodes_in_group("balls")
	for ball in balls:
		if ball is BallNode:
			ball_nodes.append(ball)
			physics.add_ball(ball.ball)
	
	print("  Found %d ball nodes" % ball_nodes.size())


## Main physics loop
func _process(delta: float) -> void:
	physics.step(delta)


## Handle ball-ball collision
func _on_ball_ball_collision(ball1: Ball, ball2: Ball, strength: float) -> void:
	print("⚽ Ball %d ↔ Ball %d (strength: %.2f)" % [ball1.ball_number, ball2.ball_number, strength])


## Handle ball-wall collision
func _on_ball_wall_collision(ball: Ball, strength: float) -> void:
	print("🧱 Ball %d ↔ Wall (strength: %.2f)" % [ball.ball_number, strength])


## Reset scene
func reset_scene() -> void:
	for ball_node in ball_nodes:
		ball_node.ball.position = Vector3.ZERO
		ball_node.ball.velocity = Vector3.ZERO
		ball_node.ball.angular_velocity = Vector3.ZERO
		ball_node.global_position = ball_node.ball.position
	
	print("🔄 Scene reset")


## Toggle collision visualization
func toggle_debug_visualization() -> void:
	debug_enabled = !debug_enabled
	for mesh_instance in collision_visual_meshes.values():
		mesh_instance.visible = debug_enabled
	print("🎨 Debug visualization: %s" % ("ON" if debug_enabled else "OFF"))


## Add a pocket (sink) at specified position
func add_pocket(position: Vector2, radius: float = 0.05) -> BilliardCollision2D:
	var pocket = BilliardCollision2D.new()
	pocket.name = "Pocket_%d" % collision_nodes.size()
	pocket.shape_type = BilliardCollision2D.ShapeType.CIRCLE
	pocket.position_2d = position
	pocket.circle_radius = radius
	
	world.add_child(pocket)
	collision_nodes.append(pocket)
	physics.add_collision_node(pocket)
	
	if debug_enabled:
		_create_collision_visual(pocket)
	
	print("🎯 Pocket added at %s" % position)
	return pocket


## Add an obstacle (outline circle) at specified position
func add_obstacle(position: Vector2, radius: float = 0.03) -> BilliardCollision2D:
	var obstacle = BilliardCollision2D.new()
	obstacle.name = "Obstacle_%d" % collision_nodes.size()
	obstacle.shape_type = BilliardCollision2D.ShapeType.CIRCLE
	obstacle.position_2d = position
	obstacle.circle_radius = radius
	
	world.add_child(obstacle)
	collision_nodes.append(obstacle)
	physics.add_collision_node(obstacle)
	
	if debug_enabled:
		_create_collision_visual(obstacle)
	
	print("🛑 Obstacle added at %s" % position)
	return obstacle
