@tool
extends Node3D
class_name BilliardCollision

@export var size := Vector2(1, 1)

var table : BTable

func _process(delta: float) -> void:
	var dd3d_config := DebugDraw3D.new_scoped_config()
	var thickness :float= 0.005
	dd3d_config.set_thickness(thickness)
	dd3d_config.set_transform(transform)
	var size3d := Vector3(size.x, thickness, size.y)
	DebugDraw3D.draw_box(Vector3.ZERO - size3d*0.5, Quaternion.IDENTITY, size3d, Color.REBECCA_PURPLE)

func _notification(what: int) -> void:
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
			table.collisions.append(self)
			#print("collision added by %s, from: %s" % [what, table.name])
	elif what == NOTIFICATION_EXIT_WORLD || what == NOTIFICATION_UNPARENTED:
		if table != null:
			var pos = table.collisions.find(self)
			if pos >= 0:
				table.collisions.remove_at(pos)
				#print("collision removed by %s, from: %s" % [what, table.name])
				table = null
