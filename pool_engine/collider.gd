extends RefCounted
class_name Collider


var collider_number : int = 0

var position : Vector2 = Vector2.ONE
var size : Vector2 = Vector2.ONE
var angle : float = 0 # radian


func _init(number: int = 0, pos: Vector2 = Vector2.ZERO, size: Vector2 = Vector2.ONE, angle:float = 0) -> void:
	collider_number = number
	position = pos
	self.size = size
	self.angle = angle
