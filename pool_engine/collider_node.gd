@tool
extends Node3D
class_name ColliderNode

var collider : Collider

@export var size := Vector2(1, 1)

var table : BTable

func _ready():
	if Engine.is_editor_hint():
		return
	collider = Collider.new(get_instance_id(), Vector2(global_position.x, global_position.z), size)

func _process(delta: float) -> void:
	var euler = transform.basis.get_euler(EULER_ORDER_XYZ)
	if euler.x != 0 || euler.z != 0:
		transform.basis = Basis.from_euler(Vector3(0,euler.y,0), EULER_ORDER_XYZ)

	var dd3d_config := DebugDraw3D.new_scoped_config()
	var thickness :float= 0.005
	dd3d_config.set_thickness(thickness)
	dd3d_config.set_transform(transform)
	var size3d := Vector3(size.x, thickness, size.y)
	DebugDraw3D.draw_box(Vector3.ZERO - size3d*0.5, Quaternion.IDENTITY, size3d, Color.REBECCA_PURPLE)

	if !Engine.is_editor_hint():
		collider.position = Vector2(global_position.x, global_position.z)
		collider.size = size
		collider.angle = transform.basis.get_euler(EULER_ORDER_XYZ).y

func _notification(what: int) -> void:
	if Engine.is_editor_hint():
		return
	if what == NOTIFICATION_ENTER_WORLD || what == NOTIFICATION_PARENTED:
		var look4table = self
		while true:
			look4table = look4table.get_parent()
			if look4table != null && look4table is BTable:
				break
			else:
				look4table = null
				break
		if look4table != null && table != look4table:
			table = look4table
			table.colliders.append(self)
	elif what == NOTIFICATION_EXIT_WORLD || what == NOTIFICATION_UNPARENTED:
		if table != null:
			var pos = table.colliders.find(self)
			if pos >= 0:
				table.colliders.remove_at(pos)
				table = null
