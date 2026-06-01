class_name Table
extends RefCounted

## Simple rectangular table definition
## Walls are defined as axis-aligned boundaries
## Coordinate system: x, z = table plane, y = height (Godot convention)

# Table dimensions (standard pool table approximately)
var width: float = 2.54   # meters (length along X axis)
var depth: float = 1.27   # meters (length along Z axis)

# Boundaries (min/max positions for ball center, accounting for ball radius)
var min_x: float
var max_x: float
var min_z: float
var max_z: float

# Wall properties
var wall_mu: float = PhysicsConstants.CUSHION_MU
var wall_loss0: float = PhysicsConstants.CUSHION_LOSS0
var wall_loss_max: float = PhysicsConstants.CUSHION_LOSS_MAX
var wall_loss_wspeed: float = PhysicsConstants.CUSHION_LOSS_WSPEED


func _init(w: float = 2.54, d: float = 1.27) -> void:
	width = w
	depth = d
	_update_boundaries()


func _update_boundaries() -> void:
	var r := PhysicsConstants.BALL_RADIUS
	min_x = -width / 2.0 + r
	max_x = width / 2.0 - r
	min_z = -depth / 2.0 + r
	max_z = depth / 2.0 - r


## Check if position is within table bounds (2D: x, z)
func is_inside(pos: Vector2) -> bool:
	return pos.x >= min_x and pos.x <= max_x and pos.y >= min_z and pos.y <= max_z


## Get wall collision info for a ball
## Returns: Dictionary with "collided", "normal", "penetration"
func check_wall_collision(ball: Ball) -> Dictionary:
	var result := {
		"collided": false,
		"normal": Vector3.ZERO,
		"penetration": 0.0
	}
	
	var pos := ball.position
	
	# Check X walls
	if pos.x < min_x:
		result.collided = true
		result.normal = Vector3(1, 0, 0)  # Push +X
		result.penetration = min_x - pos.x
	elif pos.x > max_x:
		result.collided = true
		result.normal = Vector3(-1, 0, 0)  # Push -X
		result.penetration = pos.x - max_x
	
	# Check Z walls
	if pos.z < min_z:
		result.collided = true
		result.normal = Vector3(0, 0, 1)  # Push +Z
		result.penetration = min_z - pos.z
	elif pos.z > max_z:
		result.collided = true
		result.normal = Vector3(0, 0, -1)  # Push -Z
		result.penetration = pos.z - max_z
	
	return result


## Calculate time until ball hits a wall (for precise collision detection)
## Returns negative time if collision is in the past, INF if no collision
func calc_wall_collision_time(ball: Ball) -> Dictionary:
	var result := {
		"time": INF,
		"normal": Vector3.ZERO
	}
	
	var pos := ball.position
	var vel := ball.velocity
	
	# Check X walls
	if vel.x < 0 and pos.x > min_x:
		var t := (min_x - pos.x) / vel.x
		if t < result.time:
			result.time = t
			result.normal = Vector3(1, 0, 0)
	elif vel.x > 0 and pos.x < max_x:
		var t := (max_x - pos.x) / vel.x
		if t < result.time:
			result.time = t
			result.normal = Vector3(-1, 0, 0)
	
	# Check Z walls
	if vel.z < 0 and pos.z > min_z:
		var t := (min_z - pos.z) / vel.z
		if t < result.time:
			result.time = t
			result.normal = Vector3(0, 0, 1)
	elif vel.z > 0 and pos.z < max_z:
		var t := (max_z - pos.z) / vel.z
		if t < result.time:
			result.time = t
			result.normal = Vector3(0, 0, -1)
	
	return result
