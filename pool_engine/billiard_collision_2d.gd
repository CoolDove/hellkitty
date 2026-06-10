class_name BilliardCollision2D
extends Node3D

## Universal collision node for billiard table
## Supports multiple collision shapes: rect, circle
## All collisions happen on the table plane (x-z plane, y = height)

enum ShapeType {
	RECT,      # Rectangular collision (walls, boundaries)
	CIRCLE,    # Circular collision (pockets, obstacles)
}

## Shape type
@export var shape_type: ShapeType = ShapeType.RECT

## 2D position on table (x, z coordinates)
@export var position_2d: Vector2 = Vector2.ZERO

## Rectangle properties (used when shape_type == RECT)
@export var rect_half_x: float = 0.05
@export var rect_half_z: float = 0.635
@export var rect_normal: Vector3 = Vector3(1, 0, 0)  # Must be ±X or ±Z axis

## Circle properties (used when shape_type == CIRCLE)
@export var circle_radius: float = 0.05

## Table height (Y position)
@export var table_height: float = 0.0

## Signal emitted when collision occurs
signal collision_with_ball(ball: Ball, strength: float)


func _ready() -> void:
	global_position = Vector3(position_2d.x, table_height, position_2d.y)


## Main collision check method - dispatches to appropriate shape handler
func check_ball_collision(ball: Ball) -> Dictionary:
	match shape_type:
		ShapeType.RECT:
			return _check_rect_collision(ball)
		ShapeType.CIRCLE:
			return _check_circle_collision(ball)
		_:
			return {
				"collided": false,
				"normal": Vector3.ZERO,
				"penetration": 0.0
			}


## Check collision for rectangular shape
func _check_rect_collision(ball: Ball) -> Dictionary:
	var result := {
		"collided": false,
		"normal": Vector3.ZERO,
		"penetration": 0.0
	}
	
	var ball_2d := Vector2(ball.position.x, ball.position.z)
	var closest := _get_closest_point_rect(ball_2d)
	var dist := ball_2d.distance_to(closest)
	
	if dist < ball.radius:
		result.collided = true
		result.normal = rect_normal
		result.penetration = ball.radius - dist
	
	return result


## Check collision for circular shape
func _check_circle_collision(ball: Ball) -> Dictionary:
	var result := {
		"collided": false,
		"normal": Vector3.ZERO,
		"penetration": 0.0
	}
	
	var ball_2d := Vector2(ball.position.x, ball.position.z)
	var dist := ball_2d.distance_to(position_2d)
	
	# Collision on circle outline
	if dist < ball.radius + circle_radius:
		result.collided = true
		var direction := (ball_2d - position_2d).normalized()
		result.normal = Vector3(direction.x, 0, direction.y)
		result.penetration = ball.radius + circle_radius - dist

	return result


## Get closest point on rectangular surface to a 2D position
func _get_closest_point_rect(pos: Vector2) -> Vector2:
	var rel := pos - position_2d
	
	var clamped_x = clamp(rel.x, -rect_half_x, rect_half_x) + position_2d.x
	var clamped_z = clamp(rel.y, -rect_half_z, rect_half_z) + position_2d.y
	
	var closest := Vector2.ZERO
	
	if abs(rect_normal.x) > 0.5:  # Normal along X axis
		# Vertical wall (parallel to Z axis)
		closest.x = position_2d.x
		if rect_normal.x > 0:
			closest.x -= rect_half_x
		else:
			closest.x += rect_half_x
		closest.y = clamped_z
	else:  # Normal along Z axis
		# Horizontal wall (parallel to X axis)
		closest.x = clamped_x
		closest.y = position_2d.y
		if rect_normal.z > 0:
			closest.y -= rect_half_z
		else:
			closest.y += rect_half_z
	
	return closest


## Get closest point on collision surface
func get_closest_point(pos: Vector2) -> Vector2:
	match shape_type:
		ShapeType.RECT:
			return _get_closest_point_rect(pos)
		ShapeType.CIRCLE:
			var direction := (pos - position_2d).normalized()
			return position_2d + direction * circle_radius
		_:
			return pos

## Check if a position is inside this collision shape
func is_inside(pos: Vector2) -> bool:
	match shape_type:
		ShapeType.RECT:
			var rel := pos - position_2d
			return abs(rel.x) <= rect_half_x and abs(rel.y) <= rect_half_z
		ShapeType.CIRCLE:
			var dist := pos.distance_to(position_2d)
			return dist > circle_radius
		_:
			return false

## Helper: Convert 3D position to 2D table position (x, z)
static func to_2d(pos: Vector3) -> Vector2:
	return Vector2(pos.x, pos.z)


## Helper: Convert 2D table position to 3D (x, table_height, z)
func to_3d(pos: Vector2) -> Vector3:
	return Vector3(pos.x, table_height, pos.y)
