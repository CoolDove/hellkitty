@tool
extends Node3D
class_name BTable

var collisions : Array[BilliardCollision]

func _ready() -> void:
	print("btable ready, collisions count: %s" % collisions.size())
