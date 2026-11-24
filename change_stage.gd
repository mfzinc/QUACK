extends Area2D
@export_file("*.tscn") var target_stage: String

func _on_body_entered(body: Node2D) -> void:
	if "player" in body.name:
		print("success")
		#get_tree().change_scene(target_stage)
