## Demo scene for billiard physics with collision testing
## Uses BilliardSceneManager for collision node management and visualization

extends Node

@onready var spin_panel := %SpinPanel
@onready var scene_manager: BilliardSceneManager = $BilliardSceneManager


func _ready() -> void:
	print("🎮 Billiard Demo Scene Ready")
	print("  Controls:")
	print("    🖱️  Left Click: Shoot cue ball")
	print("    🔄 R: Reset scene")
	print("    🎨 D: Toggle debug visualization")
	print("    📊 C: Print collision info")


func _process(delta: float) -> void:
	# Physics stepping is handled by BilliardSceneManager
	pass


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_shoot_cue_ball(event.position)
	
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_R:
				scene_manager.reset_scene()
				get_tree().set_input_as_handled()
			
			KEY_D:
				scene_manager.toggle_debug_visualization()
				get_tree().set_input_as_handled()
			
			KEY_C:
				_print_collision_info()
				get_tree().set_input_as_handled()


func screen_pos_to_world_z0(position: Vector2, camera: Camera3D) -> Vector3:
	var origin = camera.project_ray_origin(position)
	var dir = camera.project_ray_normal(position)
	var plane = Plane(Vector3.UP, 0.0)
	return plane.intersects_ray(origin, dir)


func _shoot_cue_ball(mouse_pos: Vector2) -> void:
	var camera = get_viewport().get_camera_3d()
	var wpos := screen_pos_to_world_z0(mouse_pos, camera)
	
	if scene_manager.physics.is_simulation_active():
		print("⏳ Balls still moving, wait...")
		return

	var hit_offset: Vector2 = spin_panel.get_hit_offset()
	var cue_ball := scene_manager.physics.balls[0]
	var direction := wpos - cue_ball.position
	direction.y = 0.0
	var shot_dir := direction.normalized()
	var shot_speed := direction.length() * 4
	
	# Apply cue ball velocity
	cue_ball.velocity = shot_dir * shot_speed
	
	# Apply spin based on hit offset
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
	
	print("🎯 Shot: dir=%s, speed=%.2f, offset=%s" % [shot_dir, shot_speed, hit_offset])
	spin_panel.reset_hit_offset()


func _print_collision_info() -> void:
	print("\n📊 Collision Information:")
	print("  Active collision nodes: %d" % scene_manager.collision_nodes.size())
	for collision_node in scene_manager.collision_nodes:
		match collision_node.shape_type:
			BilliardCollision2D.ShapeType.RECT:
				print("  • %s (RECT): pos=%.2f,%.2f normal=%s" % [
					collision_node.name,
					collision_node.position_2d.x,
					collision_node.position_2d.y,
					collision_node.rect_normal
				])
			BilliardCollision2D.ShapeType.CIRCLE:
				print("  • %s (CIRCLE): pos=%.2f,%.2f radius=%.3f mode=%s" % [
					collision_node.name,
					collision_node.position_2d.x,
					collision_node.position_2d.y,
					collision_node.circle_radius
				])
	
	print("  Ball nodes: %d" % scene_manager.ball_nodes.size())
	print()
