class_name BilliardPhysics
extends RefCounted

## Core billiard physics engine
## Based on foobillardplus physics (billmove.c)
## 
## Handles:
## - Ball movement with friction (sliding/rolling)
## - Ball-ball collision detection and response
## - Ball-wall collision detection and response
## - Angular momentum transfer


class CollisionData:
	var rect : Rect2
	var position : Vector2
	var angle : float

var balls: Array[Ball] = []

var collisions: Array[CollisionData] = []

var table: Table

# Collision event callbacks (for sound effects, etc.)
signal ball_ball_collision(ball1: Ball, ball2: Ball, strength: float)
signal ball_wall_collision(ball: Ball, strength: float)


func _init(t: Table = null) -> void:
	table = t if t else Table.new()


## Add a ball to the simulation
func add_ball(ball: Ball) -> void:
	balls.append(ball)


## Clear all balls
func clear_balls() -> void:
	balls.clear()


## Check if any ball is still moving
func is_simulation_active() -> bool:
	for ball in balls:
		if ball.in_game and ball.is_moving():
			return true
	return false


## Main physics step - call this each frame with accumulated time
func step(dt: float) -> void:
	if dt <= 0:
		return
	
	var timestep := PhysicsConstants.DEFAULT_TIMESTEP
	var remaining := dt
	
	while remaining > 0:
		var step_dt := minf(remaining, timestep)
		_proceed_dt(step_dt)
		remaining -= step_dt


## Core physics timestep (based on proceed_dt in billmove.c)
func _proceed_dt(dt: float) -> void:
	# 1. Handle collisions with Euler method
	_proceed_dt_euler(dt)
	
	# 2. Apply friction to each ball
	for ball in balls:
		if not ball.in_game:
			continue
		if not ball.is_moving():
			continue
		
		# For now, assume ball is always on table (on_table = true)
		# Future: add airborne physics for jump shots here
		if ball.on_table:
			_apply_table_friction(ball, dt)


## Euler integration with collision detection (based on proceed_dt_euler in billmove.c)
func _proceed_dt_euler(dt: float) -> void:
	# Move all balls forward
	for ball in balls:
		if ball.in_game:
			ball.integrate(dt)
	
	# Find earliest collision
	var earliest_time := 0.0
	var collision_type := 0  # 0=none, 1=ball-ball, 2=ball-wall
	var collision_ball1: Ball = null
	var collision_ball2: Ball = null
	var collision_normal := Vector3.ZERO
	
	# Check ball-ball collisions
	for i in range(balls.size()):
		if not balls[i].in_game:
			continue
		for j in range(i + 1, balls.size()):
			if not balls[j].in_game:
				continue
			var coll_time := _calc_ball_collision_time(balls[i], balls[j])
			# if balls[i].ball_number == 0 && balls[j].ball_number == 7:
			# 	print("ball collision time with %s: %s" % [j, coll_time])

			# coll_time should be negative (collision happened in the past during this timestep)
			# Check balls were approaching at start of timestep (position at -dt)
			# This avoids missing collisions when balls have already passed through each other
			if coll_time < earliest_time and _balls_approaching_at(balls[i], balls[j], -dt):
				earliest_time = coll_time
				collision_type = 1
				collision_ball1 = balls[i]
				collision_ball2 = balls[j]
	
	# Check ball-wall collisions
	for ball in balls:
		if not ball.in_game:
			continue
		
		var wall_coll := table.check_wall_collision(ball)
		if wall_coll.collided:
			# Ball has penetrated wall - collision happened in the past
			# The normal points INTO the table (away from wall)
			# vel_normal > 0 means ball is moving away from wall
			# vel_normal < 0 means ball is still moving into wall
			var vel_normal := ball.velocity.dot(wall_coll.normal)
			
			# Only process if ball is moving into wall (not already bouncing back)
			if vel_normal >= 0:
				continue
			
			# Calculate how long ago the collision happened
			# penetration = |vel_normal| * time_since_collision
			var t :float= wall_coll.penetration / absf(vel_normal)
			
			# t is positive here, representing time since collision
			# Convert to negative (past time) for comparison
			var collision_time := -t
			# Check within valid range: collision_time > -dt (happened during this timestep)
			if collision_time <= earliest_time and collision_time > -dt:
				earliest_time = collision_time
				collision_type = 2
				collision_ball1 = ball
				collision_normal = wall_coll.normal
	
	# Handle collision if found
	if collision_type == 1:
		# Rewind to collision time
		for ball in balls:
			if ball.in_game:
				ball.position += ball.velocity * earliest_time
		
		# Apply ball-ball collision response
		_ball_ball_interaction(collision_ball1, collision_ball2)
		
		# Continue with remaining time
		var remaining := -earliest_time
		if remaining > 0.0001:
			_proceed_dt_euler(remaining)
	
	elif collision_type == 2:
		# Rewind to collision time
		for ball in balls:
			if ball.in_game:
				ball.position += ball.velocity * earliest_time
		
		# Apply ball-wall collision response
		_ball_wall_interaction(collision_ball1, collision_normal)
		
		# Continue with remaining time
		var remaining := -earliest_time
		if remaining > 0.0001:
			_proceed_dt_euler(remaining)


## Calculate time until two balls collide (quadratic equation)
## Returns INF if no collision, negative if collision already happened (interpenetration)
## 
## Math: At time t, distance² = |pos_diff + vel_diff*t|² = collision_dist²
## Expanding: (vel_diff·vel_diff)*t² + 2*(pos_diff·vel_diff)*t + (pos_diff·pos_diff - collision_dist²) = 0
func _calc_ball_collision_time(ball1: Ball, ball2: Ball) -> float:
	var p := ball1.position - ball2.position      # Position difference vector
	var v := ball1.velocity - ball2.velocity      # Velocity difference vector
	var r := ball1.radius + ball2.radius          # Distance when balls touch
	
	# Quadratic equation coefficients: a*t² + b*t + c = 0
	var a := v.dot(v)                           # Relative speed squared
	var b := 2.0 * p.dot(v)                     # Position-velocity correlation
	var c := p.dot(p) - r * r  # Current distance² - collision distance²

	if is_zero_approx(v.length_squared()):
		# No relative motion between balls
		if c < 0:
			return 0.0  # Already overlapping
		return INF      # Parallel motion, never collide

	var discriminant := b * b - 4.0 * a * c

	if discriminant < 0:
		return INF  # No real solution, balls never reach collision distance

	var sqrt_discriminant := sqrt(discriminant)
	var t_entry := (-b - sqrt_discriminant) / (2.0 * a)  # Time when balls start touching
	var t_exit := (-b + sqrt_discriminant) / (2.0 * a)   # Time when balls stop touching
	
	# If t_exit < 0, collision is entirely in the past (balls already separated)
	if t_exit < 0:
		return INF

	# Return entry time (may be negative if balls are currently overlapping)
	return t_entry


## Check if two balls were approaching at a given time offset from current position
## time_offset is typically negative to check past state (e.g., start of timestep)
## Returns true if balls were moving toward each other at that time
func _balls_approaching_at(b1: Ball, b2: Ball, time_offset: float) -> bool:
	# Calculate positions at the given time offset
	var b1_pos := b1.position + b1.velocity * time_offset
	var b2_pos := b2.position + b2.velocity * time_offset
	var dr := b1_pos - b2_pos
	var dv := b1.velocity - b2.velocity
	return dr.dot(dv) < 0


## Ball-ball collision response (based on ball_ball_interaction in billmove.c)
## Collision is calculated in 2D (xz plane) to prevent y-axis (height) velocity changes
func _ball_ball_interaction(b1: Ball, b2: Ball) -> void:
	var dr := b1.position - b2.position
	dr.y = 0.0  # Ignore y-axis (height) for collision normal calculation
	var collision_normal := dr.normalized()
	
	# Relative velocity (only xz components for collision calculation)
	var dv := b2.velocity - b1.velocity
	dv.y = 0.0  # Ignore y-axis (height) velocity
	
	# Decompose into normal and tangent components
	var dvn := collision_normal * dv.dot(collision_normal)  # Normal component
	var dvp := dv - dvn  # Tangent component
	
	# Calculate collision strength for sound
	var strength := dvn.length()
	
	# Elastic collision - exchange momentum along normal
	# For equal masses: v1_new = v1 + dvn, v2_new = v2 - dvn
	var m1 := b1.mass
	var m2 := b2.mass
	var total_mass := m1 + m2
	
	var dv1 := dvn * (2.0 * m2 / total_mass)
	var dv2 := -dvn * (2.0 * m1 / total_mass)
	
	b1.velocity += dv1
	b2.velocity += dv2
	
	# Apply ball-ball friction (transfers angular momentum)
	_apply_ball_ball_friction(b1, b2, collision_normal, dvn.length())
	
	# Emit collision signal
	ball_ball_collision.emit(b1, b2, strength)
	b1.ball_collision.emit(b2, strength)
	b2.ball_collision.emit(b1, strength)


## Apply friction between two colliding balls
## Friction is calculated in 2D (xz plane) to prevent y-axis (height) velocity changes
func _apply_ball_ball_friction(b1: Ball, b2: Ball, normal: Vector3, impulse_magnitude: float) -> void:
	var mu := PhysicsConstants.MU_BALL
	
	# Calculate relative surface velocity at contact point
	var contact_r1 := -normal * b1.radius
	var contact_r2 := normal * b2.radius
	
	var surface_v1 := b1.velocity + b1.angular_velocity.cross(contact_r1)
	var surface_v2 := b2.velocity + b2.angular_velocity.cross(contact_r2)
	var relative_surface := surface_v1 - surface_v2
	relative_surface.y = 0.0  # Ignore y-axis (height) for friction calculation
	
	# Remove normal component (only tangential friction)
	var tangent_vel := relative_surface - normal * relative_surface.dot(normal)
	
	if tangent_vel.length_squared() < 1e-10:
		return
	
	var friction_dir := -tangent_vel.normalized()
	var friction_impulse := friction_dir * mu * impulse_magnitude * b1.mass
	friction_impulse.y = 0.0  # Ensure no y-axis (height) impulse
	
	# Apply to linear velocities
	b1.velocity += friction_impulse / b1.mass * 0.5
	b2.velocity -= friction_impulse / b2.mass * 0.5
	
	# Apply to angular velocities
	var torque1 := contact_r1.cross(friction_impulse)
	var torque2 := contact_r2.cross(-friction_impulse)
	
	b1.angular_velocity += torque1 / b1.inertia * 0.5
	b2.angular_velocity += torque2 / b2.inertia * 0.5


## Ball-wall collision response (based on ball_wall_interaction in billmove.c)
func _ball_wall_interaction(ball: Ball, wall_normal: Vector3) -> void:
	var vel := ball.velocity
	
	# Decompose velocity
	var vn := wall_normal * vel.dot(wall_normal)  # Normal component
	var vp := vel - vn  # Parallel component
	
	var vn_mag := vn.length()
	
	# Calculate energy loss (speed-dependent)
	var loss := table.wall_loss0 + (table.wall_loss_max - table.wall_loss0) * \
		(1.0 - exp(-vn_mag / table.wall_loss_wspeed))
	
	# Reflect normal component with energy loss
	var restitution := sqrt(1.0 - loss)
	var new_vn := -vn * restitution
	
	# Apply cushion friction to parallel component
	var friction_factor := 1.0 - table.wall_mu * (1.0 + restitution)
	friction_factor = maxf(friction_factor, 0.0)
	var new_vp := vp * friction_factor
	
	# Update velocity
	var old_vel_mag := vel.length()
	ball.velocity = new_vn + new_vp
	
	# Apply angular velocity change from friction
	var contact_r := -wall_normal * ball.radius
	var friction_impulse := (vp - new_vp) * ball.mass
	var torque := contact_r.cross(friction_impulse)
	ball.angular_velocity += torque / ball.inertia
	# temporary fix
	ball.angular_velocity *= 0.2
	
	# Emit collision signal
	ball_wall_collision.emit(ball, old_vel_mag)
	ball.wall_collision.emit(old_vel_mag)


## Apply table friction to a ball (rolling/sliding)
func _apply_table_friction(ball: Ball, dt: float) -> void:
	var perimeter_speed := ball.get_perimeter_speed()
	var perimeter_mag := Vector2(perimeter_speed.x, perimeter_speed.z).length()
	
	if perimeter_mag > PhysicsConstants.SLIDE_THRESH_SPEED:
		# Sliding friction
		_apply_sliding_friction(ball, perimeter_speed, dt)
	else:
		# Rolling friction
		_apply_rolling_friction(ball, dt)


## Apply sliding friction (ball surface moving relative to table)
## Based on foobillardplus proceed_dt sliding friction logic
func _apply_sliding_friction(ball: Ball, perimeter_speed: Vector3, dt: float) -> void:
	var mu := PhysicsConstants.MU_SLIDE
	var g := PhysicsConstants.GRAVITY
	
	# perimeter_speed is the effective perimeter speed (v + w x r)
	# Table plane is xz, so we use x and z components
	var perimeter_2d := Vector2(perimeter_speed.x, perimeter_speed.z)
	if perimeter_2d.length_squared() < 1e-10:
		return
	
	# Friction acceleration opposes perimeter velocity (from reference: fricaccel = -unit(uspeed_eff) * mu * g)
	var perimeter_dir := perimeter_2d.normalized()
	var fricaccel := Vector3(-perimeter_dir.x, 0, -perimeter_dir.y) * mu * g
	
	# Angular acceleration from friction (from reference)
	# fricmom = cross(fricaccel, (0, -r, 0)) * m  (contact point is at -y direction)
	# waccel = -fricmom / I
	var contact_r := Vector3(0, -ball.radius, 0)
	var fricmom := fricaccel.cross(contact_r) * ball.mass
	var waccel := -fricmom / ball.inertia
	
	# Apply accelerations
	ball.angular_velocity += waccel * dt
	ball.velocity += fricaccel * dt
	
	# Check if we should transition to rolling
	var new_perimeter := ball.get_perimeter_speed()
	var new_perimeter_2d := Vector2(new_perimeter.x, new_perimeter.z)
	
	# If perimeter velocity reversed direction or crossed zero, snap to rolling
	if perimeter_2d.dot(new_perimeter_2d) < 0:
		_snap_to_rolling(ball)


## Apply rolling friction (ball rolling without slipping)
func _apply_rolling_friction(ball: Ball, dt: float) -> void:
	var mu := PhysicsConstants.MU_ROLL
	var g := PhysicsConstants.GRAVITY
	var spot_r := PhysicsConstants.SPOT_R
	
	# Ensure ball is in pure rolling state
	_snap_to_rolling(ball)
	
	# Table plane is xz
	var vel_2d := Vector2(ball.velocity.x, ball.velocity.z)
	var speed := vel_2d.length()
	
	if speed < PhysicsConstants.VELOCITY_STOP_THRESHOLD:
		ball.stop()
		return
	
	# Rolling resistance deceleration
	var decel := mu * g
	var new_speed := maxf(speed - decel * dt, 0.0)
	
	if new_speed < PhysicsConstants.VELOCITY_STOP_THRESHOLD:
		ball.stop()
	else:
		var ratio := new_speed / speed
		ball.velocity.x *= ratio
		ball.velocity.z *= ratio
		
		# Maintain rolling constraint: w = v / r (perpendicular axis)
		_snap_to_rolling(ball)
	
	# Apply spot friction (slows down spin around vertical axis)
	# Vertical axis is now y
	var w_y := ball.angular_velocity.y
	if absf(w_y) > 0.01:
		var spin_friction := mu * g / spot_r * dt
		if absf(w_y) < spin_friction:
			ball.angular_velocity.y = 0.0
		else:
			ball.angular_velocity.y -= signf(w_y) * spin_friction


## Snap ball to pure rolling state (v = w x r at contact)
func _snap_to_rolling(ball: Ball) -> void:
	var r := ball.radius
	# For pure rolling on xz plane (y = height): w.x = v.z/r, w.z = -v.x/r
	ball.angular_velocity.x = ball.velocity.z / r
	ball.angular_velocity.z = -ball.velocity.x / r
