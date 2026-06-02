class_name Ball
extends RefCounted

## Ball state and properties for billiard physics simulation

# Physical properties
var mass: float = PhysicsConstants.BALL_MASS
var radius: float = PhysicsConstants.BALL_RADIUS
var inertia: float = PhysicsConstants.BALL_INERTIA

# State
var position: Vector3 = Vector3.ZERO      # Center position (x, z on table plane, y for height)
var velocity: Vector3 = Vector3.ZERO      # Linear velocity (x, z on table plane, y for height)
var angular_velocity: Vector3 = Vector3.ZERO  # Angular velocity (rotation axis * speed)
var rotation: Basis = Basis.IDENTITY      # Rotation matrix for ball orientation

# Ball identity
var ball_number: int = 0
var in_game: bool = true

# For future jump shot support
var on_table: bool = true  # False when ball is airborne


func _init(number: int = 0, pos: Vector2 = Vector2.ZERO) -> void:
	ball_number = number
	position = Vector3(pos.x, 0.0, pos.y)  # x,z = table plane, y = height


## Get 2D position (x, z on table plane)
func get_position_2d() -> Vector2:
	return Vector2(position.x, position.z)


## Get 2D velocity (x, z on table plane)
func get_velocity_2d() -> Vector2:
	return Vector2(velocity.x, velocity.z)


## Check if ball is moving (above threshold)
func is_moving() -> bool:
	return velocity.length_squared() > PhysicsConstants.VELOCITY_STOP_THRESHOLD * PhysicsConstants.VELOCITY_STOP_THRESHOLD \
		or angular_velocity.length_squared() > PhysicsConstants.OMEGA_MIN * PhysicsConstants.OMEGA_MIN * 0.01


## Get perimeter speed at contact point (for rolling/sliding detection)
## This is the surface velocity relative to ground: v + w x r
func get_perimeter_speed() -> Vector3:
	# Contact point is at -y direction (ball sits on table, y = height)
	var contact_r := Vector3(0, -radius, 0)
	var surface_velocity := angular_velocity.cross(contact_r)
	return velocity + surface_velocity


## Stop the ball completely
func stop() -> void:
	velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


## Apply impulse at center of mass
func apply_impulse(impulse: Vector3) -> void:
	velocity += impulse / mass


## Apply angular impulse
func apply_angular_impulse(angular_impulse: Vector3) -> void:
	angular_velocity += angular_impulse / inertia


## Move ball by delta time (simple integration)
func integrate(dt: float) -> void:
	position += velocity * dt
	
	# Integrate angular velocity into rotation
	var angular_speed := angular_velocity.length()
	if angular_speed > 0.001:
		var rotation_axis := angular_velocity.normalized()
		var rotation_angle := angular_speed * dt
		# Create incremental rotation using quaternion
		var quaternion := Quaternion(rotation_axis, rotation_angle)
		rotation = Basis(quaternion) * rotation
