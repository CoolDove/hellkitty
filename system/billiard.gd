extends Node
class_name Billiards

static var instance :Billiards

var camera :Camera3D
var stick :Node3D

var spin_panel

func _ready():
	instance = self
	camera = %Camera3D
	stick = %stick
	spin_panel = %SpinPanel
