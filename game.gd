extends Node
class_name Game

@onready var spin_panel := %SpinPanel
@onready var btable : BTable = %BTable

var physics: BilliardPhysics:
	get:
		return btable.physics

enum TeamFlag {
	Blue,
	Yellow,
}

var current_turn : TeamFlag

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_shoot_cue_ball(event.position)

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

	var hit_offset: Vector2 = spin_panel.get_hit_offset()
	var cue_ball := physics.balls[0]
	var direction := wpos - cue_ball.position
	direction.y = 0.0
	var shot_dir := direction.normalized()
	var shot_speed := direction.length() * 4
	
	# Apply cue ball velocity
	cue_ball.velocity = shot_dir * shot_speed
	
	# Apply spin based on hit offset
	# hit_offset.x: left/right (-1 to 1) -> side spin (english)
	# hit_offset.y: up/down (-1 to 1) -> top/back spin
	# 
	# When cue strikes off-center, it creates angular velocity:
	# - Side hit (x offset): creates spin around Y axis (vertical)
	# - Vertical hit (y offset): creates spin around horizontal axis perpendicular to shot
	#
	# The torque from cue impact: τ = r × F
	# Where r is the offset from center, F is the cue force along shot direction
	# Angular impulse: Δω = τ * Δt / I ≈ (r × F) / I
	
	var r := cue_ball.radius
	var max_offset := r * 0.7  # Can't hit too close to edge (miscue)
	
	# Hit point offset in ball's local space
	# x offset -> perpendicular to shot direction (right is positive)
	# y offset -> vertical (up is positive)
	var right_dir := Vector3(shot_dir.z, 0, -shot_dir.x)  # Perpendicular to shot in XZ plane
	var up_dir := Vector3.UP
	
	# Contact point relative to ball center
	var contact_offset := right_dir * (hit_offset.x * max_offset) + up_dir * (hit_offset.y * max_offset)
	
	# Cue force direction (along shot direction)
	# The impulse magnitude is proportional to shot speed
	var impulse_magnitude := shot_speed * cue_ball.mass
	var cue_force := shot_dir * impulse_magnitude
	
	# Torque = r × F, angular impulse = torque (instantaneous)
	var angular_impulse := contact_offset.cross(cue_force)
	
	# Apply angular velocity change: Δω = angular_impulse / I
	cue_ball.angular_velocity += angular_impulse / cue_ball.inertia
	
	print("Shot: dir=%s, speed=%.2f, offset=%s, spin=%s" % [shot_dir, shot_speed, hit_offset, cue_ball.angular_velocity])
	spin_panel.reset_hit_offset()
