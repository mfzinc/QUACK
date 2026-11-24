extends Node2D

@onready var marker_2d: Marker2D = $Marker2D
@export var level_number = 1

func _ready()-> void:
	for player in get_tree().get_nodes_in_group("player"):
		player.respawned.connect(_on_player_respawned.bind(player))
	
	
func _on_player_respawned(player):
	player.global.position = marker_2d.global_position
