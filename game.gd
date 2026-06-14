extends Node
class_name Game

@onready var spin_panel := %SpinPanel
@onready var force_bar := %ForceBar
@onready var btable : BTable = %BTable

@onready var stick : Node3D = %Stick

var physics: BilliardPhysics:
	get:
		return btable.physics

enum TeamFlag {
	Blue,
	Yellow,
}

var current_turn : TeamFlag
