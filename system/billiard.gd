extends Node
class_name Billiards

static var instance :Billiards

var camera :Camera3D
var stick :Node3D

func _ready():
	instance = self
	camera = get_node("Camera3D")
	stick = get_node("stick")
